const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const fs = require('fs');
const path = require('path');

const compression = require('compression');
const app = express();
const port = 3000;

// Middlewares
app.use(compression());
app.use(cors());
app.use(bodyParser.json());

// Cargar datos desde JSON
const dataPath = path.join(__dirname, 'data');
let categories = [];   
let items = [];        

try {
    categories = JSON.parse(fs.readFileSync(path.join(dataPath, 'categories.json'), 'utf8'));
    items = JSON.parse(fs.readFileSync(path.join(dataPath, 'items.json'), 'utf8'));
    console.log(`Datos cargados: ${items.length} items y ${categories.length} categorías.`);
} catch (error) {
    console.error("Error cargando los archivos JSON de datos:", error.message);
}

// Serve public static files (public/) and images from public/images
app.use(express.static(path.join(__dirname, 'public')));

app.use('/images', express.static(path.join(__dirname, 'public/images')));

// GET for image thumbnails
app.get('/images/thumbs/:imageName', (req, res) => {
    const imageName = req.params.imageName;
    const thumbPath = path.join(__dirname, 'public/images/thumbs', imageName);
    const mainPath = path.join(__dirname, 'public/images', imageName);
    if (fs.existsSync(thumbPath)) {
        res.sendFile(thumbPath);
    } else if (fs.existsSync(mainPath)) {
        res.sendFile(mainPath);
    } else {
        res.status(404).send('Not found');
    }
});

// GET /item/:id/image - returns image for item
app.get('/item/:id/image', (req, res) => {
    const id = parseInt(req.params.id);
    const item = items.find(i => i.id === id);
    if (!item) return res.status(404).send('Item not found');
    if (!item.image) return res.status(404).send('No image for this item');
    
    const imagePath = path.join(__dirname, 'public/images', item.image);
    if (fs.existsSync(imagePath)) return res.sendFile(imagePath);
    return res.status(404).send('Image not found');
});


// Getter for categories
app.get('/categories', (req, res) => {
    res.json(categories);
 });

// Getter for items
app.get('/items', (req, res) => {
    const categoryId = req.query.categoryId ? parseInt(req.query.categoryId) : null;
    const page = req.query.page ? Math.max(1, parseInt(req.query.page)) : 1;
    const pageSize = req.query.pageSize ? Math.max(1, parseInt(req.query.pageSize)) : 20;

    let filtered = items;
    if (categoryId) {
        filtered = items.filter(item => item.categoryId === categoryId);
    }

    const start = (page - 1) * pageSize;
    const paged = filtered.slice(start, start + pageSize);

    res.json({
        page,
        pageSize,
        total: filtered.length,
        items: paged
    });
});


// POST for categories
app.post('/categories', (req, res) => {
  res.json(categories);
});

// POST for items
app.post('/items', (req, res) => {
  const { categoryId } = req.body;
  if (categoryId) {
    // Filtrar items by categoryId
    const filteredItems = items.filter(item => item.categoryId === parseInt(categoryId));
    res.json(filteredItems);
  } else {
    // Return all items if there's no categoryId
    res.json(items);
  }
});

// POST for item
app.post('/item', (req, res) => {
  const { itemId } = req.body;
  const item = items.find(i => i.id === parseInt(itemId));
  if (item) {
    res.json(item);
  } else {
    res.status(404).send('Item not found');
  }
});

// POST for /search - search items by text
app.post('/search', (req, res) => {
        const { query } = req.body;
        if (!query || typeof query !== 'string') {
                return res.status(400).json({ error: 'Missing or invalid query' });
        }
        const q = query.trim().toLowerCase();
    // Search only by item name (field `name`)
    const results = items.filter(it => {
        const name = (it.name || '').toString().toLowerCase();
        return name.includes(q);
    });
        res.json({ query, total: results.length, items: results });
});

// GET /item/:id/image - returns image for item
app.get('/item/:id/image', (req, res) => {
        const id = parseInt(req.params.id);
        const item = items.find(i => i.id === id);
        if (!item) return res.status(404).send('Item not found');
        if (!item.image) return res.status(404).send('No image for this item');
        const imagePath = path.join(__dirname, 'public/images', item.image);
        if (fs.existsSync(imagePath)) return res.sendFile(imagePath);
        return res.status(404).send('Image not found');
});

// Si no es una imagen ni un archivo real, enviamos el index.html
app.get(/(.*)/, (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Run & Stop server
const httpServer = app.listen(port, '0.0.0.0', () => {
    console.log(`--- SERVIDOR ARRANCADO ---`);
    console.log(`Internamente: http://localhost:${port}`);
});

process.on('SIGTERM', shutDown);
process.on('SIGINT', shutDown);

function shutDown() {
    console.log('Received kill signal, shutting down gracefully');
    httpServer.close(() => {
        console.log('Closed out remaining connections');
        process.exit(0);
    });
}
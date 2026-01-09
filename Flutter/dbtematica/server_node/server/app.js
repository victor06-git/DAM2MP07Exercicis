const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const fs = require('fs');
const path = require('path');
const multer = require('multer');
const { getEnabledCategories } = require('trace_events');

const compression = require('compression');
const app = express();
const port = 3000;

// Middlewares
app.use(compression());
app.use(cors());
app.use(bodyParser.json());
app.use(express.static('public'));
app.use('/images', express.static(path.join(__dirname, 'data/images')));
// Servir miniaturas si existen; en caso contrario, devolver la imagen original
app.get('/images/thumbs/:imageName', (req, res) => {
    const imageName = req.params.imageName;
    const thumbPath = path.join(__dirname, 'data/images/thumbs', imageName);
    const mainPath = path.join(__dirname, 'data/images', imageName);
    if (fs.existsSync(thumbPath)) {
        res.sendFile(thumbPath);
    } else if (fs.existsSync(mainPath)) {
        // Fallback: servir la imagen principal si no hay miniatura
        res.sendFile(mainPath);
    } else {
        res.status(404).send('Not found');
    }
});

// Cargar datos desde JSON
const dataPath = path.join(__dirname, 'data');
const categories = JSON.parse(fs.readFileSync(path.join(dataPath, 'categories.json'), 'utf8'));
const items = JSON.parse(fs.readFileSync(path.join(dataPath, 'items.json'), 'utf8'));

app.get('/categories', (req, res) => {
    res.json(categories);
 });

// GET /items?categoryId=1&page=1&pageSize=20 - devuelve items paginados (opcional)
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
// --- Rutas para la App de Películas ---

app.post('/categories', (req, res) => {
  res.json(categories);
});

app.post('/items', (req, res) => {
  const { categoryId } = req.body;
  if (categoryId) {
    // Filtrar items por categoryId si se proporciona
    const filteredItems = items.filter(item => item.categoryId === parseInt(categoryId));
    res.json(filteredItems);
  } else {
    // Devolver todos los items si no hay categoryId
    res.json(items);
  }
});

app.post('/item', (req, res) => {
  const { itemId } = req.body;
  const item = items.find(i => i.id === parseInt(itemId));
  if (item) {
    res.json(item);
  } else {
    res.status(404).send('Item not found');
  }
});

// --- Rutas existentes para subida de archivos (Multer) ---

// Crear la carpeta 'uploads' si no existeix
if (!fs.existsSync('uploads')) {
    fs.mkdirSync('uploads');
}

// Tipus MIME acceptats
const allowedMimeTypes = ['text/plain', 'image/jpeg', 'image/png', 'application/pdf'];

// Configurar multer per guardar arxius a la carpeta "uploads"
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, 'uploads');
    },
    filename: (req, file, cb) => {
        cb(null, Date.now() + '-' + file.originalname);
    }
});

const upload = multer({
    storage: storage,
    limits: { fileSize: 50 * 1024 * 1024 }, 
    fileFilter: (req, file, cb) => {
        if (allowedMimeTypes.includes(file.mimetype)) {
            cb(null, true);
        } else {
            cb(new Error('Tipus de fitxer no permès'), false);
        }
    }
});

app.post('/upload', upload.array('files', 10), async (req, res) => {
    try {
        const jsonData = JSON.parse(req.body.json);
        const files = req.files.map(file => ({
            originalName: file.originalname,
            mimeType: file.mimetype,
            size: file.size,
            path: file.path
        }));
        res.json({
            message: 'Dades rebudes',
            jsonData: jsonData,
            files: files
        });
    } catch (error) {
        res.status(400).json({ error: 'Error processant la petició', details: error.message });
    }
});

// --- Arranque y parada del servidor ---

const httpServer = app.listen(port, () => {
    console.log(`Servidor escoltant a http://localhost:${port}`);
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
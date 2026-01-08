const express = require('express')
const app = express()
const port = 3000
const multer = require('multer')

// Continguts estàtics (carpeta public)
app.use(express.static('public'))

// Configurar direcció ‘/’ 
app.get('/', getHello)
    async function getHello (req, res) {
    res.send(`Hola Hola des del servidor Node.js amb Express!`)
}

// Activar el servidor
const httpServer = app.listen(port, appListen)
function appListen () {
    console.log(`Example app listening on: http://0.0.0.0:${port}`)
}

// Aturar el servidor correctament 
process.on('SIGTERM', shutDown);
process.on('SIGINT', shutDown);
function shutDown() {
    console.log('Received kill signal, shutting down gracefully');
    httpServer.close()
    process.exit(0);
}

// http://localhost:3000/api?param1=value1&param2=value2
app.get('/api', async (req, res) => {
    // Obtenir el valor de "param1"
    const param1 = req.query.param1 

    // Obtenir el valor de "param2"
    const param2 = req.query.param2

    res.json({
        message: 'Dades rebudes',
        param1: param1,
        param2: param2
    })
})

// Crear la carpeta 'uploads' si no existeix
const fs = require('fs')
if (!fs.existsSync('uploads')) {
    fs.mkdirSync('uploads')
}

// Tipus MIME acceptats
const allowedMimeTypes = ['text/plain', 'image/jpeg', 'image/png', 'application/pdf']

// Configurar multer per guardar arxius a la carpeta "uploads"
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        // Carpeta on es guarden els fitxers
        cb(null, 'uploads') 
    },
    filename: (req, file, cb) => {
        // Prefixar amb un timestamp per evitar col·lisions
        cb(null, Date.now() + '-' + file.originalname) 
    }
})

// Configuració de multer amb límit de mida i validació
const upload = multer({
    // Límit de 50 MB per fitxer
    storage: storage,
    limits: { fileSize: 50 * 1024 * 1024 }, 
    fileFilter: (req, file, cb) => {
        if (allowedMimeTypes.includes(file.mimetype)) {
            cb(null, true) // Acceptar el fitxer
        } else {
            cb(new Error('Tipus de fitxer no permès'), false) // Rebutjar el fitxer
        }
    }
})

app.post('/upload', upload.array('files', 10), async (req, res) => {
    try {
        // Obtenir l'objecte JSON
        const jsonData = JSON.parse(req.body.json)

        // Obtenir els arxius
        const files = req.files.map(file => ({
            originalName: file.originalname,
            mimeType: file.mimetype,
            size: file.size,
            path: file.path
        }))

        res.json({
            message: 'Dades rebudes',
            jsonData: jsonData,
            files: files
        })
    } catch (error) {
        res.status(400).json({ error: 'Error processant la petició', details: error.message })
    }
})

app.listen(3000, () => {
    console.log('Servidor escoltant al port 3000')
})
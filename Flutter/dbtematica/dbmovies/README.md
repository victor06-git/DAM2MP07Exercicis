# DBMovies - Proyecto `dbtematica/dbmovies`

Breve resumen y guía rápida sobre la estructura del proyecto y qué hace cada archivo principal.

## Resumen
App Flutter que consume un servidor NodeJS para mostrar una base de datos temática (categorías, items y detalle). Las llamadas a datos usan `POST` y las imágenes se sirven con `GET`.

## Cómo ejecutar

- Arrancar el servidor Node (desde `server_node`):
```bash
cd Flutter/dbtematica/server_node
npm install
npm run dev
```

- Ejecutar la app Flutter (desde `dbmovies`):
```bash
cd Flutter/dbtematica/dbmovies
flutter pub get
flutter run -d linux
```

Si ejecutas la app en un emulador Android, ajusta `lib/config.dart` a `http://10.0.2.2:3000`.

## Endpoints principales (servidor)

- `POST /categories` → devuelve lista de categorías.
- `POST /items` (body: `{ categoryId }`) → devuelve items de la categoría.
- `POST /item` (body: `{ itemId }`) → devuelve item concreto.
- `POST /search` (body: `{ query }`) → devuelve items que coinciden.
- `GET /images/thumbs/:imageName` → miniaturas.
- `GET /item/:id/image` → imagen principal del item.

## Archivos y qué hacen

- **Flutter/dbtematica/dbmovies/lib/main.dart**: Punto de entrada de la app; configuración del tema y rutas (`/` y `/items`).
- **Flutter/dbtematica/dbmovies/lib/config.dart**: Constante `baseUrl` con la URL del servidor (ajústala según dónde ejecutes el servidor).
- **Flutter/dbtematica/dbmovies/lib/screens/categories_screen.dart**: Pantalla de *Categories* (grid de cards, buscador inline). Hace `POST /categories` y `POST /search`.
- **Flutter/dbtematica/dbmovies/lib/screens/items_screen.dart**: Pantalla de *Items* por categoría. Obtiene items con `POST /items`, soporta paginación cliente y muestra cards con miniaturas.
- **Flutter/dbtematica/dbmovies/lib/view_item.dart**: Pantalla de *Detalle* de un item. Muestra la imagen (prueba `/images/<file>`, luego `/item/:id/image`, y finalmente la miniatura si hace falta) con zoom/pan (`InteractiveViewer`) y `Hero` para transiciones.
- **Flutter/dbtematica/dbmovies/lib/models/category.dart**: Modelo `Category` (id, name) y método `fromJson`.
- **Flutter/dbtematica/dbmovies/lib/models/item.dart**: Modelo `Item` (id, categoryId, name, description, image) y método `fromJson`.
- **Flutter/dbtematica/dbmovies/lib/categories_list_item.dart**: Componente pequeño para una fila de categoría (se usa en versiones previas; el grid actual vive en `categories_screen.dart`).

## Servidor Node (ubicación y datos)

- **Flutter/dbtematica/server_node/server/app.js**: Servidor Express que carga `server/data/categories.json` y `server/data/items.json`. Sirve imágenes desde `server/public/images`.
- **Flutter/dbtematica/server_node/server/data/**: JSON con `categories.json` y `items.json` de ejemplo. Coloca las imágenes en `server/public/images` y `server/public/images/thumbs`.

## Consejos rápidos

- Si no ves imágenes en la vista detalle, comprueba en el navegador que las URLs devuelven la imagen: `http://localhost:3000/images/<file>` o `http://localhost:3000/item/<id>/image`.
- Para mejorar rendimiento a futuro, considera implementar paginación en el servidor (ahora se hace client-side tras solicitar todos los items de una categoría).

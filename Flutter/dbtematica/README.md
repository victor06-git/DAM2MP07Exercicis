# dbtematica — README

**Overview**:
- Proyecto híbrido: Flutter frontend (`dbmovies`) y servidor Node.js (`server_node`).

**Flutter (app `dbmovies`)**:
- **Ubicación:** [Flutter/dbtematica/dbmovies](Flutter/dbtematica/dbmovies)
- **Qué hace:** Interfaz que consume la API Node (`/categories`, `/items`, `/search`) y muestra listado y detalle de items.
- **Ejecutar en desarrollo:**
```bash
cd Flutter/dbtematica/dbmovies
flutter pub get
flutter run      # Elige dispositivo o navegador (e.g. chrome)
```
- **Construir web (para desplegar con Node):**
```bash
cd Flutter/dbtematica/dbmovies
flutter build web --release
# El resultado estará en: build/web
```
- **Servir la versión web con el Node server:** copiar el contenido de `build/web` a `server_node/server/public/`:
```bash
cp -r build/web/* ../server_node/server/public/
```

**Node server (`server_node`)**:
- **Ubicación:** [Flutter/dbtematica/server_node](Flutter/dbtematica/server_node)
- **Entry:** [server_node/server/app.js](server_node/server/app.js)
- **Datos y assets:** `server_node/server/data/` contiene `categories.json` y `items.json`. Las imágenes están en `server_node/server/public/images/thumbs/`.
- **Endpoints principales:**
  - `GET /categories` — lista categorías
  - `GET /items?categoryId=<id>&page=<n>&pageSize=<m>` — lista paginada
  - `POST /search` — busca items (por `name`) — body JSON: `{ "query": "texto" }`
  - `GET /images/thumbs/<file>` — thumbs
  - `GET /item/:id/image` — imagen por item
  - `POST /upload` — subir archivos (multer)
- **Instalar y ejecutar localmente:**
```bash
cd Flutter/dbtematica/server_node
npm install
node server/app.js
# o con pm2 (recomendado en producción):
pm2 start server/app.js --name app
pm2 logs app
```

**Deploy (Proxmox script)**:
- **Script:** [server_node/scripts/proxmox/proxmoxDeploy.sh](server_node/scripts/proxmox/proxmoxDeploy.sh)
- **Uso:**
```bash
cd Flutter/dbtematica/server_node/scripts/proxmox
./proxmoxDeploy.sh <user> <rsa_path> <server_port>
```
- El script empaqueta el repo, lo copia al servidor remoto, desempaqueta en `~/nodejs_server`, ejecuta `npm install` y arranca con `pm2`.
- **Archivo de configuración:** el script lee `config.env` en la misma carpeta para valores por defecto (usuario, puerto, etc.).

**Puntos importantes / Troubleshooting**:
- El servidor Node lee el puerto desde `process.env.PORT` o `process.env.SERVER_PORT`; si el proxy devuelve `503` comprueba que la app escucha en el puerto esperado y que `pm2` está `online`.
  - Comandos útiles en remoto:
```bash
pm2 status
pm2 logs app --lines 200
ss -tln | grep ':<PORT>'
```
- Si `GET /` devuelve `Cannot GET` o un placeholder, asegúrate de copiar el build web a `server_node/server/public/` o de tener un `index.html` en esa carpeta.
- Las imágenes que usa la app son `public/images/thumbs/<name>`; si en el detalle no ves la imagen copia los archivos grandes a `server_node/server/public/images/` o ajusta la ruta en `view_item.dart`.
- Search: `/search` busca sólo por `name`.

**Archivos clave**:
- Frontend: [Flutter/dbtematica/dbmovies/lib/main.dart](dbmovies/lib/main.dart)
- Detalle de item: [Flutter/dbtematica/dbmovies/lib/view_item.dart](dbmovies/lib/view_item.dart)
- Servidor: [Flutter/dbtematica/server_node/server/app.js](server_node/server/app.js)
- Deploy: [Flutter/dbtematica/server_node/scripts/proxmox/proxmoxDeploy.sh](server_node/scripts/proxmox/proxmoxDeploy.sh)

Si quieres, puedo:
- Añadir un script `make deploy-web` que haga `flutter build web` + copia automática a `server_node/server/public/`.
- Añadir comprobaciones health-check en el servidor para que HAProxy/Proxmox detecte correctamente la app.

---
_README generado automáticamente — dime si quieres más detalle en alguna sección._

## main.dart — estructura y flujo (detallado)

Ubicación: `Flutter/dbtematica/dbmovies/lib/main.dart`.

- Entrypoint: `main()` llama a `runApp(const MyApp())`.
- `MyApp`: `MaterialApp` con `initialRoute: '/'` y rutas:
  - `/` -> `CategoriesScreen`
  - `/items` -> `ItemsScreen`

### `CategoriesScreen` (pantalla principal)
- Ciclo: en `didChangeDependencies()` se llama a `_fetchCategories()` que hace `GET /categories` y popula `_categories`.
- Controles:
  - `DropdownButton<int>`: muestra categorías; al seleccionar una categoría hace `Navigator.pushNamed('/items', arguments: <id>)`.
  - Campo de búsqueda: permite buscar items globalmente. Al pulsar Enter ejecuta `_performSearch(query)` que hace `POST /search` y muestra resultados en la misma vista.
- Estado relevante: `_categories`, `_loading`, `_selectedCategory`, `_isSearching`, `_searchQuery`, `_searchResults`, `_searchLoading`.

### `ItemsScreen` (listado por categoría)
- Recibe `categoryId` desde `ModalRoute.of(context)!.settings.arguments`.
- Paginación/infinite scroll:
  - Variables: `_page`, `_pageSize`, `_total`, `_loading`, `_loadingMore`, `_items`.
  - `_fetchItems()` hace `GET /items?categoryId=...&page=...&pageSize=...` y añade resultados cuando se llega al final de la lista.
- Tap en un item: `Navigator.push` a `ItemDetailScreen(item: item)`.

### `ItemDetailScreen` (detalle)
- Implementado en `view_item.dart` como `ItemDetailScreen`.
- Muestra la imagen (usa `https://.../images/thumbs/<file>`), el nombre y la descripción.

### Modelos
- `models/item.dart` y `models/category.dart` contienen los parseadores `fromJson`.
- `Item` incluye campos `id, categoryId, name, description, image`.

### Red / URLs
- En el código las llamadas usan la base `https://vasensiobermudez.ieti.site` hardcodeada. Para cambiar el servidor, busca y sustituye esa URL o crea una constante `BASE_URL` y úsala en todas las peticiones.

### Comportamiento de búsqueda
- Endpoint: `POST /search` con body `{ "query": "texto" }`.
- Actualmente el servidor busca únicamente por `name` (no por `description`).

### Mostrar imágenes
- La app usa `images/thumbs/<file>` para cargar thumbnails. Si la pantalla de detalle muestra un espacio en blanco:
  - Verifica que `server_node/server/public/images/thumbs/<file>` exista.
  - Si quieres mostrar imágenes grandes cambia la URL en `view_item.dart` a `/images/<file>` o copia las imágenes grandes a `public/images/`.

### Recomendaciones rápidas de desarrollo
- Extraer la `BASE_URL` en una constante o `const String kBaseUrl = 'https://...'` en `main.dart` para facilitar switches entre entornos.
- Añadir manejo de errores y mensajes cuando las peticiones fallen.
- Considerar `debounce` en el TextField de búsqueda para llamadas automáticas mientras se escribe.

Si quieres, actualizo `main.dart` para usar una `kBaseUrl` y habilitar un `--env` simple o `const` por build flavor.

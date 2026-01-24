# xatIETI — Documentación por funciones

Archivo principal de interés: `src/main/java/com/project/Controller.java`.
Este README explica cada función importante y su comportamiento para que puedas describirlo al profesor.

`Main` (punto de entrada)
- `start(Stage)`: carga `layout.fxml`, crea la `Scene` y muestra la ventana. Añade icono si no es macOS.

`Controller` (UI y lógica de peticiones)
- `initialize(URL, ResourceBundle)`:
  - Carga imágenes para botones (`upload`, `send`) y para iconos de usuario/IA si están disponibles.

- `handleUpload(ActionEvent)`:
  - Abre un `FileChooser` limitado a tipos de imagen.
  - Lee el archivo seleccionado a bytes y lo convierte a Base64 (`selectedImageBase64`) para enviarlo posteriormente.
  - Muestra mensaje simple de confirmación o error.

- `handleSend(ActionEvent)`:
  - Obtiene el texto del usuario desde `messageText`. Si está vacío muestra aviso.
  - Muestra el mensaje del usuario en la UI (`displayUserMessage`) y desactiva botones mientras procesa.
  - Si `selectedImageBase64 != null` realiza una petición de visión (`executeImageRequest`) que esperará una respuesta completa.
  - Si no hay imagen, realiza una petición de texto con streaming (`executeTextRequest`) y añade un placeholder para la respuesta AI.
  - Limpia el campo `messageText` al final.

- `callBreak(ActionEvent)`:
  - Marca la petición como cancelada (`isCancelled`), intenta cancelar las peticiones asíncronas (`streamRequest`, `completeRequest`) y cierra `InputStream` si es necesario.
  - Cancela la tarea que lee el stream y actualiza la UI con un mensaje de petición cancelada, además de reactivar botones.

Request helpers
- `executeTextRequest(String model, String prompt, boolean stream)`:
  - Prepara un JSON con `model`, `prompt`, `stream` y realiza una petición HTTP POST a `http://localhost:11434/api/generate`.
  - Si `stream==true` recibe un `InputStream` y lanza `handleStreamResponse()` en un `ExecutorService` para procesar chunks.

- `executeImageRequest(String model, String prompt, String base64Image)`:
  - Construye un JSON con `images` (lista base64) y opciones, realiza la petición y espera la respuesta completa.
  - Al recibir la respuesta parsea texto con `tryParseAnyMessage(...)` y actualiza la UI con `updateAIMessage(...)`.

- `handleStreamResponse()`:
  - Lee el `InputStream` línea a línea (cada línea es JSON con un campo `response`) y acumula los fragmentos en `aiResponse`.
  - Llama a `updateAIMessage(...)` periódicamente mediante `Platform.runLater` para mostrar la respuesta en tiempo real.
  - Controla cancelaciones e interrupciones; al finalizar cierra el stream y resetea botones.

UI display helpers
- `displayUserMessage(String message)`:
  - Limpia `textInfo` y añade elementos formateados: icono de usuario (si existe), título "You" y el cuerpo del mensaje con indentación.

- `appendAIMessage(String message, boolean isStreaming)`:
  - Inserta en `textInfo` el título de la IA ("Xat IETI") y deja un `Text` para la respuesta de la IA. Si `isStreaming==true` deja el `Text` listo para ser actualizado.

- `updateAIMessage(String message)`:
  - Reemplaza el texto del último elemento en `textInfo` con `message` (aplica indentación) — usado por streaming y por respuestas completas.

- `showSimpleMessage(String message)`:
  - Muestra un único `Text` en `textInfo` con el mensaje proporcionado (útil para errores o avisos).

Utilidades y estado
- `tryParseAnyMessage(String bodyStr)`: intenta parsear el body de la respuesta como JSON y extraer `response`, `message` o `error`.
- `resetButtons()`: reactiva `send` y `upload`, desactiva `cancel`, limpia peticiones y `selectedImageBase64`.
- `ensureModelLoaded(String modelName)`: comprueba `GET /api/ps` si el modelo está cargado; si no lo está envía una petición `generate` con `model` para forzar su precarga. Devuelve un `CompletableFuture<Void>` que completa cuando el modelo está listo.

Estado y concurrencia relevantes
- `httpClient`: cliente HTTP compartido.
- `streamRequest` / `completeRequest`: referencias a las peticiones asíncronas para poder cancelarlas.
- `isCancelled`: `AtomicBoolean` para coordinar cancelaciones.
- `executorService` + `streamReadingTask`: para procesar el InputStream de streaming fuera del hilo de JavaFX.
- `selectedImageBase64`: si no es `null` se envía la imagen al servidor de inferencia en la siguiente `handleSend`.

Cómo explicarlo al profesor (puntos clave)
- Explica primero el flujo del usuario: seleccionar imagen (opcional) -> escribir mensaje -> pulsar enviar.
- Si hay imagen: petición bloqueante (espera completa) a modelo de visión; si no, se usa streaming para que la UI muestre texto incrementalmente.
- Señala la robustez: cancelación de peticiones, cierre de streams, manejo de excepciones y feedback al usuario.
- Menciona `ensureModelLoaded` como mecanismo para evitar latencias en la primera inferencia.

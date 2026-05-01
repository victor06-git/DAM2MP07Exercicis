# Granite 4:3B + Ollama Integration

## Configuración

### 1. Instalar Ollama

```bash
# En tu máquina local
curl -fsSL https://ollama.ai/install.sh | sh
```

### 2. Descargar modelo Granite 2:3B

```bash
ollama pull granite2:3b
```

### 3. Iniciar servidor Ollama

```bash
ollama serve
```

El servidor correrá en `http://localhost:11434` por defecto.

## Uso en la app

### Llamada simple (sin streaming)

```dart
final appData = Provider.of<AppData>(context);
await appData.callGraniteSimple(
  userPrompt: 'Dibuja un círculo en el centro'
);
```

### Llamada con streaming

```dart
await appData.callGraniteStreaming(
  userPrompt: 'Describa el siguiente comando en pasos'
);
```

### Verificar conexión

```dart
final connected = await appData.checkOllamaConnection();
if (connected) {
  print('Ollama con Granite está disponible');
} else {
  print('Ollama no está disponible');
}
```

## Servicio OllamaService

Ubicado en `lib/ollama_service.dart`:

- `OllamaService.generateText(prompt)` - Llamada simple
- `OllamaService.generateTextStream(prompt)` - Streaming
- `OllamaService.checkConnection()` - Verificar disponibilidad

## Modelos disponibles

Puedes cambiar el modelo editando la constante `model` en `ollama_service.dart`:

```dart
static const String model = 'granite2:3b';
```

Otros modelos populares:
- `mistral:latest`
- `llama2:latest`
- `neural-chat:latest`

## Troubleshooting

Si Ollama no responde:

```bash
# Verificar que está corriendo
curl http://localhost:11434/api/tags

# Usar desde terminal
curl -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model": "granite2:3b", "prompt": "Hola", "stream": false}'
```

## Notas

- La app espera que Ollama esté corriendo localmente en puerto 11434
- Timeout por defecto: 60 segundos para llamadas simples
- Los modelos deben descargarse una sola vez

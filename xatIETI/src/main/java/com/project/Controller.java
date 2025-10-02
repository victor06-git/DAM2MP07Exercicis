package com.project;

import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.control.TextField;
import javafx.fxml.FXML;
import javafx.scene.control.Button;
import javafx.scene.text.Text;
import javafx.event.ActionEvent;
import javafx.application.Platform;
import java.net.URL;
import java.util.ResourceBundle;
import javafx.fxml.Initializable;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.http.HttpRequest.BodyPublishers;
import java.nio.charset.StandardCharsets;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.InputStream;
import java.io.File;
import java.nio.file.Files;
import java.util.Base64;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.atomic.AtomicBoolean;
import javafx.stage.FileChooser;
import javafx.scene.text.Font;
import javafx.scene.text.FontWeight;
import javafx.scene.text.FontPosture;
import javafx.scene.text.TextFlow;

import org.json.JSONArray;
import org.json.JSONObject;

public class Controller implements Initializable {

    // Models
    private static final String TEXT_MODEL   = "gemma3:1b";
    private static final String VISION_MODEL = "llava-phi3";

    @FXML
    private Button uploadButton, sendButton;

    @FXML
    private TextFlow textInfo;

    @FXML
    private ImageView uploadImage, sendImage; 

    @FXML
    private TextField messageText;

    private final HttpClient httpClient = HttpClient.newHttpClient();
    private CompletableFuture<HttpResponse<InputStream>> streamRequest;
    private CompletableFuture<HttpResponse<String>> completeRequest;
    private final AtomicBoolean isCancelled = new AtomicBoolean(false);
    private InputStream currentInputStream;
    private final ExecutorService executorService = Executors.newSingleThreadExecutor();
    private Future<?> streamReadingTask;
    private volatile boolean isFirst = false;
    
    // Variable per guardar la imatge seleccionada
    private String selectedImageBase64 = null;
    private String currentUserMessage = "";
    private Image aiIcon;

    // Funció initializable per afegir imatges als botons
    @Override
    public void initialize(URL url, ResourceBundle rb) {
        Image img = new Image(getClass().getResourceAsStream("/icons/upload.jpg"));
        uploadImage.setImage(img);
        Image img_character = new Image(getClass().getResourceAsStream("/icons/send.jpg"));
        sendImage.setImage(img_character);

        //Carregar la imatge de Xat IETI
        try{
            aiIcon = new Image(getClass().getResourceAsStream("/icons/ai_icon.png"));
        } catch (Exception e) {
            System.out.println("No s'ha pogut carregar la icona de la IA");
            aiIcon = null;
        }
        
        // Configurar botó Send desactivat inicialment
        sendButton.setDisable(false);
    }

    // --- UI Actions ---

    @FXML
    private void handleUpload(ActionEvent event) {
        // Escollir arxiu d'imatge
        FileChooser fc = new FileChooser();
        fc.setTitle("Choose an image");
        fc.getExtensionFilters().addAll(
            new FileChooser.ExtensionFilter("Images", "*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp", "*.gif")
        );

        // Establir directori inicial
        File initialDir = new File(System.getProperty("user.dir"));
        if (initialDir.exists() && initialDir.isDirectory()) {
            fc.setInitialDirectory(initialDir);
        }

        File file = fc.showOpenDialog(uploadButton.getScene().getWindow()); 
        if (file == null) {
            showSimpleMessage("No s'ha seleccionat cap fitxer.");
            return;
        }

        // Llegir arxiu i convertir a base64
        try {
            byte[] bytes = Files.readAllBytes(file.toPath());
            selectedImageBase64 = Base64.getEncoder().encodeToString(bytes);
            showSimpleMessage("Imatge carregada: " + file.getName());
        } catch (Exception e) {
            e.printStackTrace();
            showSimpleMessage("Error llegint la imatge.");
            selectedImageBase64 = null;
        }
    }

    //Acción botón enviar texto
    @FXML
    private void handleSend(ActionEvent event) {
        String userMessage = messageText.getText();
        
        if (userMessage == null || userMessage.trim().isEmpty()) {
            showSimpleMessage("Escriu un missatge abans d'enviar.");
            return;
        }

        //Guardar missatge de l'usuari
        currentUserMessage = userMessage;

        //String conversationStart = "You\n" + currentUserMessage + "\n\n";
        displayUserMessage(currentUserMessage);

        isCancelled.set(false);
        
        // Desactivar botó mentre processa
        sendButton.setDisable(true);
        uploadButton.setDisable(true);

        if (selectedImageBase64 != null) {
            // Petició amb imatge (visió)
            appendAIMessage("Thinking...", false);
            ensureModelLoaded(VISION_MODEL).whenComplete((v, err) -> {
                if (err != null) {
                    Platform.runLater(() -> { 
                        updateAIMessage("Error carregant el model de visió."); 
                        resetButtons(); 
                    });
                    return;
                }
                executeImageRequest(VISION_MODEL, userMessage, selectedImageBase64);
            });
        } else {
            // Petició només amb text (streaming)
            appendAIMessage("", true);
            ensureModelLoaded(TEXT_MODEL).whenComplete((v, err) -> {
                if (err != null) {
                    Platform.runLater(() -> { 
                        updateAIMessage("Error carregant el model de text."); 
                        resetButtons(); 
                    });
                    return;
                }
                executeTextRequest(TEXT_MODEL, userMessage, true);
            });
        }

        //Netejar el component
        messageText.clear();
    }

    // --- Request Helpers ---

    // Petició de text amb streaming
    private void executeTextRequest(String model, String prompt, boolean stream) {
        JSONObject body = new JSONObject()
            .put("model", model)
            .put("prompt", prompt)
            .put("stream", stream)
            .put("keep_alive", "10m");

        HttpRequest request = HttpRequest.newBuilder()
            .uri(URI.create("http://localhost:11434/api/generate"))
            .header("Content-Type", "application/json")
            .POST(BodyPublishers.ofString(body.toString()))
            .build();

        if (stream) {
            isFirst = true;

            streamRequest = httpClient.sendAsync(request, HttpResponse.BodyHandlers.ofInputStream())
                .thenApply(response -> {
                    currentInputStream = response.body();
                    streamReadingTask = executorService.submit(this::handleStreamResponse);
                    return response;
                })
                .exceptionally(e -> {
                    if (!isCancelled.get()) e.printStackTrace();
                    Platform.runLater(this::resetButtons);
                    return null;
                });
        }
    }

    // Petició amb imatge (resposta completa)
    private void executeImageRequest(String model, String prompt, String base64Image) {
        JSONObject body = new JSONObject()
            .put("model", model)
            .put("prompt", prompt)
            .put("images", new JSONArray().put(base64Image))
            .put("stream", false)
            .put("keep_alive", "10m")
            .put("options", new JSONObject()
                .put("num_ctx", 2048)
                .put("num_predict", 256)
            );

        HttpRequest request = HttpRequest.newBuilder()
            .uri(URI.create("http://localhost:11434/api/generate"))
            .header("Content-Type", "application/json")
            .POST(BodyPublishers.ofString(body.toString()))
            .build();

        completeRequest = httpClient.sendAsync(request, HttpResponse.BodyHandlers.ofString())
            .thenApply(resp -> {
                int code = resp.statusCode();
                String bodyStr = resp.body();

                String msg = tryParseAnyMessage(bodyStr);
                if (msg == null || msg.isBlank()) {
                    msg = (code >= 200 && code < 300) ? "(resposta buida)" : "HTTP " + code + ": " + bodyStr;
                }

                final String toShow = msg;
                Platform.runLater(() -> { 
                    updateAIMessage(toShow);
                    resetButtons(); //Resetea els buttons
                });
                return resp;
            })
            .exceptionally(e -> {
                if (!isCancelled.get()) e.printStackTrace();
                Platform.runLater(() -> { 
                    String conversationStart = "You\n" + currentUserMessage + "\n\n";
                    updateAIMessage("Error en la petició."); 
                    resetButtons(); 
                });
                return null;
            });
    }

    // Llegir resposta en streaming
    private void handleStreamResponse() {
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(currentInputStream, StandardCharsets.UTF_8))) {
            String line;
            StringBuilder aiResponse = new StringBuilder();

            while ((line = reader.readLine()) != null) {
                if (isCancelled.get()) break;
                if (line.isBlank()) continue;

                JSONObject jsonResponse = new JSONObject(line);
                String chunk = jsonResponse.optString("response", "");
                if (chunk.isEmpty()) continue;

                aiResponse.append(chunk);
                final String currentResponse = aiResponse.toString();

                Platform.runLater(() -> updateAIMessage(currentResponse));
            }
        } catch (Exception e) {
            e.printStackTrace();
            Platform.runLater(() -> { 
                updateAIMessage("Error durant el streaming."); 
                resetButtons(); 
            });
        } finally {
            try { 
                if (currentInputStream != null) currentInputStream.close(); 
            } catch (Exception ignore) {}
            Platform.runLater(this::resetButtons);
        }
    }

    // --- Display Method ---

    private void displayUserMessage(String message) {
        Platform.runLater(() -> {
            textInfo.getChildren().clear();

            // Títol "You" en negreta i més gran
            Text userTitle = new Text("You\n");
            userTitle.setFont(Font.font("System", FontWeight.BOLD, 18));

            // Missatge de l'usuari
            Text userMsg = new Text(message + "\n\n");
            userMsg.setFont(Font.font("System", 14));

            textInfo.getChildren().addAll(userTitle, userMsg);
        });
    }

    private void appendAIMessage(String message, boolean isStreaming) {
        Platform.runLater(() -> {
            // Crear icona de la IA
            ImageView aiIconView = null;
            if (aiIcon != null) {
                aiIconView = new ImageView(aiIcon);
                aiIconView.setFitWidth(100);
                aiIconView.setFitHeight(100);
                aiIconView.setPreserveRatio(true);
            }
            
            // Títol "Xat IETI" en negreta i més gran
            Text aiTitle = new Text(" Xat IETI\n");
            aiTitle.setFont(Font.font("System", FontWeight.BOLD, 18));
            
            // Missatge de la IA
            Text aiMsg = new Text(message);
            aiMsg.setFont(Font.font("System", 14));
            
            if (aiIconView != null) {
                textInfo.getChildren().addAll(aiIconView, aiTitle, aiMsg);
            } else {
                textInfo.getChildren().addAll(aiTitle, aiMsg);
            }
        });
    }

    private void updateAIMessage(String message) {
        Platform.runLater(() -> {
            // Buscar l'últim Text que correspon al missatge de la IA
            int size = textInfo.getChildren().size();
            if (size > 0) {
                // L'últim element hauria de ser el missatge de la IA
                Text aiMsg = (Text) textInfo.getChildren().get(size - 1);
                aiMsg.setText(message);
            }
        });
    }

    private void showSimpleMessage(String message) {
        Platform.runLater(() -> {
            textInfo.getChildren().clear();
            Text msg = new Text(message);
            msg.setFont(Font.font("System", 14));
            textInfo.getChildren().add(msg);
        });
    }



    // --- Utility Methods ---

    private String tryParseAnyMessage(String bodyStr) {
        try {
            JSONObject o = new JSONObject(bodyStr);
            if (o.has("response")) return o.optString("response", "");
            if (o.has("message"))  return o.optString("message", "");
            if (o.has("error"))    return "Error: " + o.optString("error", "");
        } catch (Exception ignore) {}
        return null;
    }

    private void resetButtons() {
        sendButton.setDisable(false);
        uploadButton.setDisable(false);
        streamRequest = null;
        completeRequest = null;
        // Netejar la imatge seleccionada després d'enviar
        selectedImageBase64 = null;
    }

    // Assegurar que el model està carregat
    private CompletableFuture<Void> ensureModelLoaded(String modelName) {
        return httpClient.sendAsync(
                HttpRequest.newBuilder()
                    .uri(URI.create("http://localhost:11434/api/ps"))
                    .GET()
                    .build(),
                HttpResponse.BodyHandlers.ofString()
            )
            .thenCompose(resp -> {
                boolean loaded = false;
                try {
                    JSONObject o = new JSONObject(resp.body());
                    JSONArray models = o.optJSONArray("models");
                    if (models != null) {
                        for (int i = 0; i < models.length(); i++) {
                            String name = models.getJSONObject(i).optString("name", "");
                            String model = models.getJSONObject(i).optString("model", "");
                            if (name.startsWith(modelName) || model.startsWith(modelName)) { 
                                loaded = true; 
                                break; 
                            }
                        }
                    }
                } catch (Exception ignore) {}

                if (loaded) return CompletableFuture.completedFuture(null);

                Platform.runLater(() -> updateAIMessage("Carregant model..."));

                String preloadJson = new JSONObject()
                    .put("model", modelName)
                    .put("stream", false)
                    .put("keep_alive", "10m")
                    .toString();

                HttpRequest preloadReq = HttpRequest.newBuilder()
                    .uri(URI.create("http://localhost:11434/api/generate"))
                    .header("Content-Type", "application/json")
                    .POST(BodyPublishers.ofString(preloadJson))
                    .build();

                return httpClient.sendAsync(preloadReq, HttpResponse.BodyHandlers.ofString())
                        .thenAccept(r -> { /* model carregat */ });
            });
    }
}
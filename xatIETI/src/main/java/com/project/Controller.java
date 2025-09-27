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

import org.json.JSONArray;
import org.json.JSONObject;

public class Controller implements Initializable {

    // Models
    private static final String TEXT_MODEL   = "gemma3:1b";
    private static final String VISION_MODEL = "llava-phi3";

    @FXML
    private Button uploadButton, sendButton;

    @FXML
    private Text textInfo;

    @FXML
    private ImageView uploadImage, sendImage; 

    @FXML
    private TextField messageText;

    //Funció initalizable per afegir imatges als botons
    @Override
    public void initialize(URL url, ResourceBundle rb) {
        Image img = new Image(getClass().getResourceAsStream("/icons/upload.jpg"));
        uploadImage.setImage(img);
        Image img_character = new Image(getClass().getResourceAsStream("/icons/send.jpg"));
        sendImage.setImage(img_character);
    }
}

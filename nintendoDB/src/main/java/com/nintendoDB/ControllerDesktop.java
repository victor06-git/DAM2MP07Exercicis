package com.nintendoDB;

import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ResourceBundle;

import org.json.JSONArray;
import org.json.JSONObject;

import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.fxml.Initializable;
import javafx.scene.Parent;
import javafx.scene.control.ChoiceBox;
import javafx.scene.control.Label;
import javafx.scene.control.TextField;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.layout.VBox;
import javafx.scene.shape.Circle;


public class ControllerDesktop implements Initializable {

    @FXML
    private ChoiceBox<String> choiceTitle;
    String seriesDB[] = { "Personatges", "Series TV", "Canals TV" };


    @FXML
    private VBox list = new VBox();

    @FXML
    private Label labelNom;

    @FXML
    private ImageView image;

    @FXML
    private Circle circle;

    @FXML
    private TextField textFieldDescription;

     public void setNom(String nom){
        this.labelNom.setText(nom);
    }

    public void setCircle(String circle){ 
         this.circle.setStyle(circle);
    }

    public void setSubtitle(String subtitle) {
        this.textFieldDescription.setText(subtitle);
    }

    public void setImage(Image image){
        this.image.setImage(image);
    }

    @Override
    public void initialize(URL location, ResourceBundle resources) {
        choiceTitle.getItems().clear();
        choiceTitle.getItems().addAll(seriesDB);
        choiceTitle.setValue(seriesDB[0]);

        // Cargar lista inicial
        loadList(choiceTitle.getValue());

        // Al cambiar la opción, recarga la lista
        choiceTitle.setOnAction((event) -> {
            String selected = choiceTitle.getValue();
            Main.tema.equals(selected); // <-- aquí se establece el tema
            labelNom.setText(selected);
            loadList(selected); // <-- aquí se carga dinámicamente
        });
    }

    public void loadList(String category) {
    try {
        // Selección del archivo JSON en base a la categoría
        String jsonFile = switch (category) {
            case "Personatges" -> "/assets/data/characters.json";
            case "Canals TV" -> "/assets/data/channels.json";
            case "Series TV" -> "/assets/data/series.json";
            default -> null;
        };

        if (jsonFile == null) return;

        URL jsonFileURL = getClass().getResource(jsonFile);
        Path path = Paths.get(jsonFileURL.toURI());
        String content = new String(Files.readAllBytes(path), StandardCharsets.UTF_8);
        JSONArray jsonInfo = new JSONArray(content);

        list.getChildren().clear();

        String pathImages = "/assets/images0601/"; // Puedes cambiar esto según el tipo

        for (int i = 0; i < jsonInfo.length(); i++) {
            JSONObject item = jsonInfo.getJSONObject(i);

            // Asumiendo que todos tienen estas claves mínimas
            String name = item.optString("name", "Sense nom");
            String image = item.optString("image", "default.png");
            String color = item.optString("color", "#000000");
            
            String subtitle_str = "";

            if (jsonFile.equals("/assets/data/characters.json")) {
                subtitle_str = item.optString("series", "");
            } else if (jsonFile.equals("/assets/data/channels.json")) {
                subtitle_str = item.optString("description", "");
            } else {
                subtitle_str = item.optString("description", "");
            }
            
            // Subview que puede ser común o diferente por categoría
            URL resource = this.getClass().getResource("/assets/subviewDesktop.fxml");
            FXMLLoader loader = new FXMLLoader(resource);
            Parent itemPane = loader.load();
            ControllerItemDesktop itemController = loader.getController();

            itemController.setImage(pathImages + image);
            itemController.setTitle(name);
            itemController.setCircleColor(color);
            itemController.setSubtitle(subtitle_str);

            list.getChildren().add(itemPane);
        }

    } catch (Exception e) {
        System.err.println("Error al cargar la lista de: " + category);
        e.printStackTrace();
    }
}
    
}
    

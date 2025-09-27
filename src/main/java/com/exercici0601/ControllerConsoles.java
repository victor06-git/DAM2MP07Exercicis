package com.exercici0601;

import com.utils.*;

import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Objects;
import java.util.ResourceBundle;

import org.json.JSONArray;
import org.json.JSONObject;

import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.fxml.FXMLLoader;
import javafx.scene.control.Label;
import javafx.scene.Parent;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.VBox;

public class ControllerConsoles implements Initializable {

    @FXML
    private ImageView imgArrowBack;

    @FXML
    private VBox list;

    @Override
    public void initialize(URL url, ResourceBundle rb) {
        Path imagePath = null;
        try {
            URL imageURL = getClass().getResource("/assets/images0601/arrow-back.png");
            Image image = new Image(imageURL.toExternalForm());
            imgArrowBack.setImage(image);
        } catch (Exception e) {
            System.err.println("Error loading image asset: " + imagePath);
            e.printStackTrace();
        }
    }

    public void loadList() {
        try {
            URL jsonFileURL = getClass().getResource("/assets/data/consoles.json");
            Path path = Paths.get(jsonFileURL.toURI());
            String content = new String(Files.readAllBytes(path), StandardCharsets.UTF_8);
            JSONArray jsonInfo = new JSONArray(content);
            String pathImages = "/assets/images0601/";

            list.getChildren().clear();
            for (int i = 0; i < jsonInfo.length(); i++) {
                JSONObject character = jsonInfo.getJSONObject(i);
                String name = character.getString("name");
                String color = character.getString("color");
                String date = character.getString("date");
                String cpu = character.getString("procesador");
                String image = character.getString("image");
                Integer units = character.getInt("units_sold");
                
                // TODO: Aquí carregar subvista  
                // amb les dades de cada objecte enlloc d'un Label

                URL resource = this.getClass().getResource("/assets/subviewConsoles.fxml");
                FXMLLoader loader = new FXMLLoader(resource);
                Parent itemPane = loader.load();
                ControllerItem3 itemController = loader.getController();

                itemController.setCircleColor(color);
                itemController.setCpu(cpu);
                itemController.setDate(date);
                itemController.setImage(pathImages + image);
                itemController.setUnit(units);
                itemController.setTitle(name);

                // Label label = new Label(name);
                // label.setStyle("-fx-border-color: green;");
                list.getChildren().add(itemPane);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    

    @FXML
    private void toViewMain(MouseEvent event) {
        UtilsViews.setViewAnimating("ViewMain");
    }
 
}

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

public class ControllerGames implements Initializable {

    @FXML
    private ImageView imgArrowBack;

    @FXML
    private VBox list_games;

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
            URL jsonFileURL = getClass().getResource("/assets/data/games.json");
            Path path = Paths.get(jsonFileURL.toURI());
            String content = new String(Files.readAllBytes(path), StandardCharsets.UTF_8);
            JSONArray jsonInfo = new JSONArray(content);
            String pathImages = "/assets/images0601/";

            list_games.getChildren().clear();
            for (int i = 0; i < jsonInfo.length(); i++) {
                JSONObject character = jsonInfo.getJSONObject(i);
                String name = character.getString("name");
                String type = character.getString("type");
                String plot = character.getString("plot");
                String image = character.getString("image");
                Integer year = character.getInt("year");
                
                // TODO: Aquí carregar subvista  
                // amb les dades de cada objecte enlloc d'un Label

                URL resource = this.getClass().getResource("/assets/subviewGames.fxml");
                FXMLLoader loader = new FXMLLoader(resource);
                Parent itemPane = loader.load();
                ControllerItem2 itemController = loader.getController();

                itemController.setImage(pathImages + image);
                itemController.setTitle(name);
                itemController.setSubtitle(type);
                itemController.setYear(year);
                itemController.setPlot(plot);

                // Label label = new Label(name);
                // label.setStyle("-fx-border-color: green;");


                list_games.getChildren().add(itemPane);
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

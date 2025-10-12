package com.project;

import java.net.URL;
import java.nio.file.Path;
import java.util.ResourceBundle;

import org.json.JSONObject;

import com.utils.*;

import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.control.Label;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.input.MouseEvent;
import javafx.scene.shape.Circle;

public class ControllerCharacter implements Initializable {
    @FXML
    private Label nom, serie;

    @FXML
    private Circle circle;

    @FXML
    private ImageView image, imgArrowBack;

    @Override
    public void initialize(URL url, ResourceBundle rb) {
        if (Main.currentObject != -1 && "Characters".equals(Main.currentJSON)) {
            System.out.println("➡️ Cambiando a ViewCharacter con JSON = " + Main.currentJSON);
            showData();
        }

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

    public void showData() {
        if (Main.currentObject == -1 || Main.currentObjects.isEmpty()) {
            return;
        }

        JSONObject character = Main.currentObjects.get(Main.currentObject);

        try {
            String name = character.getString("name");
            setNom(name);

            String series = character.getString("series");
            setSeries(series);

            String color = character.getString("color");
            setCircle(color);

            String imagePath = "/assets/images0601/" + character.getString("image");
            Image img = new Image(getClass().getResourceAsStream(imagePath));
            setImage(img);

        } catch (Exception e) {
            System.err.println("Error displaying character data");
            e.printStackTrace();
        }
    }

    public void setNom(String nom) {
        this.nom.setText(nom);
    }

    public void setCircle(String circle) {
        this.circle.setStyle("-fx-fill: " + circle + ";");

    }

    public void setSeries(String series) {
        this.serie.setText(series);
    }

    public void setImage(Image image) {
        this.image.setImage(image);
    }

    @FXML
    private void toViewMain(MouseEvent event) {
        Main.currentObject = -1;

        UtilsViews.setViewAnimating("ViewCharacters");
    }

}

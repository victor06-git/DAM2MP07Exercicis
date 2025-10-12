package com.project;

import java.net.URL;
import java.nio.file.Path;
import java.util.ResourceBundle;

import org.json.JSONObject;

import com.utils.UtilsViews;

import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.control.Label;
import javafx.scene.control.TextArea;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.input.MouseEvent;
import javafx.scene.shape.Circle;

public class ControllerSerie implements Initializable {
    @FXML
    private Label nom;

    @FXML
    private TextArea description;

    @FXML
    private Circle circle;

    @FXML
    private ImageView image, imgArrowBack;

    @Override
    public void initialize(URL url, ResourceBundle rb) {
        if (Main.currentObject != -1 && "Series".equals(Main.currentJSON)) {
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

        showData();
    }

    public void setNom(String nom) {
        this.nom.setText(nom);
    }

    public void setCircle(String circle) {
        this.circle.setStyle("-fx-fill: " + circle + ";");

    }

    public void setDescription(String description) {
        this.description.setText(description);
    }

    public void setImage(Image image) {
        this.image.setImage(image);
    }

    public void showData() {
        if (Main.currentObject == -1 || Main.currentObjects.isEmpty()) {
            return;
        }

        JSONObject serie = Main.currentObjects.get(Main.currentObject);

        try {
            String name = serie.getString("name");
            setNom(name);

            String description = serie.getString("description");
            setDescription(description);

            String color = serie.getString("color");
            setCircle(color);

            String imagePath = "/assets/images0601/" + serie.getString("image");
            Image img = new Image(getClass().getResourceAsStream(imagePath));
            setImage(img);

        } catch (Exception e) {
            System.err.println("Error displaying serie data");
            e.printStackTrace();
        }
    }

    @FXML
    private void toViewMain(MouseEvent event) {
        Main.currentObject = -1;
        UtilsViews.setViewAnimating("ViewSeries");
    }

}

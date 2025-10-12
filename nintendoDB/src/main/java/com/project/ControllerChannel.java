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

public class ControllerChannel implements Initializable {
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
        if (Main.currentObject != -1 && "Channels".equals(Main.currentJSON)) {
            System.out.println("➡️ Cambiando a ViewChannel con JSON = " + Main.currentJSON);
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

    public void showData() {
        if (Main.currentObject == -1 || Main.currentObjects.isEmpty()) {
            return;
        }

        JSONObject channel = Main.currentObjects.get(Main.currentObject);

        try {
            String name = channel.getString("name");
            setNom(name);

            String desc = channel.getString("description");
            setDescription(desc);

            String color = channel.getString("color");
            setCircle(color);

            String imagePath = "/assets/images0601/" + channel.getString("image");
            Image img = new Image(getClass().getResourceAsStream(imagePath));
            setImage(img);

        } catch (Exception e) {
            System.err.println("Error displaying channel data");
            e.printStackTrace();
        }
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

    @FXML
    private void toViewMain(MouseEvent event) {
        Main.currentObject = -1;
        UtilsViews.setViewAnimating("ViewChannels");
    }

}

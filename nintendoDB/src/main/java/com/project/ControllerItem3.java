package com.project;

import java.util.Objects;

import com.utils.UtilsViews;

import javafx.fxml.FXML;
import javafx.scene.control.Label;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.input.MouseEvent;
import javafx.scene.shape.Circle;

public class ControllerItem3 {

    @FXML
    private Label title;

    @FXML
    private ImageView image;

    @FXML
    private Circle circle;

    private String description;

    private int index;

    public void setTitle(String title) {
        this.title.setText(title);
    }

    public void setImage(String imagePath) {
        try {
            Image image = new Image(Objects.requireNonNull(getClass().getResourceAsStream(imagePath)));
            this.image.setImage(image);
        } catch (NullPointerException e) {
            System.err.println("Error loading image asset: " + imagePath);
            e.printStackTrace();
        }
    }

    public void setCircleColor(String color) {
        circle.setStyle("-fx-fill: " + color);
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public void setIndex(int index) {
        this.index = index;
    }

    public void toViewChannel(MouseEvent event) {
        Main.currentObject = index;
        Main.currentJSON = "Channels";

        ControllerChannel crtl = (ControllerChannel) UtilsViews.getController("ViewChannel");
        if (crtl != null) {
            crtl.showData();
        }

        UtilsViews.setViewAnimating("ViewChannel");
    }
}

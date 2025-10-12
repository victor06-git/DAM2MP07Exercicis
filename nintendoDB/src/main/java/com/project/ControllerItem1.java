package com.project;

import java.util.Objects;

import com.utils.UtilsViews;

import javafx.fxml.FXML;
import javafx.scene.control.Label;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.input.MouseEvent;
import javafx.scene.shape.Circle;

public class ControllerItem1 {

    @FXML
    private Label title, subtitle;

    @FXML
    private ImageView image;

    @FXML
    private Circle circle;

    private int index;

    public void setTitle(String title) {
        this.title.setText(title);
    }

    public void setSubtitle(String subtitle) {
        this.subtitle.setText(subtitle);
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

    public void setIndex(int index) {
        this.index = index;
    }

    public void toViewCharacter(MouseEvent event) {
        Main.currentObject = index;
        Main.currentJSON = "Characters";

        ControllerCharacter crtl = (ControllerCharacter) UtilsViews.getController("ViewCharacter");
        if (crtl != null) {
            crtl.showData();
        }
        UtilsViews.setViewAnimating("ViewCharacter");
    }
}

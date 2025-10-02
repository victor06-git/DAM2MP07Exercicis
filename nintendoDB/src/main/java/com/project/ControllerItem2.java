package com.project;

import java.util.Objects;

import com.utils.UtilsViews;

import javafx.fxml.FXML;
import javafx.scene.control.Label;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.input.MouseEvent;
import javafx.scene.shape.Circle;


public class ControllerItem2 {
    
    @FXML
    private Label title;

    @FXML
    private ImageView image;

    @FXML
    private Circle circle;

    private String description;

    public void setDescription(String description){
        this.description = description;
    }

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

    public void toViewSerie(MouseEvent event){
        ControllerSerie crtl = (ControllerSerie) UtilsViews.getController("ViewSerie");
        crtl.setNom(title.getText());
        crtl.setCircle(circle.getStyle());
        crtl.setImage(image.getImage());
        crtl.setDescription(description);
        
        UtilsViews.setViewAnimating("ViewSerie");
    }
}

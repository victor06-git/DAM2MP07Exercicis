package com.exercici0601;

import java.util.Objects;

import com.utils.UtilsViews;

import javafx.fxml.FXML;
import javafx.scene.control.Label;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.control.TextArea;
import javafx.scene.input.MouseEvent;
import javafx.scene.shape.Circle;


public class ControllerItem2 {
    
    @FXML
    private Label title, subtitle, year;

    @FXML
    private TextArea  plot;

    @FXML
    private ImageView image;

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

    public void setPlot(String text) {
        this.plot.setText(text);
    }

    public void setYear(Integer year) {
        this.year.setText(Integer.toString(year));
    }

    public void toViewGame(MouseEvent event){
        ControllerGame crtl = (ControllerGame) UtilsViews.getController("ViewGame");
        crtl.setNom(title.getText());
        crtl.setImage(image.getImage());
        crtl.setPlot(plot.getText());
        crtl.setType(subtitle.getText());
        crtl.setYear(year.getText());
        UtilsViews.setViewAnimating("ViewGame");
    }

}

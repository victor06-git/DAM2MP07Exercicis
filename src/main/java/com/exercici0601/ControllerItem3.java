package com.exercici0601;

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
    private Label title, date, cpu, unit;

    @FXML
    private Circle circle;

    @FXML
    private ImageView image;

    public void setTitle(String title) {
        this.title.setText(title);
    }

    public void setDate(String date) {
        this.date.setText(date);
    }

    public void setCpu(String cpu) {
        this.cpu.setText(cpu);
    }

    public void setUnit(Integer unit) {
        this.unit.setText(Integer.toString(unit));
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

    public void toViewConsole(MouseEvent event){
        ControllerConsole crtl = (ControllerConsole) UtilsViews.getController("ViewConsole");
        crtl.setNom(title.getText());
        crtl.setCircle(circle.getStyle());
        crtl.setCpu(cpu.getText());
        crtl.setDate(date.getText());
        crtl.setImage(image.getImage());
        crtl.setUnit(unit.getText());
        UtilsViews.setViewAnimating("ViewConsole");
    }

}

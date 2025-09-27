package com.exercici0601;

import java.net.URL;
import java.nio.file.Path;
import java.util.ResourceBundle;

import com.utils.UtilsViews;

import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.control.Label;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.input.MouseEvent;
import javafx.scene.shape.Circle;
import javafx.scene.text.Text;


public class ControllerConsole implements Initializable{
    @FXML
    private Label nom, cpu, units, date;

    @FXML
    private Circle circle;

    @FXML
    private ImageView image, imgArrowBack;

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

    public void setNom(String nom){
        this.nom.setText(nom);
    }

    public void setImage(Image image){
        this.image.setImage(image);
    }

    public void setUnit(String unit) {
        this.units.setText(unit);
    }

    public void setCpu(String cpu){
        this.cpu.setText(cpu);
    }

    public void setCircle(String circle){ 
        this.circle.setStyle(circle);
    }

    public void setDate(String date){
        this.date.setText(date);
    }

    @FXML
    private void toViewMain(MouseEvent event) {
        UtilsViews.setViewAnimating("ViewConsoles");
    }

}

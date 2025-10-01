package com.nintendoDB;

import java.net.URL;
import java.util.ResourceBundle;

import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.control.ChoiceBox;
import javafx.scene.control.Label;
import javafx.scene.control.TextField;
import javafx.scene.image.ImageView;
import javafx.scene.layout.VBox;


public class ControllerDesktop implements Initializable {

    @FXML
    private ChoiceBox<String> choiceTitle;
    String seriesDB[] = { "Personatges", "Canals TV", "Series TV" };


    @FXML
    private VBox list;

    @FXML
    private Label labelNom;

    @FXML
    private ImageView image;

    @FXML
    private TextField textFieldDescription;

    @Override
    public void initialize(URL location, ResourceBundle resources) {
        
        choiceTitle.getItems().clear();
        choiceTitle.getItems().addAll(seriesDB);
        choiceTitle.setValue(seriesDB[0]);
        choiceTitle.setOnAction((event) -> {
            labelNom.setText(choiceTitle.getValue().toString());
        });
    }
    
    
}
    

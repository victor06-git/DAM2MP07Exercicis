package com.project;

import com.utils.UtilsViews;

import javafx.fxml.FXML;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.input.MouseEvent;

public class ControllerMain {

    @FXML
    private ImageView image;

    @FXML
    private ImageView characterImage, seriesImage, channelImage;

    @FXML
    public void initialize() {
        Image img = new Image(getClass().getResourceAsStream("/icons/simpsons.gif"));
        image.setImage(img);
        Image img_character = new Image(getClass().getResourceAsStream("/icons/scooby.gif"));
        characterImage.setImage(img_character);
        Image img_serie = new Image(getClass().getResourceAsStream("/icons/picapiedra.gif"));
        seriesImage.setImage(img_serie);
        Image img_channel = new Image(getClass().getResourceAsStream("/icons/simpson.gif"));
        channelImage.setImage(img_channel);

    }

    @FXML
    private void toViewCharacters(MouseEvent event) {
        Main.currentJSON = "Characters";
        ControllerCharacters ctrlCharacters = (ControllerCharacters) UtilsViews.getController("ViewCharacters");
        ctrlCharacters.loadList();
        UtilsViews.setViewAnimating("ViewCharacters");
    }

    @FXML
    private void toViewSeries(MouseEvent event) {
        Main.currentJSON = "Series";
        ControllerSeries ctrlSeries = (ControllerSeries) UtilsViews.getController("ViewSeries");
        ctrlSeries.loadList();
        UtilsViews.setViewAnimating("ViewSeries");
    }

    @FXML
    private void toViewChannels(MouseEvent event) {
        Main.currentJSON = "Channels";
        ControllerChannels ctrlChannels = (ControllerChannels) UtilsViews.getController("ViewChannels");
        ctrlChannels.loadList();
        UtilsViews.setViewAnimating("ViewChannels");
    }

}

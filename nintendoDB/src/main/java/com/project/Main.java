package com.project;

import java.util.ArrayList;

import org.json.JSONObject;

import com.utils.UtilsViews;

import javafx.application.Application;
import javafx.application.Platform;
import javafx.beans.value.ChangeListener;
import javafx.beans.value.ObservableValue;
import javafx.scene.Scene;
import javafx.scene.image.Image;
import javafx.stage.Stage;

// Fes anar l'exemple amb:
// ./run.sh com.exercici0601.Main

public class Main extends Application {

    final int WINDOW_WIDTH = 450;
    final int WINDOW_HEIGHT = 500;

    public static ArrayList<JSONObject> currentObjects = new ArrayList<>();
    public static int currentObject = -1;
    public static String currentJSON = "Characters";

    public static void main(String[] args) {
        launch(args);
    }

    @Override
    public void start(Stage stage) throws Exception {

        UtilsViews.parentContainer.setStyle("-fx-font: 14 arial;");
        UtilsViews.addView(getClass(), "Mobile", "/assets/viewMain.fxml");
        UtilsViews.addView(getClass(), "ViewCharacters", "/assets/viewCharacters.fxml");
        UtilsViews.addView(getClass(), "ViewCharacter", "/assets/viewCharacter.fxml");
        UtilsViews.addView(getClass(), "Desktop", "/assets/viewDesktop.fxml");
        UtilsViews.addView(getClass(), "ViewSeries", "/assets/viewSeries.fxml");
        UtilsViews.addView(getClass(), "ViewSerie", "/assets/viewSerie.fxml");
        UtilsViews.addView(getClass(), "ViewChannels", "/assets/viewChannels.fxml");
        UtilsViews.addView(getClass(), "ViewChannel", "/assets/viewChannel.fxml");

        Scene scene = new Scene(UtilsViews.parentContainer);

        // Listen to window width changes
        scene.widthProperty().addListener((ChangeListener<? super Number>) new ChangeListener<Number>() {
            @Override
            public void changed(ObservableValue<? extends Number> observable, Number oldWidth, Number newWidth) {
                _setLayout(newWidth.intValue());
            }
        });

        stage.setScene(scene);
        stage.setTitle("Series DB");
        stage.setWidth(WINDOW_WIDTH);
        stage.setHeight(WINDOW_HEIGHT);
        stage.show();
        UtilsViews.setView("Mobile");

        // Add icon only if not Mac
        if (!System.getProperty("os.name").contains("Mac")) {
            Image icon = new Image("file:/icons/icon.png");
            stage.getIcons().add(icon);
        }
    }

    private void _setLayout(int width) {

        if (width < 750) {
            // Vista MOBILE
            if (currentObject != -1) {
                showDetailView();
            } else if (!currentObjects.isEmpty()) {
                showListView();
            } else {
                UtilsViews.setView("Mobile");
            }
        } else {
            UtilsViews.setView("Desktop");

            ControllerDesktop ctrlDesktop = (ControllerDesktop) UtilsViews.getController("Desktop");
            if (ctrlDesktop != null) {
                Platform.runLater(() -> {
                    ctrlDesktop.refresh(Main.currentJSON, Main.currentObject);
                });
            }
        }
    }

    private void showDetailView() {

        if (Main.currentObject == -1 || Main.currentObjects.isEmpty()) {
            showListView();
            return;
        }

        switch (currentJSON) {
            case "Characters":
                UtilsViews.setView("ViewCharacter");
                // Obtener el controlador y cargar datos
                ControllerCharacter ctrlCharacter = (ControllerCharacter) UtilsViews.getController("ViewCharacter");
                if (ctrlCharacter != null) {
                    Platform.runLater(() -> ctrlCharacter.showData());
                }
                break;
            case "Series":
                UtilsViews.setView("ViewSerie");
                ControllerSerie ctrlSerie = (ControllerSerie) UtilsViews.getController("ViewSerie");
                if (ctrlSerie != null) {
                    Platform.runLater(() -> ctrlSerie.showData());
                }
                break;
            case "Channels":
                UtilsViews.setView("ViewChannel");
                ControllerChannel ctrlChannel = (ControllerChannel) UtilsViews.getController("ViewChannel");
                if (ctrlChannel != null) {
                    Platform.runLater(() -> ctrlChannel.showData());
                }
                break;
            default:
                UtilsViews.setView("Mobile");
        }
    }

    private void showListView() {
        switch (currentJSON) {
            case "Characters":
                UtilsViews.setView("ViewCharacters");
                break;
            case "Series":
                UtilsViews.setView("ViewSeries");
                break;
            case "Channels":
                UtilsViews.setView("ViewChannels");
                break;
            default:
                UtilsViews.setView("Mobile");
        }
    }
}

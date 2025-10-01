package com.nintendoDB;
import com.utils.UtilsViews;

import javafx.application.Application;
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

    static int id = 0; //Valor para pasar la info entre vistas
    static String tema = "Personatges"; //Valor para pasar la info entre vistas

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

        // Afegeix un listener per detectar canvis en les dimensions de la finestra
        stage.widthProperty().addListener((obs, oldVal, newVal) -> {
            System.out.println("Width changed: " + newVal);
        });

        stage.heightProperty().addListener((obs, oldVal, newVal) -> {
            System.out.println("Height changed: " + newVal);
        });

        // Add icon only if not Mac
        if (!System.getProperty("os.name").contains("Mac")) {
            Image icon = new Image("file:/icons/icon.png");
            stage.getIcons().add(icon);
        }
    }

    private void _setLayout(int width) {
        if (width < 600) {
            UtilsViews.setView("Mobile");
        } else {
            UtilsViews.setView("Desktop");
            //ControllerDesktop crtl = (ControllerDesktop) UtilsViews.getController("Desktop");
            //crtl.loadList("Personatges"); // o cualquier valor por defecto
        }
    }
}

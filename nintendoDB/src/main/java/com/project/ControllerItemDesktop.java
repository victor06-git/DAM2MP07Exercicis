package com.project;

import java.util.Objects;

import com.utils.UtilsViews;

import javafx.fxml.FXML;
import javafx.scene.control.Label;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.input.MouseEvent;
import javafx.scene.shape.Circle;

public class ControllerItemDesktop {

    @FXML
    private Label title, subtitle;

    @FXML
    private ImageView image;

    @FXML
    private Circle circle;

    private int index; // Indice de la lista json

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

    // Establecer el índice (aunque en Desktop se usa listener directo)
    public void setIndex(int index) {
        this.index = index;
    }

    // NUEVO: Obtener el índice (por si necesitas accederlo desde ControllerDesktop)
    public int getIndex() {
        return this.index;
    }

    @FXML
    public void toViewItem(MouseEvent event) {
        Main.currentObject = index;
        ControllerDesktop ctrl = (ControllerDesktop) UtilsViews.getController("Desktop");
        if (ctrl != null) {
            ctrl.showDetailData(); // Carga el detalle en el panel derecho
        }
    }

}

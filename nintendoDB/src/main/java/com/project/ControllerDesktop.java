package com.project;

import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ResourceBundle;

import org.json.JSONArray;
import org.json.JSONObject;

import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.fxml.Initializable;
import javafx.scene.Parent;
import javafx.scene.control.ChoiceBox;
import javafx.scene.control.Label;
import javafx.scene.control.TextField;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.layout.VBox;
import javafx.scene.shape.Circle;

public class ControllerDesktop implements Initializable {

    @FXML
    private ChoiceBox<String> choiceTitle;
    String seriesDB[] = { "Personatges", "Series TV", "Canals TV" };

    @FXML
    private VBox list = new VBox();

    @FXML
    private Label labelNom;

    @FXML
    private ImageView image;

    @FXML
    private Circle circle;

    @FXML
    private TextField textFieldDescription;

    public void setNom(String nom) {
        this.labelNom.setText(nom);
    }

    public void setCircle(String circle) {
        this.circle.setStyle(circle);
    }

    public void setSubtitle(String subtitle) {
        this.textFieldDescription.setText(subtitle);
    }

    public void setImage(Image image) {
        this.image.setImage(image);
    }

    @Override
    public void initialize(URL location, ResourceBundle resources) {
        choiceTitle.getItems().clear();
        choiceTitle.getItems().addAll(seriesDB);

        // Restaurar la categoría seleccionada previamente
        restoreSelectedCategory();

        // Listener para cambios en el ChoiceBox
        choiceTitle.setOnAction((event) -> {
            String selected = choiceTitle.getValue();
            updateCategory(selected);
        });

        if (Main.currentJSON != null) {
            loadList(getCategoryFromJSON(Main.currentJSON));
        } else {
            // Valor por defecto
            Main.currentJSON = "Characters";
            loadList("Personatges");
        }

        if (Main.currentObject != -1) {
            showDetailData();
        }
    }

    // Restore de la categoria seleccionada
    private void restoreSelectedCategory() {
        if (Main.currentJSON != null) {
            String category = getCategoryFromJSON(Main.currentJSON);
            if (category != null) {
                choiceTitle.setValue(category);
            } else {
                choiceTitle.setValue(seriesDB[0]);
            }
        } else {
            choiceTitle.setValue(seriesDB[0]);
        }
    }

    private String getCategoryFromJSON(String jsonType) {
        switch (jsonType) {
            case "Characters":
                return "Personatges";
            case "Series":
                return "Series TV";
            case "Channels":
                return "Canals TV";
            default:
                return seriesDB[0];
        }
    }

    private String getJSONFromCategory(String category) {
        switch (category) {
            case "Personatges":
                return "Characters";
            case "Series TV":
                return "Series";
            case "Canals TV":
                return "Channels";
            default:
                return null;
        }
    }

    private void updateCategory(String selected) {
        // Actualizar el estado global
        Main.currentJSON = getJSONFromCategory(selected);
        Main.currentObject = -1;

        // Limpiar los detalles
        clearDetails();

        // Cargar nueva lista
        loadList(selected);
    }

    // Posa tot com a default
    private void clearDetails() {
        labelNom.setText("");
        circle.setStyle("");
        textFieldDescription.setText("");
        image.setImage(null);
    }

    // Carrega la llista
    public void loadList(String category) {
        System.out.println("=== loadList called ===");
        System.out.println("category parameter: " + category);

        try {
            // Selección del archivo JSON
            String jsonFile;
            switch (category) {
                case "Personatges":
                    Main.currentJSON = "Characters";
                    jsonFile = "/assets/data/characters.json";
                    break;
                case "Canals TV":
                    Main.currentJSON = "Channels";
                    jsonFile = "/assets/data/channels.json";
                    break;
                case "Series TV":
                    Main.currentJSON = "Series";
                    jsonFile = "/assets/data/series.json";
                    break;
                default:
                    System.err.println("Unknown category: " + category);
                    jsonFile = null;
            }

            if (jsonFile == null) {
                System.err.println("jsonFile is null, returning");
                return;
            }

            System.out.println("Loading JSON file: " + jsonFile);

            URL jsonFileURL = getClass().getResource(jsonFile);
            Path path = Paths.get(jsonFileURL.toURI());
            String content = new String(Files.readAllBytes(path), StandardCharsets.UTF_8);
            JSONArray jsonInfo = new JSONArray(content);

            // Actualizar el estado global
            Main.currentObjects.clear();

            for (int i = 0; i < jsonInfo.length(); i++) {
                Main.currentObjects.add(jsonInfo.getJSONObject(i));
            }

            list.getChildren().clear();

            String pathImages = "/assets/images0601/"; // Puedes cambiar esto según el tipo

            for (int i = 0; i < jsonInfo.length(); i++) {
                JSONObject item = jsonInfo.getJSONObject(i);
                int index = i;

                // Asumiendo que todos tienen estas claves mínimas
                String name = item.optString("name", "");
                String image = item.optString("image", "default.png");
                String color = item.optString("color", "#000000");

                String subtitle_str = "";
                if (jsonFile.equals("/assets/data/characters.json")) {
                    subtitle_str = item.optString("series", "");
                } else {
                    subtitle_str = item.optString("description", "");
                }

                // Subview que puede ser común o diferente por categoría
                URL resource = this.getClass().getResource("/assets/subviewDesktop.fxml");
                FXMLLoader loader = new FXMLLoader(resource);
                Parent itemPane = loader.load();
                ControllerItemDesktop itemController = loader.getController();

                itemController.setImage(pathImages + image);
                itemController.setTitle(name);
                itemController.setCircleColor(color);
                itemController.setSubtitle(subtitle_str);
                itemController.setIndex(index);

                list.getChildren().add(itemPane);
            }

        } catch (Exception e) {
            System.err.println("Error al cargar la lista de: " + category);
            e.printStackTrace();
        }
    }

    public void showDetailData() {
        if (Main.currentObject == -1 || Main.currentObjects.isEmpty()) {
            return;
        }

        JSONObject element = Main.currentObjects.get(Main.currentObject);

        // Actualitzar nom
        String name = element.optString("name", "");
        setNom(name);

        // Carregar imatge
        try {
            String imagePath = "/assets/images0601/" + element.optString("image", "default.png");
            Image img = new Image(getClass().getResourceAsStream(imagePath));
            setImage(img);
        } catch (Exception e) {
            System.err.println("Error loading image: " + element.optString("image", ""));
            e.printStackTrace();
        }

        // Color del cercle
        String color = element.optString("color", "#000000");
        circle.setStyle("-fx-fill: " + color + ";");

        // Descripció segons tipus
        String description = "";
        switch (Main.currentJSON) {
            case "Characters":
                description = "El personatge " + name + " surt a la sèrie " +
                        element.optString("series", "");
                break;
            case "Series":
                description = element.optString("description", "");
                break;
            case "Channels":
                description = element.optString("description", "");
                break;
            default:
                description = "Informació no disponible";
        }

        setSubtitle(description);
    }

    public void refresh(String jsonType, int objectIndex) {
        System.out.println("=== refresh called ===");
        System.out.println("jsonType: " + jsonType + ", objectIndex: " + objectIndex);
        // Actualizar estado global
        Main.currentJSON = jsonType;
        Main.currentObject = objectIndex;
        // Restaurar categoría en ChoiceBox (sin disparar listener para evitar reset de
        // currentObject)
        String category = getCategoryFromJSON(jsonType);
        if (choiceTitle.getItems().contains(category)) {
            choiceTitle.setValue(category); // No dispara onAction porque lo seteamos directamente
        }
        // Cargar lista (esto actualiza currentObjects)
        loadList(category);
        // Si hay selección, mostrar detalle (con delay para asegurar que la vista esté
        // lista)
        if (objectIndex != -1) {
            // Usa Platform.runLater para threading, similar a Mobile
            javafx.application.Platform.runLater(() -> showDetailData());
        } else {
            clearDetails();
        }
    }

}

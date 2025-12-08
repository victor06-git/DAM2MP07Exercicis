import 'cell.dart';
import 'dart:math';

class Board {
  final int rows;
  final int columns;
  final int mineCount;

  // Aquí guardaremos las instancias (los objetos reales)
  // Es una lista de listas de objetos Cell
  List<List<Cell>> grid = [];

  Board({required this.rows, required this.columns, required this.mineCount}) {
    _initializeBoard();
    _placeMines();
    _nearMines();
  }

  // Private method to initialize the board with Cell instances
  void _initializeBoard() {
    for (int r = 0; r < rows; r++) {
      List<Cell> rowList = [];
      for (int c = 0; c < columns; c++) {
        // Calculate position string (e.g., "A0", "B3")
        String letter = String.fromCharCode('A'.codeUnitAt(0) + r);
        String pos = "$letter$c";

        // Create the object (the instance) with 'new Cell' (the new is optional in modern Dart)
        Cell newCell = Cell(position: pos);

        // Add it to the temporary list
        rowList.add(newCell);
      }
      // Add the complete row to the grid
      grid.add(rowList);
    }
  }

  /**
   * @param fMin Row min (inclusive)
   * @param fMax Row max (inclusive)
   * @param cMin Column min (inclusive)
   * @param cMax Column max (inclusive)
   * @param quantity Number of mines to place in the zone
   */
  void _placeMinesInZone(int fMin, int fMax, int cMin, int cMax, int quantity) {
    var rng = Random();
    int mines = 0;

    // Bucle: Mientras no hayamos puesto las minas necesarias...
    while (mines < quantity) {
      // Generate random row and column within the specified zone
      // Fórmula: min + random(max - min + 1)
      int r = fMin + rng.nextInt(fMax - fMin + 1);
      int c = cMin + rng.nextInt(cMax - cMin + 1);

      // Check if there's already a mine
      if (grid[r][c].isMine == false) {
        // 3. Poner la mina
        grid[r][c].isMine = true;

        // Increase counter to exit the loop
        mines++;
      }
    }
  }

  // Method to place mines in four quadrants
  void _placeMines() {
    // Call the helper function for each quadrant
    _placeMinesInZone(0, 2, 0, 4, 2);
    _placeMinesInZone(0, 2, 5, 9, 2);
    _placeMinesInZone(3, 5, 0, 4, 2);
    _placeMinesInZone(3, 5, 5, 9, 2);
  }

  // Function to see near mines
  void _nearMines() {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < columns; c++) {
        if (grid[r][c].isMine) {
          // Check all adjacent cells
          for (int dr = -1; dr <= 1; dr++) {
            for (int dc = -1; dc <= 1; dc++) {
              int newRow = r + dr;
              int newCol = c + dc;

              // Ensure we are within bounds and not the mine itself
              if (newRow >= 0 &&
                  newRow < rows &&
                  newCol >= 0 &&
                  newCol < columns &&
                  !(dr == 0 && dc == 0)) {
                grid[newRow][newCol].adjacentMines++;
              }
            }
          }
        }
      }
    }
  }

  // Method to print the board
  void printBoard({bool revealMines = false}) {
    // Capçalera de columnes
    print("   " + List.generate(columns, (i) => i.toString()).join(" "));
    print("  " + "-" * (columns * 2));

    for (int r = 0; r < rows; r++) {
      String letter = String.fromCharCode('A'.codeUnitAt(0) + r);
      String rowStr = "$letter |";

      for (int c = 0; c < columns; c++) {
        Cell cell = grid[r][c];
        String char = ".";

        // PRIORITAT DE VISUALITZACIÓ:
        // 1. Si es demana revelar tot (Game Over o Cheat)
        if (revealMines) {
          if (cell.isMine)
            char = "*";
          else if (cell.adjacentMines > 0)
            char = cell.adjacentMines.toString();
          else
            char = " ";
        }
        // 2. Si té bandera (sempre visible si no està destapada)
        else if (cell.isFlagged) {
          char = "#"; // Símbol de bandera
        }
        // 3. Si està destapada (jugada normal)
        else if (cell.isRevealed) {
          if (cell.adjacentMines > 0)
            char = cell.adjacentMines.toString();
          else
            char = " "; // Casella buida (0)
        }
        // 4. Si no, està tapada (.)

        rowStr += "$char ";
      }
      print(rowStr);
    }
  }

  // Reveal cell and its neighbors if it's a 0
  void revealCell(int r, int c) {
    // Límits del tauler
    if (r < 0 || r >= rows || c < 0 || c >= columns) return;

    Cell cell = grid[r][c];

    if (cell.isRevealed || cell.isFlagged) return;

    cell.isRevealed = true;

    if (cell.adjacentMines == 0 && !cell.isMine) {
      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          if (dr != 0 || dc != 0) {
            revealCell(r + dr, c + dc);
          }
        }
      }
    }
  }

  // Put or remove a flag on a cell
  bool toggleFlag(int r, int c) {
    if (r >= 0 && r < rows && c >= 0 && c < columns) {
      Cell cell = grid[r][c];
      if (!cell.isRevealed) {
        cell.isFlagged = !cell.isFlagged;
        return true;
      }
    }
    return false;
  }
}

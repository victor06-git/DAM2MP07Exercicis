import 'dart:io';

import 'board.dart';
import 'cell.dart';

void main() {
  print('Welcome to the game!');

  // Bucle PRINCIPAL de la aplicación (para poder reiniciar)
  while (true) {
    // 1. Inicialización de la partida (Reset de variables)
    Board myBoard = Board(rows: 6, columns: 10, mineCount: 8);
    bool cheatMode = false;
    int tirades = 0;
    bool playing = true; // Controla el bucle de la partida actual

    print("\n=================================");
    print("      NOVA PARTIDA INICIADA      ");
    print("=================================");

    // Bucle de la PARTIDA (Juego activo)
    while (playing) {
      print("\n--- BUSCAMINES (Tirades: $tirades) ---");
      myBoard.printBoard(revealMines: cheatMode);

      print(
        "Escriu 'A0' per destapar, 'A0 flag' | 'A0 bandera' per bandera/treure bandera, 'exit' per sortir.",
      );
      stdout.write('> ');
      String? input = stdin.readLineSync();

      // Salida total de la aplicación
      if (input == null || input.toLowerCase() == 'exit') {
        print('Exiting the game. Goodbye!');
        return; // Sale del main() completo
      }

      // Trucos
      if (input.trim().toLowerCase() == 'cheat' ||
          input.trim().toLowerCase() == 'trampes') {
        cheatMode = !cheatMode;
        print(cheatMode ? "Mode cheat activated" : "Mode cheat deactivated");
        continue;
      }

      // Normalización del input
      input = input.toUpperCase().trim();
      bool isFlagAction = false;

      // Lógica de detección de bandera (Corregida para mayúsculas)
      if (input.endsWith('FLAG')) {
        isFlagAction = true;
        input = input.substring(0, input.length - 4).trim();
      } else if (input.endsWith('BANDERA')) {
        isFlagAction = true;
        input = input.substring(0, input.length - 7).trim();
      }

      if (input.length < 2) continue;

      int r = input.codeUnitAt(0) - 'A'.codeUnitAt(0);
      int c = int.tryParse(input.substring(1)) ?? -1;

      // Validar coordenadas
      if (r >= 0 && r < myBoard.rows && c >= 0 && c < myBoard.columns) {
        Cell target = myBoard.grid[r][c];

        if (isFlagAction) {
          // --- ACCIÓN DE BANDERA ---
          bool success = myBoard.toggleFlag(r, c);
          if (success) {
            print(
              target.isFlagged
                  ? "Bandera posada."
                  : "Bandera treta. Casella llesta per descobrir.",
            );
          } else {
            print("No pots posar bandera en una casella destapada.");
          }
        } else {
          // --- ACCIÓN DE DESTAPAR ---
          if (target.isFlagged) {
            print("Hi ha una bandera! Treu-la primer ('$input flag').");
          } else if (target.isRevealed) {
            print("Ja està destapada.");
          } else {
            tirades++; // Solo cuenta si destapa y es válido

            if (target.isMine) {
              // --- GAME OVER ---
              print("\nBOOM! Has trepitjat una mina.");
              print("-----------------------------------");
              myBoard.printBoard(revealMines: true);
              print("-----------------------------------");
              print("Joc acabat.");
              print("Total de tirades realitzades: $tirades");

              playing = false; // Rompemos el bucle interno
            } else {
              myBoard.revealCell(r, c);
              print("Casella segura.");
            }
          }
        }
      } else {
        print("Coordenades invàlides.");
      }
    } // Fin del while (playing)

    // 2. Preguntar si quiere volver a jugar
    stdout.write("\nVols tornar a jugar? (S/N): ");
    String? retry = stdin.readLineSync();
    if (retry == null || retry.toUpperCase() != 'S') {
      print("Gràcies per jugar. Adéu!");
      break; // Rompe el bucle while(true) principal
    }
    // Si dice 'S', el bucle principal se repite y crea un nuevo Board
  }
}

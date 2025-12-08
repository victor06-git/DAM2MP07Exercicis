class Cell {
  final String position;
  bool isRevealed;
  bool isFlagged;
  bool isMine;
  int adjacentMines;

  Cell({
    required this.position,
    this.isRevealed = false,
    this.isFlagged = false,
    this.isMine = false,
    this.adjacentMines = 0,
  });

  void reveal() {
    isRevealed = true;
  }

  void toggleFlag() {
    isFlagged = !isFlagged;
  }
}

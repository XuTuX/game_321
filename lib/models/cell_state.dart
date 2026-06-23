/// 보드 칸의 상태
enum CellState {
  empty,
  player1,
  player2,
}

/// 플레이어
enum Player {
  player1,
  player2,
}

/// 블록 크기
enum BlockSize {
  two,
  three,
}

/// 배치 방향
enum Direction {
  horizontal,
  vertical,
}

/// 게임 진행 단계
enum GamePhase {
  placingBlock,
  selectingForcedCell,
  gameOver,
}

/// 강제칸 좌표
class ForcedCell {
  final int row;
  final int col;

  const ForcedCell(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForcedCell &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => 'ForcedCell($row, $col)';
}

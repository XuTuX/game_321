import 'cell_state.dart';

/// FORCE 게임의 핵심 상태 관리 클래스
class GameState {
  static const int boardSize = 7;

  /// 7x7 보드 상태
  List<List<CellState>> board;

  /// 현재 턴인 플레이어
  Player currentPlayer;

  /// 선택된 블록 크기
  BlockSize selectedBlockSize;

  /// 선택된 배치 방향
  Direction selectedDirection;

  /// 강제칸 (nullable)
  ForcedCell? forcedCell;

  /// 현재 게임 진행 단계
  GamePhase phase;

  /// 승자 (nullable)
  Player? winner;

  /// 에러 메시지
  String? errorMessage;

  GameState()
      : board = List.generate(
            boardSize, (_) => List.filled(boardSize, CellState.empty)),
        currentPlayer = Player.player1,
        selectedBlockSize = BlockSize.two,
        selectedDirection = Direction.horizontal,
        forcedCell = null,
        phase = GamePhase.placingBlock,
        winner = null,
        errorMessage = null;

  /// 게임 초기화
  void reset() {
    board = List.generate(
        boardSize, (_) => List.filled(boardSize, CellState.empty));
    currentPlayer = Player.player1;
    selectedBlockSize = BlockSize.two;
    selectedDirection = Direction.horizontal;
    forcedCell = null;
    phase = GamePhase.placingBlock;
    winner = null;
    errorMessage = null;
  }

  /// 블록 배치 시 차지할 칸들의 좌표 목록을 반환
  /// 보드 밖으로 나가면 null
  List<List<int>>? getCellsForPlacement(int row, int col, BlockSize size, Direction dir) {
    int length = size == BlockSize.two ? 2 : 3;
    List<List<int>> cells = [];

    for (int i = 0; i < length; i++) {
      int r = dir == Direction.vertical ? row + i : row;
      int c = dir == Direction.horizontal ? col + i : col;

      if (r < 0 || r >= boardSize || c < 0 || c >= boardSize) {
        return null; // 보드 밖
      }
      cells.add([r, c]);
    }

    return cells;
  }

  /// 배치가 합법적인지 검증
  bool isValidPlacement(int row, int col, BlockSize size, Direction dir) {
    List<List<int>>? cells = getCellsForPlacement(row, col, size, dir);
    if (cells == null) return false;

    // 이미 채워진 칸이 있으면 invalid
    for (var cell in cells) {
      if (board[cell[0]][cell[1]] != CellState.empty) {
        return false;
      }
    }

    // 강제칸이 있으면 배치 칸 목록에 포함되어야 함
    if (forcedCell != null) {
      bool containsForced = cells.any(
          (cell) => cell[0] == forcedCell!.row && cell[1] == forcedCell!.col);
      if (!containsForced) {
        return false;
      }
    }

    return true;
  }

  /// 특정 플레이어가 합법적으로 둘 수 있는 수가 있는지 검사
  bool hasAnyValidMove({ForcedCell? overrideForcedCell}) {
    ForcedCell? originalForced = forcedCell;
    if (overrideForcedCell != null) {
      forcedCell = overrideForcedCell;
    }

    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        for (var size in BlockSize.values) {
          for (var dir in Direction.values) {
            if (isValidPlacement(row, col, size, dir)) {
              forcedCell = originalForced;
              return true;
            }
          }
        }
      }
    }

    forcedCell = originalForced;
    return false;
  }

  /// 블록 배치 실행
  bool placeBlock(int row, int col) {
    if (phase != GamePhase.placingBlock) return false;

    if (!isValidPlacement(row, col, selectedBlockSize, selectedDirection)) {
      errorMessage = '여기에는 놓을 수 없습니다';
      return false;
    }

    List<List<int>> cells =
        getCellsForPlacement(row, col, selectedBlockSize, selectedDirection)!;
    CellState cellState = currentPlayer == Player.player1
        ? CellState.player1
        : CellState.player2;

    for (var cell in cells) {
      board[cell[0]][cell[1]] = cellState;
    }

    // 강제칸 제거 (배치에 포함되었으므로)
    forcedCell = null;
    errorMessage = null;

    if (selectedBlockSize == BlockSize.two) {
      // 2칸 블록: 강제칸 선택 단계로 전환
      phase = GamePhase.selectingForcedCell;
      return true;
    } else {
      // 3칸 블록: 즉시 턴 변경
      _switchTurn();
      return true;
    }
  }

  /// 강제칸 지정
  bool selectForcedCell(int row, int col) {
    if (phase != GamePhase.selectingForcedCell) return false;

    // 빈 칸만 강제칸으로 선택 가능
    if (board[row][col] != CellState.empty) {
      errorMessage = '빈 칸만 강제칸으로 지정할 수 있습니다';
      return false;
    }

    ForcedCell candidate = ForcedCell(row, col);

    // 상대가 이 강제칸을 포함해서 놓을 수 있는지 확인
    // (놓을 수 없는 강제칸도 지정 가능 — 규칙상 강제칸을 포함하는 합법적 배치가 없으면 상대 패배)
    forcedCell = candidate;
    errorMessage = null;

    _switchTurn();
    return true;
  }

  /// 턴 변경
  void _switchTurn() {
    currentPlayer =
        currentPlayer == Player.player1 ? Player.player2 : Player.player1;

    // 다음 플레이어가 합법적으로 둘 수 있는 수가 있는지 확인
    if (!hasAnyValidMove()) {
      // 둘 수 없으면 이전 플레이어 승리
      winner = currentPlayer == Player.player1 ? Player.player2 : Player.player1;
      phase = GamePhase.gameOver;
    } else {
      phase = GamePhase.placingBlock;
    }
  }

  /// 미리보기용: 배치할 셀 좌표 목록 반환 (유효한 경우만)
  List<List<int>>? getPreviewCells(int row, int col) {
    List<List<int>>? cells =
        getCellsForPlacement(row, col, selectedBlockSize, selectedDirection);
    if (cells == null) return null;

    // 칸이 모두 비어있는지만 확인 (강제칸 체크 제외 — 미리보기용)
    for (var cell in cells) {
      if (board[cell[0]][cell[1]] != CellState.empty) {
        return null;
      }
    }

    return cells;
  }

  /// 현재 플레이어의 이름
  String get currentPlayerName =>
      currentPlayer == Player.player1 ? 'Player 1' : 'Player 2';

  /// 현재 플레이어의 반대편 플레이어 이름
  String get opponentName =>
      currentPlayer == Player.player1 ? 'Player 2' : 'Player 1';
}

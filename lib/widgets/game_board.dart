import 'package:flutter/material.dart';
import '../models/cell_state.dart';
import '../models/game_state.dart';

/// 7x7 게임 보드 위젯
class GameBoard extends StatelessWidget {
  final GameState gameState;
  final List<List<int>>? previewCells;
  final bool isPreviewValid;
  final Function(int row, int col) onCellPanDown;
  final Function(int row, int col) onCellPanUpdate;
  final VoidCallback onCellPanEnd;

  const GameBoard({
    super.key,
    required this.gameState,
    required this.onCellPanDown,
    required this.onCellPanUpdate,
    required this.onCellPanEnd,
    this.previewCells,
    this.isPreviewValid = false,
  });

  // 색상 정의
  static const Color player1Color = Color(0xFF4A90D9);
  static const Color player1Light = Color(0xFFB8D4F0);
  static const Color player2Color = Color(0xFFE8853A);
  static const Color player2Light = Color(0xFFF5CDA8);
  static const Color forcedCellColor = Color(0xFF9B59B6);
  static const Color forcedCellLight = Color(0xFFD2B4DE);
  static const Color emptyColor = Color(0xFFF0F0F0);
  static const Color previewValidColor = Color(0x5000C853);
  static const Color previewInvalidColor = Color(0x50FF1744);
  static const Color boardBgColor = Color(0xFFE8E8E8);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: boardBgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              onPanDown: (details) => _handlePan(details.localPosition, constraints.maxWidth, onCellPanDown),
              onPanUpdate: (details) => _handlePan(details.localPosition, constraints.maxWidth, onCellPanUpdate),
              onPanEnd: (details) => onCellPanEnd(),
              child: _buildGrid(),
            );
          },
        ),
      ),
    );
  }

  void _handlePan(Offset localPosition, double width, Function(int, int) callback) {
    double cellSize = width / GameState.boardSize;
    int col = (localPosition.dx / cellSize).floor();
    int row = (localPosition.dy / cellSize).floor();
    if (col >= 0 && col < GameState.boardSize && row >= 0 && row < GameState.boardSize) {
      callback(row, col);
    }
  }

  Widget _buildGrid() {

    return Column(
      children: List.generate(GameState.boardSize, (row) {
        return Expanded(
          child: Row(
            children: List.generate(GameState.boardSize, (col) {
              return Expanded(
                child: _buildCell(row, col, previewCells, isPreviewValid),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildCell(int row, int col,
      List<List<int>>? previewCells, bool isPreviewValid) {
    CellState cellState = gameState.board[row][col];
    bool isForcedCell = gameState.forcedCell != null &&
        gameState.forcedCell!.row == row &&
        gameState.forcedCell!.col == col;
    bool isSelectingForced = gameState.phase == GamePhase.selectingForcedCell;

    // 미리보기에 포함되는 셀인지
    bool isPreview = false;
    if (previewCells != null) {
      isPreview = previewCells.any((c) => c[0] == row && c[1] == col);
    }

    Color bgColor;
    Widget? child;
    BoxBorder? border;

    if (cellState == CellState.player1) {
      bgColor = player1Color;
    } else if (cellState == CellState.player2) {
      bgColor = player2Color;
    } else if (isForcedCell) {
      bgColor = forcedCellLight;
      border = Border.all(color: forcedCellColor, width: 2.5);
      child = const Icon(Icons.star, color: Color(0xFF9B59B6), size: 20);
    } else if (isSelectingForced && cellState == CellState.empty) {
      // 강제칸 선택 단계 — 선택 가능한 빈 칸 강조
      bgColor = const Color(0xFFFFF9C4);
      border = Border.all(color: const Color(0xFFFFD54F), width: 1.5);
    } else {
      bgColor = emptyColor;
    }

    // 미리보기 오버레이
    if (isPreview && cellState == CellState.empty) {
      if (isPreviewValid) {
        bgColor = gameState.currentPlayer == Player.player1
            ? player1Light
            : player2Light;
        border = Border.all(
          color: gameState.currentPlayer == Player.player1
              ? player1Color
              : player2Color,
          width: 2,
        );
      } else {
        bgColor = const Color(0xFFFFCDD2);
        border = Border.all(color: const Color(0xFFEF5350), width: 2);
      }
    }

    return Padding(
      padding: const EdgeInsets.all(1.5),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: border ?? Border.all(color: Colors.white, width: 1),
          boxShadow: cellState != CellState.empty
              ? [
                  BoxShadow(
                    color: (cellState == CellState.player1
                            ? player1Color
                            : player2Color)
                        .withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Center(child: child),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'models/cell_state.dart';
import 'models/game_state.dart';
import 'widgets/game_board.dart';
import 'widgets/control_panel.dart';

void main() {
  runApp(const ForceApp());
}

class ForceApp extends StatelessWidget {
  const ForceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FORCE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF4A90D9),
        fontFamily: 'Pretendard',
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final GameState _gameState = GameState();
  List<List<int>>? _previewCells;
  bool _isPreviewValid = false;

  late AnimationController _titleController;
  late Animation<double> _titleAnimation;

  @override
  void initState() {
    super.initState();
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _titleAnimation = CurvedAnimation(
      parent: _titleController,
      curve: Curves.easeOutBack,
    );
    _titleController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  int? _dragStartRow;
  int? _dragStartCol;
  int? _dragCurrRow;
  int? _dragCurrCol;

  void _onCellPanDown(int row, int col) {
    if (_gameState.phase == GamePhase.placingBlock) {
      setState(() {
        _dragStartRow = row;
        _dragStartCol = col;
        _dragCurrRow = row;
        _dragCurrCol = col;
        _updatePreviewFromDrag();
      });
    } else if (_gameState.phase == GamePhase.selectingForcedCell) {
      setState(() {
        bool success = _gameState.selectForcedCell(row, col);
        if (success && _gameState.phase == GamePhase.gameOver) {
          _showWinnerDialog();
        }
      });
      _clearErrorMessageLater();
    }
  }

  void _onCellPanUpdate(int row, int col) {
    if (_gameState.phase == GamePhase.placingBlock && _dragStartRow != null) {
      if (_dragCurrRow != row || _dragCurrCol != col) {
        setState(() {
          _dragCurrRow = row;
          _dragCurrCol = col;
          _updatePreviewFromDrag();
        });
      }
    }
  }

  void _onCellPanEnd() {
    if (_gameState.phase == GamePhase.placingBlock && _dragStartRow != null && _dragCurrRow != null) {
      _attemptPlacementFromDrag();
      setState(() {
        _dragStartRow = null;
        _dragStartCol = null;
        _dragCurrRow = null;
        _dragCurrCol = null;
        _previewCells = null;
        _isPreviewValid = false;
      });
      _clearErrorMessageLater();
    }
  }

  void _updatePreviewFromDrag() {
    int rowDiff = _dragCurrRow! - _dragStartRow!;
    int colDiff = _dragCurrCol! - _dragStartCol!;

    Direction dir;
    int size = 1;
    int startR = _dragStartRow!;
    int startC = _dragStartCol!;

    if (rowDiff.abs() >= colDiff.abs()) {
      dir = Direction.vertical;
      size = rowDiff.abs() + 1;
      if (rowDiff < 0) startR = _dragStartRow! + rowDiff;
    } else {
      dir = Direction.horizontal;
      size = colDiff.abs() + 1;
      if (colDiff < 0) startC = _dragStartCol! + colDiff;
    }

    if (size > 3) {
      size = 3;
      if (dir == Direction.vertical && rowDiff < 0) {
        startR = _dragStartRow! - 2;
      } else if (dir == Direction.horizontal && colDiff < 0) {
        startC = _dragStartCol! - 2;
      }
    }

    _gameState.selectedDirection = dir;
    _gameState.selectedBlockSize = size >= 3 ? BlockSize.three : BlockSize.two;

    List<List<int>> cells = [];
    for (int i = 0; i < size; i++) {
      int r = dir == Direction.vertical ? startR + i : startR;
      int c = dir == Direction.horizontal ? startC + i : startC;
      cells.add([r, c]);
    }
    
    _previewCells = cells;

    // Check validity
    if (size < 2) {
      // 1칸일 때는 빨간색 또는 단순 표시 (현재는 단순 빈칸 여부만 체크)
      _isPreviewValid = _gameState.board[startR][startC] == CellState.empty;
    } else {
      _isPreviewValid = _gameState.isValidPlacement(startR, startC, _gameState.selectedBlockSize, dir);
    }
  }

  void _attemptPlacementFromDrag() {
    if (_previewCells == null || _previewCells!.length < 2) {
      return; 
    }

    int startR = _previewCells!.first[0];
    int startC = _previewCells!.first[1];

    setState(() {
      bool success = _gameState.placeBlock(startR, startC);
      if (success && _gameState.phase == GamePhase.gameOver) {
        _showWinnerDialog();
      }
    });
  }

  void _clearErrorMessageLater() {
    if (_gameState.errorMessage != null) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _gameState.errorMessage = null;
          });
        }
      });
    }
  }

  void _showWinnerDialog() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final isP1 = _gameState.winner == Player.player1;
          final winnerColor =
              isP1 ? const Color(0xFF4A90D9) : const Color(0xFFE8853A);
          final winnerName = isP1 ? 'Player 1' : 'Player 2';

          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    winnerColor.withValues(alpha: 0.05),
                    winnerColor.withValues(alpha: 0.15),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: winnerColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.emoji_events_rounded,
                        color: winnerColor, size: 40),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '🎉 승리!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$winnerName가 승리했습니다!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: winnerColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '상대가 더 이상 블록을 놓을 수 없습니다.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {
                          _gameState.reset();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: winnerColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '다시 시작',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double boardMaxSize = constraints.maxWidth < 500
                ? constraints.maxWidth - 32
                : 420.0;

            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: boardMaxSize + 32),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    child: Column(
                      children: [
                        // 제목
                        ScaleTransition(
                          scale: _titleAnimation,
                          child: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFF4A90D9),
                                Color(0xFF9B59B6),
                                Color(0xFFE8853A),
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              'FORCE',
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 8,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          '상대를 봉쇄하라',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade400,
                            letterSpacing: 2,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 컨트롤 패널
                        ControlPanel(
                          currentPlayer: _gameState.currentPlayer,
                          selectedBlockSize: _gameState.selectedBlockSize,
                          selectedDirection: _gameState.selectedDirection,
                          phase: _gameState.phase,
                          forcedCell: _gameState.forcedCell,
                          errorMessage: _gameState.errorMessage,
                          onBlockSizeChanged: (size) {
                            setState(() {
                              _gameState.selectedBlockSize = size;
                            });
                          },
                          onDirectionChanged: (dir) {
                            setState(() {
                              _gameState.selectedDirection = dir;
                            });
                          },
                          onReset: () {
                            setState(() {
                              _gameState.reset();
                            });
                          },
                        ),

                        const SizedBox(height: 20),

                        // 게임 보드
                        SizedBox(
                          width: boardMaxSize,
                          child: GameBoard(
                            gameState: _gameState,
                            previewCells: _previewCells,
                            isPreviewValid: _isPreviewValid,
                            onCellPanDown: _onCellPanDown,
                            onCellPanUpdate: _onCellPanUpdate,
                            onCellPanEnd: _onCellPanEnd,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Reset 버튼
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _gameState.reset();
                              });
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('다시 시작'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade500,
                              side: BorderSide(color: Colors.grey.shade200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


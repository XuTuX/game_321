import 'package:flutter/material.dart';
import '../models/cell_state.dart';

/// 게임 컨트롤 패널 위젯 — 컴팩트한 한 줄 레이아웃
class ControlPanel extends StatelessWidget {
  final Player currentPlayer;
  final BlockSize selectedBlockSize;
  final Direction selectedDirection;
  final GamePhase phase;
  final ForcedCell? forcedCell;
  final String? errorMessage;
  final Function(BlockSize) onBlockSizeChanged;
  final Function(Direction) onDirectionChanged;
  final VoidCallback onReset;

  const ControlPanel({
    super.key,
    required this.currentPlayer,
    required this.selectedBlockSize,
    required this.selectedDirection,
    required this.phase,
    required this.forcedCell,
    required this.errorMessage,
    required this.onBlockSizeChanged,
    required this.onDirectionChanged,
    required this.onReset,
  });

  static const Color player1Color = Color(0xFF4A90D9);
  static const Color player2Color = Color(0xFFE8853A);
  static const Color forcedColor = Color(0xFF9B59B6);

  @override
  Widget build(BuildContext context) {
    Color playerColor =
        currentPlayer == Player.player1 ? player1Color : player2Color;
    String playerName =
        currentPlayer == Player.player1 ? 'Player 1' : 'Player 2';

    return Column(
      children: [
        // 상태 배너: 강제칸 선택 단계 or 강제칸 경고 or 일반 턴
        if (phase == GamePhase.selectingForcedCell)
          _buildBanner(
            icon: Icons.star_rounded,
            text: '강제칸을 지정하세요',
            color: forcedColor,
          )
        else if (forcedCell != null)
          _buildBanner(
            icon: Icons.warning_amber_rounded,
            text: '★ 강제칸을 포함해서 놓으세요',
            color: forcedColor,
          )
        else
          // 턴 표시
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: playerColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: playerColor.withValues(alpha: 0.25), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: playerColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: playerColor.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$playerName의 턴',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: playerColor,
                  ),
                ),
              ],
            ),
          ),

        // 블록 배치 안내 메시지
        if (phase == GamePhase.placingBlock) ...[
          const SizedBox(height: 14),
          Text(
            '보드를 드래그하여 블록(2칸 또는 3칸)을 배치하세요',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
        ],

        // 에러 메시지
        if (errorMessage != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              errorMessage!,
              style: const TextStyle(
                color: Color(0xFFD32F2F),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// 상태 배너 (강제칸 관련)
  Widget _buildBanner({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

}

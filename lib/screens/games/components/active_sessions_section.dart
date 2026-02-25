import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/modern_snackbar.dart';
import '../../../providers/game_provider.dart';
import '../dialogs/game_bill_dialog.dart';

class ActiveSessionsSection extends StatelessWidget {
  final String gameType;

  const ActiveSessionsSection({super.key, required this.gameType});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        final activeSessions = gameProvider.activeGameSessions;

        if (activeSessions.isEmpty) {
          return const _EmptySessions();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Sessions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray800,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.space2,
                    vertical: AppTokens.space1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                  ),
                  child: Text(
                    '${activeSessions.length} Active',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.info,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space3),

            // Sessions List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeSessions.length,
              itemBuilder: (context, index) {
                final session = activeSessions[index];
                return _SessionCard(
                  session: session,
                  gameType: gameType,
                  onStop: () => _stopSession(context, session.id),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _stopSession(BuildContext context, String sessionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Session?'),
        content: const Text('Are you sure you want to end this session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context.read<GameProvider>().stopSession(
                gameType: gameType,
                sessionId: sessionId,
              );

              if (context.mounted) {
                if (success) {
                  ModernSnackBar.success(context, 'Session ended');
                } else {
                  ModernSnackBar.error(context, 'Failed to end session');
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('End'),
          ),
        ],
      ),
    );
  }
}

// ==================== SESSION CARD ====================

class _SessionCard extends StatefulWidget {
  final dynamic session;
  final String gameType;
  final VoidCallback onStop;

  const _SessionCard({
    required this.session,
    required this.gameType,
    required this.onStop,
  });

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  late int _gameCount;

  @override
  void initState() {
    super.initState();
    _gameCount = 0;
  }

  @override
  Widget build(BuildContext context) {
    final startTime = widget.session.startTime as DateTime;
    final now = DateTime.now();
    final duration = now.difference(startTime);
    final minutes = duration.inMinutes;
    final isSnooker = widget.gameType == 'snooker-pool';

    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.space3),
      padding: const EdgeInsets.all(AppTokens.space3),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.05),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table and Customer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Table ${widget.session.tableNumber}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray800,
                    ),
                  ),
                  const SizedBox(height: AppTokens.space1),
                  Text(
                    widget.session.customerName,
                    style: TextStyle(fontSize: 12, color: AppColors.gray600),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space2,
                  vertical: AppTokens.space1,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                ),
                child: Text(
                  isSnooker ? '$_gameCount Games' : '${minutes}m',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),

          // Notes (if available)
          if (widget.session.notes != null &&
              widget.session.notes!.isNotEmpty) ...[
            const SizedBox(height: AppTokens.space2),
            Text(
              widget.session.notes!,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.gray600,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Games Info (for snooker)
          if (isSnooker) ...[
            const SizedBox(height: AppTokens.space3),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Games Played',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.gray600,
                        ),
                      ),
                      const SizedBox(height: AppTokens.space1),
                      Text(
                        _gameCount.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gray800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTokens.space3),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _gameCount++);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTokens.space2,
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Game'),
                  ),
                ),
              ],
            ),
          ],

          // Action Buttons
          const SizedBox(height: AppTokens.space3),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onStop,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTokens.space2,
                    ),
                  ),
                  child: const Text(
                    'End Session',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.space2),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showBillDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTokens.space2,
                    ),
                  ),
                  child: const Text(
                    'Bill',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBillDialog(BuildContext context) {
    final gameProvider = context.read<GameProvider>();
    final gameConfig = gameProvider.getGameConfigByType(widget.gameType);

    if (gameConfig == null) {
      ModernSnackBar.error(context, 'Game config not found');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => GameBillDialog(
        gameType: widget.gameType,
        session: widget.session,
        pricePerUnit: gameConfig.pricePerUnit,
        gameCount: widget.gameType == 'snooker-pool' ? _gameCount : null,
      ),
    );
  }
}

// ==================== EMPTY SESSIONS ====================

class _EmptySessions extends StatelessWidget {
  const _EmptySessions();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.space4),
      decoration: BoxDecoration(
        color: AppColors.gray200.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.hourglass_empty_rounded,
              size: 32,
              color: AppColors.gray500,
            ),
            const SizedBox(height: AppTokens.space2),
            Text(
              'No Active Sessions',
              style: TextStyle(
                color: AppColors.gray600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

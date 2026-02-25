import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/modern_snackbar.dart';
import '../../../providers/game_provider.dart';
import '../../../services/auth_service.dart';
import '../dialogs/start_session_dialog.dart';

class GameTableSection extends StatelessWidget {
  final String gameType;
  final bool isDemoMode;

  const GameTableSection({
    super.key,
    required this.gameType,
    this.isDemoMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        // Loading state
        if (gameProvider.isLoadingTables) {
          return _LoadingTables();
        }

        // Error state
        if (gameProvider.tablesError != null) {
          return _ErrorTables(
            message: gameProvider.tablesError!,
            onRetry: () => gameProvider.loadTablesForGame(gameType),
          );
        }

        final tables = gameProvider.tablesByGame[gameType] ?? [];

        if (tables.isEmpty) {
          return _EmptyTables();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available Tables',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray800,
                  ),
                ),
                Text(
                  '${tables.where((t) => !t.isOccupied).length}/${tables.length} Free',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space4),

            // Tables Grid
            GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: AppTokens.space3,
                mainAxisSpacing: AppTokens.space3,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tables.length,
              itemBuilder: (context, index) {
                final table = tables[index];
                return _TableCard(
                  gameType: gameType,
                  tableNumber: table.tableNumber,
                  isOccupied: table.isOccupied,
                  onTap: table.isOccupied
                      ? null
                      : () =>
                            _showStartSessionDialog(context, table.tableNumber),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showStartSessionDialog(BuildContext context, int tableNumber) {
    showDialog(
      context: context,
      builder: (context) =>
          StartSessionDialog(gameType: gameType, tableNumber: tableNumber),
    );
  }
}

// ==================== TABLE CARD ====================

class _TableCard extends StatelessWidget {
  final String gameType;
  final int tableNumber;
  final bool isOccupied;
  final VoidCallback? onTap;

  const _TableCard({
    required this.gameType,
    required this.tableNumber,
    required this.isOccupied,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isOccupied
              ? AppColors.error.withOpacity(0.1)
              : AppColors.success.withOpacity(0.1),
          border: Border.all(
            color: isOccupied ? AppColors.error : AppColors.success,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'TBL ${tableNumber.toString()}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.gray800,
              ),
            ),
            const SizedBox(height: AppTokens.space3),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.space3,
                vertical: AppTokens.space1,
              ),
              decoration: BoxDecoration(
                color: isOccupied ? AppColors.error : AppColors.success,
                borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
              ),
              child: Text(
                isOccupied ? 'Occupied' : 'Free',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSuccess,
                ),
              ),
            ),
            if (!isOccupied) ...[
              const SizedBox(height: AppTokens.space3),
              Icon(Icons.add_rounded, size: 20, color: AppColors.success),
            ],
          ],
        ),
      ),
    );
  }
}

// ==================== LOADING TABLES ====================

class _LoadingTables extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Tables',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.gray800,
          ),
        ),
        const SizedBox(height: AppTokens.space4),
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: AppTokens.space3,
            mainAxisSpacing: AppTokens.space3,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.gray200,
                borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ==================== ERROR TABLES ====================

class _ErrorTables extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorTables({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.space4),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        border: Border.all(color: AppColors.error),
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline_rounded, color: AppColors.error),
              const SizedBox(width: AppTokens.space2),
              Expanded(
                child: Text(
                  'Error Loading Tables',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space2),
          Text(
            message,
            style: TextStyle(color: AppColors.gray700, fontSize: 13),
          ),
          const SizedBox(height: AppTokens.space3),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ==================== EMPTY TABLES ====================

class _EmptyTables extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.table_chart_outlined, size: 32, color: AppColors.gray500),
          const SizedBox(height: AppTokens.space2),
          Text(
            'No Tables Available',
            style: TextStyle(color: AppColors.gray600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

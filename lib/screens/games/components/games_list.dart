import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/game_config.dart';

class GamesList extends StatelessWidget {
  final List<GameConfig> games;
  final String? selectedGameType;
  final Function(String) onSelectGame;

  const GamesList({
    super.key,
    required this.games,
    required this.selectedGameType,
    required this.onSelectGame,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: games.length,
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          final game = games[index];
          final isSelected = game.gameType == selectedGameType;

          return Padding(
            padding: EdgeInsets.only(
              right: index == games.length - 1 ? 0 : AppTokens.space3,
            ),
            child: _GameCard(
              game: game,
              isSelected: isSelected,
              onTap: () => onSelectGame(game.gameType),
            ),
          );
        },
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final GameConfig game;
  final bool isSelected;
  final VoidCallback onTap;

  const _GameCard({
    required this.game,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outline,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              game.gameType == 'table-tennis'
                  ? Icons.sports_tennis_rounded
                  : Icons.casino_rounded,
              size: 32,
              color: isSelected ? AppColors.onPrimary : AppColors.gray700,
            ),
            const SizedBox(height: AppTokens.space2),
            Text(
              game.displayName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.onPrimary : AppColors.gray800,
              ),
            ),
            const SizedBox(height: AppTokens.space1),
            Text(
              '${game.numberOfTables} Tables',
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppColors.onPrimary : AppColors.gray600,
              ),
            ),
            const SizedBox(height: AppTokens.space1),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.space2,
                vertical: AppTokens.space1,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.onPrimary.withOpacity(0.2)
                    : AppColors.gray300,
                borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
              ),
              child: Text(
                game.gameType == 'table-tennis'
                    ? 'Rs. ${game.pricePerUnit.toStringAsFixed(0)}/min'
                    : 'Rs. ${game.pricePerUnit.toStringAsFixed(0)}/game',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.onPrimary : AppColors.gray800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/modern_snackbar.dart';
import '../providers/game_provider.dart';
import '../services/auth_service.dart';
import 'games/components/games_list.dart';
import 'games/components/game_tables_section.dart';
import 'games/components/active_sessions_section.dart';
import 'games/dialogs/start_session_dialog.dart';
import 'games/games_bills_screen.dart';

class GamesTab extends StatefulWidget {
  const GamesTab({super.key});

  @override
  State<GamesTab> createState() => _GamesTabState();
}

class _GamesTabState extends State<GamesTab> {
  @override
  void initState() {
    super.initState();
    _loadGameData();
  }

  void _loadGameData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().loadGameConfigs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray100,
      appBar: AppBar(
        title: const Text('Games'),
        centerTitle: false,
        actions: [
          // Bills button
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GamesBillsScreen(),
                ),
              );
            },
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              context.read<GameProvider>().refreshAllGames();
              ModernSnackBar.show(
                context: context,
                message: 'Refreshing...',
                icon: Icons.refresh_rounded,
                backgroundColor: AppColors.info,
                foregroundColor: AppColors.onInfo,
              );
            },
          ),
        ],
      ),
      body: Consumer<GameProvider>(
        builder: (context, gameProvider, _) {
          // Loading state
          if (gameProvider.isLoadingConfigs) {
            return const _LoadingState();
          }

          // Error state
          if (gameProvider.configError != null) {
            return _ErrorState(
              message: gameProvider.configError!,
              onRetry: _loadGameData,
            );
          }

          // Empty state
          if (gameProvider.gameConfigs.isEmpty) {
            return const _EmptyState();
          }

          return CustomScrollView(
            slivers: [
              // Games List Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppTokens.space4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select a Game',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray800,
                        ),
                      ),
                      const SizedBox(height: AppTokens.space3),
                      GamesList(
                        games: gameProvider.gameConfigs,
                        selectedGameType: gameProvider.selectedGameType,
                        onSelectGame: (gameType) async {
                          await gameProvider.selectGame(gameType);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Game Tables Section
              if (gameProvider.selectedGameType != null) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTokens.space4),
                    child: GameTableSection(
                      gameType: gameProvider.selectedGameType!,
                      isDemoMode: false,
                    ),
                  ),
                ),
              ],

              // Active Sessions Section
              if (gameProvider.selectedGameType != null) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTokens.space4),
                    child: ActiveSessionsSection(
                      gameType: gameProvider.selectedGameType!,
                    ),
                  ),
                ),
              ],

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: AppTokens.space5),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ==================== LOADING STATE ====================

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppTokens.space4),
          Text(
            'Loading games...',
            style: TextStyle(color: AppColors.gray600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ==================== ERROR STATE ====================

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
          const SizedBox(height: AppTokens.space4),
          Text(
            'Error Loading Games',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: AppTokens.space2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.gray600, fontSize: 14),
            ),
          ),
          const SizedBox(height: AppTokens.space4),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// ==================== EMPTY STATE ====================

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_volleyball_outlined,
            size: 48,
            color: AppColors.gray500,
          ),
          const SizedBox(height: AppTokens.space4),
          Text(
            'No Games Available',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: AppTokens.space2),
          Text(
            'Check back later',
            style: TextStyle(color: AppColors.gray600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

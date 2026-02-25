import 'package:flutter/foundation.dart';
import '../models/game_config.dart';
import '../models/game_table.dart';
import '../models/game_session.dart';
import '../services/game_service.dart';

class GameProvider with ChangeNotifier {
  // Game Configs
  List<GameConfig> _gameConfigs = [];
  bool _isLoadingConfigs = false;
  String? _configError;

  // Tables
  Map<String, List<GameTable>> _tablesByGame = {};
  bool _isLoadingTables = false;
  String? _tablesError;

  // Sessions
  Map<String, List<GameSession>> _sessionsByGame = {};
  bool _isLoadingSessions = false;
  String? _sessionsError;

  // Selected game
  String? _selectedGameType;

  // Getters for Game Configs
  List<GameConfig> get gameConfigs => _gameConfigs;
  bool get isLoadingConfigs => _isLoadingConfigs;
  String? get configError => _configError;

  // Getters for Tables
  Map<String, List<GameTable>> get tablesByGame => _tablesByGame;
  bool get isLoadingTables => _isLoadingTables;
  String? get tablesError => _tablesError;

  // Getters for Sessions
  Map<String, List<GameSession>> get sessionsByGame => _sessionsByGame;
  bool get isLoadingSessions => _isLoadingSessions;
  String? get sessionsError => _sessionsError;

  // Getters for Selected Game
  String? get selectedGameType => _selectedGameType;

  // Get tables for selected game
  List<GameTable> get selectedGameTables {
    if (_selectedGameType == null) return [];
    return _tablesByGame[_selectedGameType] ?? [];
  }

  // Get sessions for selected game
  List<GameSession> get selectedGameSessions {
    if (_selectedGameType == null) return [];
    return _sessionsByGame[_selectedGameType] ?? [];
  }

  // Get active sessions for selected game
  List<GameSession> get activeGameSessions {
    return selectedGameSessions.where((s) => s.isActive).toList();
  }

  // Get game config by type
  GameConfig? getGameConfigByType(String? gameType) {
    if (gameType == null) return null;
    try {
      return _gameConfigs.firstWhere((config) => config.gameType == gameType);
    } catch (e) {
      return null;
    }
  }

  // ==================== LOAD GAME CONFIGS ====================

  /// Load all game configurations
  Future<void> loadGameConfigs() async {
    _isLoadingConfigs = true;
    _configError = null;
    notifyListeners();

    try {
      _gameConfigs = await GameService.getAllGameConfigs();
      _isLoadingConfigs = false;
      notifyListeners();

      // If no game is selected, select the first one
      if (_selectedGameType == null && _gameConfigs.isNotEmpty) {
        selectGame(_gameConfigs[0].gameType);
      }
    } catch (e) {
      _isLoadingConfigs = false;
      _configError = e.toString();
      notifyListeners();
    }
  }

  // ==================== SELECT GAME ====================

  /// Select a game type and load its tables
  Future<void> selectGame(String gameType) async {
    _selectedGameType = gameType;
    notifyListeners();

    // Load tables for selected game if not already loaded
    if (!_tablesByGame.containsKey(gameType)) {
      await loadTablesForGame(gameType);
    }

    // Load sessions for selected game if not already loaded
    if (!_sessionsByGame.containsKey(gameType)) {
      await loadSessionsForGame(gameType);
    }
  }

  // ==================== LOAD TABLES ====================

  /// Load tables for a specific game type
  Future<void> loadTablesForGame(String gameType) async {
    _isLoadingTables = true;
    _tablesError = null;
    notifyListeners();

    try {
      List<GameTable> tables;

      if (gameType == 'table-tennis') {
        tables = await GameService.getTennisTableStatuses();
      } else if (gameType == 'snooker-pool') {
        tables = await GameService.getSnookerTableStatuses();
      } else {
        throw Exception('Unknown game type: $gameType');
      }

      _tablesByGame[gameType] = tables;
      _isLoadingTables = false;
      notifyListeners();
    } catch (e) {
      _isLoadingTables = false;
      _tablesError = e.toString();
      notifyListeners();
    }
  }

  // ==================== LOAD SESSIONS ====================

  /// Load sessions for a specific game type
  Future<void> loadSessionsForGame(
    String gameType, {
    int page = 1,
    int limit = 10,
  }) async {
    _isLoadingSessions = true;
    _sessionsError = null;
    notifyListeners();

    try {
      if (gameType == 'table-tennis') {
        final response = await GameService.getTennisSessions(
          page: page,
          limit: limit,
        );
        _sessionsByGame[gameType] = response.docs;
      } else if (gameType == 'snooker-pool') {
        final response = await GameService.getSnookerSessions(
          page: page,
          limit: limit,
        );
        _sessionsByGame[gameType] = response.docs;
      } else {
        throw Exception('Unknown game type: $gameType');
      }

      _isLoadingSessions = false;
      notifyListeners();
    } catch (e) {
      _isLoadingSessions = false;
      _sessionsError = e.toString();
      notifyListeners();
    }
  }

  // ==================== START SESSION ====================

  /// Start a new session
  Future<GameSession?> startSession({
    required String gameType,
    required int tableNumber,
    required String customerName,
    required String createdBy,
    String? notes,
  }) async {
    try {
      GameSession session;

      if (gameType == 'table-tennis') {
        session = await GameService.startTennisSession(
          tableNumber: tableNumber,
          customerName: customerName,
          createdBy: createdBy,
          notes: notes,
        );
      } else if (gameType == 'snooker-pool') {
        session = await GameService.startSnookerSession(
          tableNumber: tableNumber,
          customerName: customerName,
          createdBy: createdBy,
          notes: notes,
        );
      } else {
        throw Exception('Unknown game type: $gameType');
      }

      // Add session to the list
      if (!_sessionsByGame.containsKey(gameType)) {
        _sessionsByGame[gameType] = [];
      }
      _sessionsByGame[gameType]!.insert(0, session);

      // Update table status
      if (_tablesByGame.containsKey(gameType)) {
        final tables = _tablesByGame[gameType]!;
        final tableIndex = tables.indexWhere(
          (t) => t.tableNumber == tableNumber,
        );
        if (tableIndex != -1) {
          _tablesByGame[gameType]![tableIndex] = tables[tableIndex].copyWith(
            isOccupied: true,
          );
        }
      }

      notifyListeners();
      return session;
    } catch (e) {
      _sessionsError = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ==================== STOP SESSION ====================

  /// Stop an active session
  Future<bool> stopSession({
    required String gameType,
    required String sessionId,
  }) async {
    try {
      if (gameType == 'table-tennis') {
        await GameService.stopTennisSession(sessionId);
      } else if (gameType == 'snooker-pool') {
        await GameService.stopSnookerSession(sessionId);
      } else {
        throw Exception('Unknown game type: $gameType');
      }

      // Find and remove the session or update its status
      if (_sessionsByGame.containsKey(gameType)) {
        final sessionIndex = _sessionsByGame[gameType]!.indexWhere(
          (s) => s.id == sessionId,
        );
        if (sessionIndex != -1) {
          final session = _sessionsByGame[gameType]![sessionIndex];
          _sessionsByGame[gameType]![sessionIndex] = session.copyWith(
            status: 'completed',
          );
        }
      }

      // Reload tables to update status
      await loadTablesForGame(gameType);
      notifyListeners();
      return true;
    } catch (e) {
      _sessionsError = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ==================== CLEAR ERRORS ====================

  /// Clear all errors
  void clearErrors() {
    _configError = null;
    _tablesError = null;
    _sessionsError = null;
    notifyListeners();
  }

  /// Clear config error
  void clearConfigError() {
    _configError = null;
    notifyListeners();
  }

  /// Clear tables error
  void clearTablesError() {
    _tablesError = null;
    notifyListeners();
  }

  /// Clear sessions error
  void clearSessionsError() {
    _sessionsError = null;
    notifyListeners();
  }

  // ==================== REFRESH ====================

  /// Refresh all data for a game
  Future<void> refreshGame(String gameType) async {
    await Future.wait([
      loadTablesForGame(gameType),
      loadSessionsForGame(gameType),
    ]);
  }

  /// Refresh all games data
  Future<void> refreshAllGames() async {
    await loadGameConfigs();
    for (final gameType in _gameConfigs.map((g) => g.gameType)) {
      await refreshGame(gameType);
    }
  }
}

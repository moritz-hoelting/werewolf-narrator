import 'dart:async' show unawaited;

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:werewolf_narrator/database/database.dart'
    show AppDatabase, AppDatabaseHolder;
import 'package:werewolf_narrator/game/game_command.dart' show GameCommand;
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/misc/phases/sheriff.dart'
    show SheriffElectionScreen;
import 'package:werewolf_narrator/game/misc/phases/voting.dart'
    show VillageVoteScreen;
import 'package:werewolf_narrator/game/model/death_information.dart'
    show DeathInformation, DeathReason;
import 'package:werewolf_narrator/game/model/player.dart' show PlayerView;
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/model/team.dart' show TeamType;
import 'package:werewolf_narrator/game/model/win_condition.dart'
    show WinCondition;
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/team/team.dart' show Team;
import 'package:werewolf_narrator/game/util/dynamic_actions.dart'
    show DynamicActionEntry;
import 'package:werewolf_narrator/game/util/hooks.dart';
import 'package:werewolf_narrator/views/game/check_roles_screen.dart'
    show CheckRolesData;

class GameState extends ChangeNotifier {
  /// The unique identifier for this game, corresponding to the database ID.
  final int id;

  late final GameData _data;

  /// Chunked actions for undo functionality. Each inner list represents a batch of actions that should be undone together.
  final List<IList<_CommandStackEntry>> _batchedCommandStack = [];

  /// Current commands that have been applied but not yet finalized into a batch.
  final List<_CommandStackEntry> _currentCommandStack = [];

  /// Stack of batches that have been undone and can be redone.
  final List<IList<GameCommand>> _redoCommandStack = [];

  /// Frames for the currently applied commands, used for handling nested command applications.
  final List<_AppliedCommandFrame> _frameStack = [];

  void _apply(GameCommand command) {
    final previousStack = _frameStack.lastOrNull;
    if (previousStack != null) {
      previousStack.add(command);
    }
    _frameStack.add(_AppliedCommandFrame());
    command.apply(_data);
    final currentStackEntry = _frameStack.removeLast();
    currentStackEntry.removeEmptyFrames();
    if (_frameStack.isEmpty) {
      _currentCommandStack.add(
        _CommandStackEntry(command: command, frame: currentStackEntry),
      );
    } else {
      _frameStack.last.addFrame(currentStackEntry);
    }
  }

  void apply(GameCommand command) {
    _apply(command);
    _redoCommandStack.clear();
    notifyListeners();
  }

  IList<_CommandStackEntry> _finishBatch([GameCommand? finalCommand]) {
    assert(
      _frameStack.isEmpty,
      'Finish batch cannot be called within a command application',
    );

    if (finalCommand != null) {
      _apply(finalCommand);
      _redoCommandStack.clear();
    }

    final commands = _currentCommandStack.toIList();
    _currentCommandStack.clear();
    _frameStack.clear();
    _batchedCommandStack.add(commands);

    return commands;
  }

  void finishBatch([GameCommand? finalCommand]) {
    final commandsInBatch = _finishBatch(finalCommand);

    notifyListeners();

    final db = AppDatabaseHolder().database;
    unawaited(
      db.computeWithDatabase(
        computation: (db) => db.gamesDao.insertCommandBatch(
          id,
          commandsInBatch.map((entry) => entry.command),
        ),
        connect: AppDatabase.open,
      ),
    );
  }

  void undoBatch() {
    final batchStackLength = _batchedCommandStack.length;
    for (final entry in _currentCommandStack.reversed) {
      entry.undo(_data);
    }
    if (_batchedCommandStack.isNotEmpty) {
      final lastBatch = _batchedCommandStack.removeLast();

      for (final batchEntry in lastBatch.reversed) {
        batchEntry.undo(_data);
      }
      _redoCommandStack.add(
        lastBatch
            .addAll(_currentCommandStack)
            .map((entry) => entry.command)
            .toIList(),
      );
    } else {
      _redoCommandStack.add(
        _currentCommandStack.map((entry) => entry.command).toIList(),
      );
    }
    _currentCommandStack.clear();
    notifyListeners();

    if (batchStackLength > 0) {
      final db = AppDatabaseHolder().database;
      unawaited(
        db.computeWithDatabase(
          computation: (db) =>
              db.gamesDao.setBatchUndoStatus(id, batchStackLength - 1, true),
          connect: AppDatabase.open,
        ),
      );
    }
  }

  void redoBatch() {
    final batchStackLength = _batchedCommandStack.length;
    final IList<GameCommand> redoCommands = _redoCommandStack.removeLast();
    for (final command in redoCommands) {
      _apply(command);
    }
    _finishBatch();

    notifyListeners();

    final db = AppDatabaseHolder().database;
    unawaited(
      db.computeWithDatabase(
        computation: (db) =>
            db.gamesDao.setBatchUndoStatus(id, batchStackLength, false),
        connect: AppDatabase.open,
      ),
    );
  }

  bool get canUndoBatch =>
      _currentCommandStack.every((entry) => entry.canBeUndone) &&
      (_batchedCommandStack.lastOrNull?.every((entry) => entry.canBeUndone) ??
          false);

  bool get canRedoBatch => _redoCommandStack.isNotEmpty;

  GameState({
    required this.id,
    required Iterable<String> playerNames,
    required IMap<RoleType, ({Map<String, dynamic> config, int count})>
    roleConfigurations,
  }) {
    _data = GameData(
      state: this,
      playerNames: playerNames,
      roleConfigurations: roleConfigurations.unlockLazy,
    );

    VillageVoteScreen.registerAction(this);
    SheriffElectionScreen.registerAction(this);
    for (final team in teams.values) {
      team.initialize(this);
    }
    for (final role in roleConfigurations.keys) {
      final roleInitializer = RoleManager.getInitializer(role);
      if (roleInitializer != null) {
        roleInitializer(this);
      }
    }

    _currentCommandStack.clear();
    _frameStack.clear();
  }

  static Future<GameState> fromDatabase({
    required int id,
    required IList<String> playerNames,
    required IMap<RoleType, ({Map<String, dynamic> config, int count})>
    roleConfigurations,
  }) async {
    final state = GameState(
      id: id,
      playerNames: playerNames,
      roleConfigurations: roleConfigurations,
    );

    final (:run, :undone) = await AppDatabaseHolder().database.gamesDao
        .getCommandBatchesForGame(id);

    for (final batch in run) {
      for (final command in batch) {
        state._apply(command);
      }
      state._finishBatch();
    }

    state._redoCommandStack.addAll(undone);

    return state;
  }

  int? get dynamicActionIndex => _data.dynamicActionIndex;

  CheckRolesData get checkRolesData => _data.checkRolesData;

  IMap<dynamic, dynamic> get customData => _data.customData.lock;

  /// The current day counter.
  int get dayCounter => _data.dayCounter;

  /// The current phase of the game.
  GamePhase get phase => _data.phase;

  /// Whether the game is currently in a night phase.
  bool get isNight => phase.isNight;

  /// The players in the game.
  IList<PlayerView> get players =>
      _data.players.map((p) => PlayerView(p)).toIList();

  /// The teams present in this game.
  IMap<TeamType, Team> get teams => _data.teams.lock;

  /// The counts of roles present in this game (initialized during setup).
  IMap<RoleType, ({int count, IMap<String, dynamic> config})>
  get roleConfigurations => _data.roleConfigurations
      .mapValue((value) => (config: value.config.lock, count: value.count))
      .toIMap();

  /// The total number of players in the game.
  int get playerCount => _data.playerCount;

  /// The number of alive players in the game.
  int get alivePlayerCount => _data.alivePlayerCount;

  /// Whether the game starts with a day phase (instead of night).
  bool get startGameWithDay => _data.startGameWithDay;

  /// Conditions under which the game is considered to be won.
  IList<WinCondition> get winConditions => _data.winConditions.lock;

  /// Hooks run at dawn.
  IList<DawnHook> get dawnHooks => _data.dawnHooks.lock;

  /// Hooks when a player is marked dead.
  ///
  /// Can prevent death by returning true.
  IList<DeathHook> get deathHooks => _data.deathHooks.lock;

  /// Hooks when a player is marked revived.
  ///
  /// Can prevent revival by returning true.
  IList<ReviveHook> get reviveHooks => _data.reviveHooks.lock;

  /// Hooks when a player is displayed.
  IList<PlayerDisplayHook> get playerDisplayHooks =>
      _data.playerDisplayHooks.lock;

  /// Hooks when a night action is displayed.
  ///
  /// Can prevent the action from being displayed for the given players by returning true.
  IList<ActionHook> get nightActionHooks => _data.nightActionHooks.lock;

  /// Hooks when a day action is displayed.
  ///
  /// Can prevent the action from being displayed for the given players by returning true.
  IList<ActionHook> get dayActionHooks => _data.dayActionHooks.lock;

  /// Hooks when a death action is displayed.
  ///
  /// Can prevent the action from being displayed for the given players by returning true.
  /// Will be called multiple times per death for determining whether to show the action. The answer must be consistent.
  IList<DeathActionHook> get deathActionHooks => _data.deathActionHooks.lock;

  /// Hooks for remaining roles at the end of role assignment.
  ///
  /// Called with the count of remaining roles for each role type.
  IMap<RoleType, IList<RemainingRoleHook>> get remainingRoleHooks =>
      _data.remainingRoleHooks.mapValue((value) => value.lock).toIMap();

  /// Hooks to determine if a player has won alongside the winning team.
  ///
  /// Returning true adds the player as a winner, false excludes them,
  /// and null has no effect.
  IList<PlayerWinHook> get playerWinHooks => _data.playerWinHooks.lock;

  /// Returns a map of player indices to their death reasons for the given cycle.
  IMap<int, DeathReason> deathsInCycle(int dayCounter, bool atNight) =>
      _data.deathsInCycle(dayCounter, atNight);

  /// Returns a map of player indices to their death reasons for the current cycle (day/night).
  IMap<int, DeathReason> get currentCycleDeaths => _data.currentCycleDeaths;

  /// Returns a map of player indices to their death reasons for the previous cycle (day/night).
  IMap<int, DeathReason> get previousCycleDeaths => _data.previousCycleDeaths;

  /// Returns a map of player indices to their unannounced death information.
  IMap<int, DeathInformation> get unannouncedDeaths => _data.unannouncedDeaths;

  /// Checks if the game has a specific role.
  bool hasRole(RoleType role) => _data.hasRole(role);

  /// Checks if the game has a specific role.
  bool hasRoleType<T extends Role>() => hasRole(RoleType.of<T>());

  /// Checks if the game has a specific role with at least one alive player.
  bool hasAliveRole(RoleType role) => _data.hasAliveRole(role);

  /// Checks if the game has a specific role with at least one alive player.
  bool hasAliveRoleType<T extends Role>() => hasAliveRole(RoleType.of<T>());

  /// Returns index and the player with a specific role, if any.
  ({int index, PlayerView player})? getPlayerOfRole(RoleType role) {
    final p = _data.getPlayerOfRole(role);
    if (p == null) return null;
    return (index: p.index, player: PlayerView(p.player));
  }

  /// Returns index and the player with a specific role, if any.
  ({int index, PlayerView player})? getPlayerOfRoleType<T extends Role>() =>
      getPlayerOfRole(RoleType.of<T>());

  /// Returns index and the alive player with a specific role, if any.
  ({int index, PlayerView player})? getAlivePlayerOfRole(RoleType role) {
    final p = _data.getAlivePlayerOfRole(role);
    if (p == null) return null;
    return (index: p.index, player: PlayerView(p.player));
  }

  /// Returns index and the alive player with a specific role, if any.
  ({int index, PlayerView player})?
  getAlivePlayerOfRoleType<T extends Role>() =>
      getAlivePlayerOfRole(RoleType.of<T>());

  /// Returns a list of indices and players with a specific role.
  IList<({int index, PlayerView player})> getPlayersOfRole(
    RoleType role,
  ) => _data
      .getPlayersOfRole(role)
      .where(
        (entry) =>
            entry.player.role != null && entry.player.role!.roleType == role,
      )
      .map((entry) => (index: entry.index, player: PlayerView(entry.player)))
      .toIList();

  /// Returns a list of indices and players with a specific role.
  IList<({int index, PlayerView player})>
  getPlayersOfRoleType<T extends Role>() => getPlayersOfRole(RoleType.of<T>());

  /// Returns a list of indices and alive players with a specific role.
  IList<({int index, PlayerView player})> getAlivePlayersOfRole(
    RoleType role,
  ) => _data
      .getAlivePlayersOfRole(role)
      .map(
        (element) => (index: element.index, player: PlayerView(element.player)),
      )
      .toIList();

  /// Returns a list of indices and alive players with a specific role.
  IList<({int index, PlayerView player})>
  getAlivePlayersOfRoleType<T extends Role>() =>
      getAlivePlayersOfRole(RoleType.of<T>());

  /// Checks if the game has a specific team.
  bool hasPlayerOfTeam(TeamType team) => _data.hasPlayerOfTeam(team);

  /// Checks if the game has a specific team.
  bool hasPlayerOfTeamType<T extends Team>() =>
      hasPlayerOfTeam(TeamType.of<T>());

  /// Checks if the game has an alive player of the specific team.
  bool hasAlivePlayerOfTeam(TeamType team) => _data.hasAlivePlayerOfTeam(team);

  /// Checks if the game has an alive player of the specific team.
  bool hasAlivePlayerOfTeamType<T extends Team>() =>
      hasAlivePlayerOfTeam(TeamType.of<T>());

  /// Returns a list of indices and players belonging to a specific team.
  IList<({int index, PlayerView player})> getPlayersOfTeam(TeamType team) =>
      _data
          .getPlayersOfTeam(team)
          .map(
            (element) =>
                (index: element.index, player: PlayerView(element.player)),
          )
          .toIList();

  /// Returns a list of indices and players belonging to a specific team.
  IList<({int index, PlayerView player})>
  getPlayersOfTeamType<T extends Team>() => getPlayersOfTeam(TeamType.of<T>());

  /// Returns a list of indices and alive players belonging to a specific team.
  IList<({int index, PlayerView player})> getAlivePlayersOfTeam(
    TeamType team,
  ) => _data
      .getAlivePlayersOfTeam(team)
      .map(
        (element) => (index: element.index, player: PlayerView(element.player)),
      )
      .toIList();

  /// Returns a list of indices and alive players belonging to a specific team.
  IList<({int index, PlayerView player})>
  getAlivePlayersOfTeamType<T extends Team>() =>
      getAlivePlayersOfTeam(TeamType.of<T>());

  /// Returns a list of unassigned roles in the game.
  IList<RoleType> get unassignedRoles => _data.unassignedRoles;

  /// Checks if a player is alive or killed in the current cycle.
  bool playerAliveOrKilledThisCycle(int playerIndex) =>
      _data.playerAliveOrKilledThisCycle(playerIndex);

  /// Checks if a player is alive or will remain alive until dawn.
  bool playerAliveUntilDawn(int playerIndex) =>
      _data.playerAliveUntilDawn(playerIndex);

  /// Player indices that are known to be dead based on the current game state (until dawn).
  ISet<int> get knownDeadPlayerIndices => _data.knownDeadPlayerIndices;

  /// Player indices that are known to be alive based on the current game state (until dawn).
  ISet<int> get knownAlivePlayerIndices => _data.knownDeadPlayerIndices;

  /// Player indices that are alive.
  ISet<int> get alivePlayerIndices => _data.alivePlayerIndices;

  /// Player indices that are dead.
  ISet<int> get deadPlayerIndices => _data.deadPlayerIndices;

  /// The index of the first player with pending death actions, or null if there are none.
  int? get firstPlayerWithPendingDeathAction =>
      _data.firstPlayerWithPendingDeathAction;

  /// Whether there are pending death announcements to be made.
  bool get pendingDeathAnnouncements => _data.pendingDeathAnnouncements;

  /// Whether there are pending death announcements to be made for deaths that occurred during the night.
  bool get pendingDeathAnnouncementsFromNight =>
      _data.pendingDeathAnnouncementsFromNight;

  (int, int) getAliveNeighbors(int playerIndex) =>
      _data.getAliveNeighbors(playerIndex);

  /// Checks if any team has met its win conditions.
  WinCondition? checkWinConditions() => _data.checkWinConditions();

  /// Returns the list of winning players if there is a winning team.
  ISet<({int index, PlayerView player})>? winningPlayers() => _data
      .winningPlayers()
      ?.map(
        (element) => (index: element.index, player: PlayerView(element.player)),
      )
      .toISet();

  IList<DynamicActionEntry> get nightActions =>
      _data.nightActionManager.orderedActions;

  IList<DynamicActionEntry> get dayActions =>
      _data.dayActionManager.orderedActions;
}

class _CommandStackEntry {
  const _CommandStackEntry({required this.command, required this.frame});

  final GameCommand command;
  final _AppliedCommandFrame frame;

  void undo(GameData gameData) {
    frame.undoAll(gameData);
    command.undo(gameData);
  }

  bool get canBeUndone => command.canBeUndone && frame.canUndoAll;

  @override
  String toString() => 'CommandStackEntry {command: $command, frame: $frame}';
}

class _AppliedCommandFrame {
  _AppliedCommandFrame();

  final List<Either<GameCommand, _AppliedCommandFrame>> entries = [];

  void add(GameCommand command) {
    entries.add(Left(command));
  }

  void addFrame(_AppliedCommandFrame frame) {
    entries.add(Right(frame));
  }

  void undoAll(GameData gameData) {
    for (final entry in entries.reversed) {
      entry.match(
        (cmd) => cmd.undo(gameData),
        (frame) => frame.undoAll(gameData),
      );
    }
  }

  void removeEmptyFrames() {
    for (final entry in entries) {
      entry.match((_) {}, (frame) => frame.removeEmptyFrames());
    }
    entries.removeWhere(
      (entry) => entry
          .getRight()
          .map((frame) => frame.entries.isEmpty)
          .getOrElse(() => false),
    );
  }

  bool get canUndoAll => entries.every(
    (entry) =>
        entry.match((cmd) => cmd.canBeUndone, (frame) => frame.canUndoAll),
  );

  @override
  String toString() => 'AppliedCommandFrame[${_toStringInner()}]';

  String _toStringInner() => entries.map(_toStringInnerEither).join(',\n');

  static String _toStringInnerEither(
    Either<GameCommand, _AppliedCommandFrame> entry,
  ) => entry.match((cmd) => cmd.toString(), (frame) => frame._toStringInner());
}

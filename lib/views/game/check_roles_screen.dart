import 'dart:math' show max;

import 'package:collection/collection.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' show Either;
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/game/commands/set_players_role.dart';
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart' show GameData, GamePhase;
import 'package:werewolf_narrator/game/model/role_config.dart'
    show RoleConfiguration;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/model/team.dart';
import 'package:werewolf_narrator/game/role/village/villager.dart'
    show VillagerRole;
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/widgets/game/app_bar.dart';
import 'package:werewolf_narrator/widgets/game/player_list.dart';

class CheckRolesScreen extends StatelessWidget {
  const CheckRolesScreen({super.key, required this.onPhaseComplete});

  final VoidCallback onPhaseComplete;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) => CheckRoleScreen(
        key: UniqueKey(),
        current: gameState
            .checkRolesData
            .checkOrder[gameState.checkRolesData.currentIndex],
        onComplete: onComplete(gameState),
        missingAssignments: gameState.checkRolesData.missingAssignments,
        assignedPlayersByTeam:
            gameState.checkRolesData.assignedPlayersByTeam.lock,
      ),
    );
  }

  void Function(int missing) onComplete(GameState gameState) => (missing) {
    if (gameState.checkRolesData.currentIndex >=
        gameState.checkRolesData.checkOrder.length - 1) {
      for (final entry
          in gameState.checkRolesData.assignedPlayersByTeam.entries) {
        final defaultRole =
            entry.key.information.checkTeamTogether?.defaultRole;
        if (defaultRole != null) {
          final noRolePlayers = entry.value
              .where((index) => gameState.players[index].role == null)
              .toISet();
          gameState.apply(SetPlayersRoleCommand(defaultRole, noRolePlayers));
        }
      }
      executeHooks(gameState);
      onPhaseComplete();
    } else {
      gameState.finishBatch(CheckNextRoleCommand(missing: missing));
    }
  };

  void executeHooks(GameState gameState) {
    final unassignedRoles = gameState.unassignedRoles.fold(<RoleType, int>{}, (
      acc,
      element,
    ) {
      acc[element] = (acc[element] ?? 0) + 1;
      return acc;
    });
    for (final roleType in unassignedRoles.entries) {
      gameState.remainingRoleHooks[roleType.key]?.forEach(
        (hook) => hook(gameState, roleType.value),
      );
    }
  }
}

class CheckRoleScreen extends StatefulWidget {
  final Either<(TeamType, TeamRoleCheckTogetherInformation), RoleType> current;
  final void Function(int missing) onComplete;
  final int missingAssignments;
  final IMap<TeamType, ISet<int>> assignedPlayersByTeam;

  const CheckRoleScreen({
    super.key,
    required this.current,
    required this.onComplete,
    required this.missingAssignments,
    required this.assignedPlayersByTeam,
  });

  @override
  State<CheckRoleScreen> createState() => _CheckRoleScreenState();
}

class _CheckRoleScreenState extends State<CheckRoleScreen> {
  late final List<bool> _selectedPlayers;

  int get selectedCount =>
      _selectedPlayers.where((isSelected) => isSelected).length;

  @override
  void initState() {
    super.initState();
    _selectedPlayers = List.filled(
      Provider.of<GameState>(context, listen: false).playerCount,
      false,
    );
  }

  int missingRoleCount(GameState gameState) => max(
    0,
    gameState.roleConfigurations.entries
            .map(
              (e) =>
                  (e.key.information.addedRoleCardAmount - 1) * e.value.count,
            )
            .sum -
        widget.missingAssignments,
  );

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        return widget.current.fold(
          (teamTuple) {
            final team = teamTuple.$1;
            final checkTogetherInformation = teamTuple.$2;

            final maxSelection = gameState.roleConfigurations.entries
                .where((entry) => entry.key.information.initialTeam == team)
                .map((entry) => entry.value.count)
                .sum;

            return _build(
              context: context,
              gameState: gameState,
              maxSelection: maxSelection,
              title: checkTogetherInformation.checkInstruction(
                context,
                maxSelection,
              ),
              onCompletePressed: () =>
                  onCompleteTeam(gameState, team, maxSelection),
            );
          },
          (role) {
            final maxSelection = gameState.roleConfigurations[role]?.count ?? 0;

            final teamConstraints = role.information.initialTeam != null
                ? widget.assignedPlayersByTeam[role.information.initialTeam!]
                : null;

            return _build(
              context: context,
              gameState: gameState,
              maxSelection: maxSelection,
              teamConstraints: teamConstraints,
              title: role.information.checkRoleInstruction(
                context,
                maxSelection,
              ),
              onCompletePressed: () => onCompleteRole(
                gameState,
                role,
                isTeamRole: teamConstraints != null,
              ),
            );
          },
        );
      },
    );
  }

  Widget _build({
    required BuildContext context,
    required GameState gameState,
    required int maxSelection,
    required String title,
    required VoidCallback onCompletePressed,
    ISet<int>? teamConstraints,
  }) {
    final localizations = AppLocalizations.of(context);
    final minSelection = maxSelection - missingRoleCount(gameState);
    final teamAssignedPlayers =
        widget.assignedPlayersByTeam.values.flattenedToList;

    return Scaffold(
      appBar: GameAppBar(title: Text(title)),
      body: teamConstraints != null && teamConstraints.isEmpty
          ? Center(
              child: Text(
                localizations.screen_checkRoles_noPlayersInTeam,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            )
          : PlayerList(
              phaseIdentifier: (GamePhase.checkRoles, widget.current),
              onPlayerTap: (index) => getOnTapPlayer(
                index: index,
                gameState: gameState,
                maxSelection: maxSelection,
                teamAssignedPlayers: teamAssignedPlayers.lock,
                teamConstraints: teamConstraints,
              ),
              selectedPlayers: _selectedPlayers
                  .mapIndexed((index, isSelected) => isSelected ? index : null)
                  .nonNulls
                  .toISet(),
              disabledPlayers: List.generate(gameState.playerCount, (i) => i)
                  .where(
                    (index) =>
                        gameState.players[index].role != null ||
                        (teamConstraints != null
                            ? !teamConstraints.contains(index)
                            : teamAssignedPlayers.contains(index)) ||
                        gameState.knownDeadPlayerIndices.contains(index),
                  )
                  .toISet(),
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(60),
          ),
          onPressed:
              (selectedCount >= minSelection &&
                      selectedCount <= maxSelection) ||
                  (teamConstraints != null && teamConstraints.isEmpty)
              ? onCompletePressed
              : null,
          label: Text(localizations.button_continueLabel),
          icon: const Icon(Icons.arrow_forward),
        ),
      ),
    );
  }

  VoidCallback? getOnTapPlayer({
    required int index,
    required GameState gameState,
    required int maxSelection,
    required IList<int> teamAssignedPlayers,
    ISet<int>? teamConstraints,
  }) {
    if (gameState.players[index].role != null ||
        (teamConstraints != null
            ? !teamConstraints.contains(index)
            : teamAssignedPlayers.contains(index))) {
      return null;
    }

    if (maxSelection == 1) {
      return () {
        final hasMissingRoles = missingRoleCount(gameState) > 0;

        setState(() {
          if (hasMissingRoles) {
            _clearAllExcept(index);
            _selectedPlayers[index] = !_selectedPlayers[index];
          } else {
            _clearAll();
            _selectedPlayers[index] = true;
          }
        });
      };
    }

    return (_selectedPlayers[index] ||
            (!_selectedPlayers[index] && selectedCount < maxSelection))
        ? () {
            setState(() {
              _selectedPlayers[index] = !_selectedPlayers[index];
            });
          }
        : null;
  }

  void _clearAll() {
    for (int i = 0; i < _selectedPlayers.length; i++) {
      _selectedPlayers[i] = false;
    }
  }

  void _clearAllExcept(int index) {
    for (int i = 0; i < _selectedPlayers.length; i++) {
      if (i != index) {
        _selectedPlayers[i] = false;
      }
    }
  }

  void onCompleteTeam(GameState gameState, TeamType team, int maxSelection) {
    final selectedIndices = _selectedPlayers.indexed
        .where((entry) => entry.$2)
        .map((entry) => entry.$1)
        .toList();
    gameState.apply(
      AssignPlayersByTeamCommand(
        team: team,
        playerIndices: selectedIndices.toISet(),
      ),
    );
    final missing = maxSelection - selectedIndices.length;

    widget.onComplete(max(0, missing));
  }

  void onCompleteRole(
    GameState gameState,
    RoleType role, {
    bool isTeamRole = false,
  }) {
    final selectedIndices = _selectedPlayers.indexed
        .where((entry) => entry.$2)
        .map((entry) => entry.$1)
        .toISet();
    gameState.apply(SetPlayersRoleCommand(role, selectedIndices));
    final missing =
        (gameState.roleConfigurations[role]?.count ?? 0) -
        selectedIndices.length;

    widget.onComplete(isTeamRole ? 0 : max(0, missing));
  }
}

class CheckRolesData {
  late final IList<
    Either<(TeamType, TeamRoleCheckTogetherInformation), RoleType>
  >
  checkOrder;
  final Map<TeamType, ISet<int>> assignedPlayersByTeam = {};
  int missingAssignments = 0;
  int currentIndex = 0;

  CheckRolesData(
    Map<RoleType, ({int count, RoleConfiguration config})> roleConfigurations,
  ) {
    final gameRoles = roleConfigurations.entries
        .where(
          (entry) => entry.value.count > 0 && entry.key != VillagerRole.type,
        )
        .map((entry) => entry.key)
        .toIList();
    final gameTeams = roleConfigurations.entries
        .where((entry) => entry.value.count > 0)
        .map((entry) => entry.key.information.initialTeam)
        .nonNulls
        .toISet();
    final teams = TeamManager.registeredTeams
        .where(
          (team) =>
              gameTeams.contains(team) &&
              team.information.checkTeamTogether != null &&
              gameRoles.contains(
                team.information.checkTeamTogether!.defaultRole,
              ),
        )
        .map(
          (team) =>
              Either<
                (TeamType, TeamRoleCheckTogetherInformation),
                RoleType
              >.left((team, team.information.checkTeamTogether!)),
        );
    final roles = RoleManager.categorizedRoles
        .expand((entry) => entry.roles)
        .where(
          (role) =>
              gameRoles.contains(role) &&
              !gameTeams.any(
                (team) =>
                    team.information.checkTeamTogether?.defaultRole == role,
              ),
        )
        .map(
          (role) =>
              Either<
                (TeamType, TeamRoleCheckTogetherInformation),
                RoleType
              >.right(role),
        );
    checkOrder = IList(teams.followedBy(roles));
    assert(checkOrder.isNotEmpty, 'There should be at least one role to check');
  }
}

class CheckNextRoleCommand implements GameCommand {
  final int missing;

  const CheckNextRoleCommand({required this.missing});

  @override
  void apply(GameData gameData) {
    gameData.checkRolesData.currentIndex++;
    gameData.checkRolesData.missingAssignments += missing;
  }

  @override
  bool get canBeUndone => true;

  @override
  void undo(GameData gameData) {
    gameData.checkRolesData.currentIndex--;
    gameData.checkRolesData.missingAssignments -= missing;
  }
}

class AssignPlayersByTeamCommand implements GameCommand {
  final TeamType team;
  final ISet<int> playerIndices;

  const AssignPlayersByTeamCommand({
    required this.team,
    required this.playerIndices,
  });

  @override
  void apply(GameData gameData) {
    gameData.checkRolesData.assignedPlayersByTeam[team] = playerIndices;
  }

  @override
  bool get canBeUndone => true;

  @override
  void undo(GameData gameData) {
    gameData.checkRolesData.assignedPlayersByTeam.remove(team);
  }
}

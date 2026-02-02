import 'dart:math' show max;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/model/role.dart';
import 'package:werewolf_narrator/role/villager.dart' show VillagerRole;
import 'package:werewolf_narrator/state/game.dart';
import 'package:werewolf_narrator/state/game_phase.dart';
import 'package:werewolf_narrator/state/hooks.dart';

class CheckRolesScreen extends StatefulWidget {
  const CheckRolesScreen({super.key, required this.onPhaseComplete});

  final VoidCallback onPhaseComplete;

  @override
  State<CheckRolesScreen> createState() => _CheckRolesScreenState();
}

class _CheckRolesScreenState extends State<CheckRolesScreen> {
  late final QueueList<RoleType> _remainingRoles;
  int _missingAssignments = 0;

  @override
  void initState() {
    super.initState();
    final gameRoles = Provider.of<GameState>(context, listen: false)
        .roleCounts
        .entries
        .where((entry) => entry.value > 0 && entry.key != VillagerRole.type)
        .map((entry) => entry.key)
        .toList();
    _remainingRoles = QueueList.from(
      RoleManager.registeredRoles.where((role) => gameRoles.contains(role)),
    );
    assert(
      _remainingRoles.isNotEmpty,
      'There should be at least one role to check',
    );
  }

  @override
  Widget build(BuildContext context) {
    return CheckRoleScreen(
      key: UniqueKey(),
      role: _remainingRoles[0],
      onComplete: onComplete,
      missingAssignments: _missingAssignments,
    );
  }

  void onComplete(int missing) {
    if (_remainingRoles.length == 1) {
      executeHooks();
      widget.onPhaseComplete();
    } else {
      setState(() {
        _remainingRoles.removeFirst();
        _missingAssignments += missing;
      });
    }
  }

  void executeHooks() {
    final gameState = Provider.of<GameState>(context, listen: false);
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
  final RoleType role;
  final void Function(int missing) onComplete;
  final int missingAssignments;

  const CheckRoleScreen({
    super.key,
    required this.role,
    required this.onComplete,
    required this.missingAssignments,
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

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        final localizations = AppLocalizations.of(context);

        final maxSelection = gameState.roleCounts[widget.role] ?? 0;
        final minSelection =
            maxSelection -
            max(
              0,
              gameState.roleCounts.entries
                      .map(
                        (e) =>
                            (e.key.instance.addedRoleCardAmount - 1) * e.value,
                      )
                      .sum -
                  widget.missingAssignments,
            );

        final playerDisplayHooks = gameState.playerDisplayHooks;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.role.instance.checkRoleInstruction(
                context,
                gameState.roleCounts[widget.role] ?? 0,
              ),
            ),
            automaticallyImplyLeading: false,
          ),
          body: ListView.builder(
            itemCount: gameState.playerCount,
            itemBuilder: (context, index) {
              final playerDisplayData = PlayerDisplayData.merge(
                playerDisplayHooks
                    .map(
                      (hook) => hook(gameState, (
                        GamePhase.checkRoles,
                        widget.role,
                      ), index),
                    )
                    .nonNulls,
              );

              return ListTile(
                title: Text(gameState.players[index].name),
                subtitle: playerDisplayData.subtitle != null
                    ? playerDisplayData.subtitle!(context)
                    : null,
                trailing: playerDisplayData.trailing != null
                    ? playerDisplayData.trailing!(context)
                    : null,
                onTap: getOnTapPlayer(index, gameState),
                selected: _selectedPlayers[index],
                enabled:
                    gameState.players[index].role == null &&
                    !playerDisplayData.disabled,
                selectedTileColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.2),
              );
            },
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
              ),
              onPressed:
                  selectedCount >= minSelection && selectedCount <= maxSelection
                  ? () => onComplete(gameState)
                  : null,
              label: Text(localizations.button_continueLabel),
              icon: const Icon(Icons.arrow_forward),
            ),
          ),
        );
      },
    );
  }

  VoidCallback? getOnTapPlayer(int index, GameState gameState) {
    if (gameState.players[index].role != null) {
      return null;
    }

    if ((gameState.roleCounts[widget.role] ?? 0) == 1) {
      return () {
        final hasMissingRoles =
            (gameState.roleCounts.entries
                    .map(
                      (e) => (e.key.instance.addedRoleCardAmount - 1) * e.value,
                    )
                    .sum -
                widget.missingAssignments) >
            0;
        setState(() {
          if (hasMissingRoles) {
            for (int i = 0; i < _selectedPlayers.length; i++) {
              if (i != index) {
                _selectedPlayers[i] = false;
              }
            }
            _selectedPlayers[index] = !_selectedPlayers[index];
          } else {
            for (int i = 0; i < _selectedPlayers.length; i++) {
              _selectedPlayers[i] = false;
            }
            _selectedPlayers[index] = true;
          }
        });
      };
    }

    return (_selectedPlayers[index] ||
            (!_selectedPlayers[index] &&
                selectedCount < (gameState.roleCounts[widget.role] ?? 0)))
        ? () {
            setState(() {
              _selectedPlayers[index] = !_selectedPlayers[index];
            });
          }
        : null;
  }

  void onComplete(GameState gameState) {
    final selectedIndices = _selectedPlayers.indexed
        .where((entry) => entry.$2)
        .map((entry) => entry.$1)
        .toList();
    gameState.setPlayersRole(widget.role, selectedIndices);
    final missing =
        (gameState.roleCounts[widget.role] ?? 0) - selectedIndices.length;

    widget.onComplete(max(0, missing));
  }
}

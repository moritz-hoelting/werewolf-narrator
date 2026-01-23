import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/model/roles.dart';
import 'package:werewolf_narrator/role/role.dart';
import 'package:werewolf_narrator/state/game.dart';

class CheckRolesScreen extends StatefulWidget {
  const CheckRolesScreen({super.key, required this.onPhaseComplete});

  final VoidCallback onPhaseComplete;

  @override
  State<CheckRolesScreen> createState() => _CheckRolesScreenState();
}

class _CheckRolesScreenState extends State<CheckRolesScreen> {
  late final List<RoleType> _remainingRoles;

  @override
  void initState() {
    super.initState();
    final gameRoles = Provider.of<GameState>(context, listen: false)
        .roles
        .entries
        .where((entry) => entry.value > 0 && entry.key != VillagerRole.type)
        .map((entry) => entry.key)
        .toList();
    _remainingRoles = RoleManager.registeredRoles
        .where((role) => gameRoles.contains(role))
        .toList();
    assert(
      _remainingRoles.isNotEmpty,
      'There should be at least one role to check',
    );
  }

  @override
  Widget build(BuildContext context) {
    return CheckRoleScreen(role: _remainingRoles[0], onComplete: onComplete);
  }

  void onComplete() {
    if (_remainingRoles.length == 1) {
      widget.onPhaseComplete();
    } else {
      setState(() {
        _remainingRoles.removeAt(0);
      });
    }
  }
}

class CheckRoleScreen extends StatefulWidget {
  final RoleType role;
  final VoidCallback onComplete;

  const CheckRoleScreen({
    super.key,
    required this.role,
    required this.onComplete,
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
        final localizations = AppLocalizations.of(context)!;

        final maxSelection = gameState.roles[widget.role] ?? 0;
        final minSelection = gameState.hasRoleType<ThiefRole>()
            ? maxSelection - (2 * gameState.roles[ThiefRole.type]!)
            : maxSelection;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              RoleManager.getRoleInstance(widget.role).checkRoleInstruction(
                context,
                gameState.roles[widget.role] ?? 0,
              ),
            ),
            automaticallyImplyLeading: false,
          ),
          body: ListView.builder(
            itemCount: gameState.playerCount,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(gameState.players[index].name),
                onTap: getOnTapPlayer(index, gameState),
                selected: _selectedPlayers[index],
                enabled: gameState.players[index].role == null,
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

    if ((gameState.roles[widget.role] ?? 0) == 1) {
      return () {
        final hasThiefRole = gameState.hasRoleType<ThiefRole>();
        setState(() {
          if (hasThiefRole) {
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
                selectedCount < (gameState.roles[widget.role] ?? 0)))
        ? () {
            setState(() {
              _selectedPlayers[index] = !_selectedPlayers[index];
            });
          }
        : null;
  }

  void onComplete(GameState gameState) {
    final selectedIndices = _selectedPlayers
        .asMap()
        .entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    gameState.setPlayersRole(widget.role, selectedIndices);

    widget.onComplete();
  }
}

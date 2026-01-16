import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/model/role.dart';
import 'package:werewolf_narrator/state/game.dart';

class CheckRoleScreen extends StatefulWidget {
  final Role role;
  final VoidCallback onPhaseComplete;

  const CheckRoleScreen({
    super.key,
    required this.role,
    required this.onPhaseComplete,
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
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Select ${(gameState.roles[widget.role] ?? 0) > 1 ? 'all' : 'the'} ${widget.role.name(context)}',
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
              );
            },
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
              ),
              onPressed: selectedCount == gameState.roles[widget.role]
                  ? () => onPhaseComplete(gameState)
                  : null,
              label: const Text('Continue'),
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
        setState(() {
          for (int i = 0; i < _selectedPlayers.length; i++) {
            _selectedPlayers[i] = false;
          }
          _selectedPlayers[index] = true;
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

  void onPhaseComplete(GameState gameState) {
    final selectedIndices = _selectedPlayers
        .asMap()
        .entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    gameState.setPlayersRole(widget.role, selectedIndices);

    widget.onPhaseComplete();
  }
}

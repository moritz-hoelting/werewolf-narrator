import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/model/role.dart';
import 'package:werewolf_narrator/state/game.dart';

class ActionScreen extends StatefulWidget {
  final Role role;
  final VoidCallback onPhaseComplete;

  const ActionScreen({
    super.key,
    required this.role,
    required this.onPhaseComplete,
  });

  @override
  State<ActionScreen> createState() => _ActionScreenState();
}

class _ActionScreenState extends State<ActionScreen> {
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
            title: Text('Select action for ${widget.role.name(context)}'),
            automaticallyImplyLeading: false,
          ),
          body: ListView.builder(
            itemCount: gameState.playerCount,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(gameState.players[index].name),
                onTap: getOnTapPlayer(index, gameState),
                selected: _selectedPlayers[index],
                enabled:
                    gameState.players[index].isAlive &&
                    ((widget.role.nightAction?.allowSelfSelect ?? false) ||
                        gameState.players[index].role != widget.role),
              );
            },
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
              ),
              onPressed: selectedCount == widget.role.nightAction?.maxSelection
                  ? () {
                      final onNightActionConfirm =
                          widget.role.nightAction?.onConfirm;
                      if (onNightActionConfirm != null) {
                        onNightActionConfirm(
                          _selectedPlayers
                              .asMap()
                              .entries
                              .where((entry) => entry.value)
                              .map((entry) => entry.key)
                              .toList(),
                          gameState,
                        );
                      }
                      widget.onPhaseComplete();
                    }
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
    if (!gameState.players[index].isAlive) {
      return null;
    }

    if (!(widget.role.nightAction?.allowSelfSelect ?? false) &&
        gameState.players[index].role == widget.role) {
      return null;
    }

    if ((widget.role.nightAction?.maxSelection ?? 0) == 1) {
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
                selectedCount < (widget.role.nightAction?.maxSelection ?? 0)))
        ? () {
            setState(() {
              _selectedPlayers[index] = !_selectedPlayers[index];
            });
          }
        : null;
  }
}

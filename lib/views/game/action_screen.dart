import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/model/role.dart';
import 'package:werewolf_narrator/state/game.dart';

class ActionScreen extends StatefulWidget {
  final Widget appBarTitle;

  final List<int> disabledPlayerIndices;

  final int selectionCount;
  final bool allowSelectLess;

  final void Function(List<int> playerIds, GameState gameState) onConfirm;

  const ActionScreen({
    super.key,
    required this.appBarTitle,
    required this.disabledPlayerIndices,
    required this.selectionCount,
    this.allowSelectLess = false,
    required this.onConfirm,
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
            title: widget.appBarTitle,
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
                    !widget.disabledPlayerIndices.contains(index),
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
                  (selectedCount == widget.selectionCount ||
                      (widget.allowSelectLess &&
                          selectedCount < widget.selectionCount))
                  ? () {
                      final selectedPlayers = _selectedPlayers
                          .asMap()
                          .entries
                          .where((entry) => entry.value)
                          .map((entry) => entry.key)
                          .toList();
                      if (selectedCount < widget.selectionCount) {
                        final answer = showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Fewer selections made'),
                            content: Text(
                              'You have selected $selectedCount player(s), '
                              'but the action allows selecting '
                              '${widget.selectionCount} player(s). '
                              'Do you want to continue?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('No'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Yes'),
                              ),
                            ],
                          ),
                        );
                        answer.then((continueWithLess) {
                          if (continueWithLess == true) {
                            widget.onConfirm(selectedPlayers, gameState);
                          }
                        });
                      } else {
                        widget.onConfirm(selectedPlayers, gameState);
                      }
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

    if (widget.disabledPlayerIndices.contains(index)) {
      return null;
    }

    if (widget.selectionCount == 1) {
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
            (!_selectedPlayers[index] && selectedCount < widget.selectionCount))
        ? () {
            setState(() {
              _selectedPlayers[index] = !_selectedPlayers[index];
            });
          }
        : null;
  }
}

class RoleActionScreen extends StatelessWidget {
  final Role role;
  final VoidCallback onPhaseComplete;

  const RoleActionScreen({
    super.key,
    required this.role,
    required this.onPhaseComplete,
  });

  @override
  Widget build(BuildContext context) {
    if (role.nightAction == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('No action for ${role.name(context)}'),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(60),
            ),
            onPressed: onPhaseComplete,
            label: const Text('Continue'),
            icon: const Icon(Icons.arrow_forward),
          ),
        ),
      );
    }

    return Consumer<GameState>(
      builder: (context, gameState, _) => ActionScreen(
        appBarTitle: Text('Select action for ${role.name(context)}'),
        disabledPlayerIndices: role.nightAction!.allowSelfSelect
            ? []
            : gameState.players
                  .asMap()
                  .entries
                  .where((entry) => entry.value.role == role)
                  .map((entry) => entry.key)
                  .toList(),
        selectionCount: role.nightAction!.selectionCount,
        onConfirm: (selectedPlayers, gameState) {
          if (role.nightAction!.onConfirm != null) {
            role.nightAction!.onConfirm!(selectedPlayers, gameState);
          }
          onPhaseComplete();
        },
      ),
    );
  }
}

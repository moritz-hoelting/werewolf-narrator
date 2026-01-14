import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/model/role.dart';
import 'package:werewolf_narrator/state/game.dart';

class ActionScreen extends StatefulWidget {
  final Widget appBarTitle;
  final VoidCallback onPhaseComplete;

  final List<int> disabledPlayerIndices;

  final int maxSelection;
  final bool allowSelfSelect;

  final void Function(List<int> playerIds, GameState gameState) onConfirm;

  const ActionScreen({
    super.key,
    required this.appBarTitle,
    required this.onPhaseComplete,
    required this.disabledPlayerIndices,
    required this.maxSelection,
    this.allowSelfSelect = false,
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
                    (widget.allowSelfSelect ||
                        !widget.disabledPlayerIndices.contains(index)),
              );
            },
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
              ),
              onPressed: selectedCount == widget.maxSelection
                  ? () {
                      widget.onConfirm(
                        _selectedPlayers
                            .asMap()
                            .entries
                            .where((entry) => entry.value)
                            .map((entry) => entry.key)
                            .toList(),
                        gameState,
                      );
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

    if (!widget.allowSelfSelect &&
        widget.disabledPlayerIndices.contains(index)) {
      return null;
    }

    if (widget.maxSelection == 1) {
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
            (!_selectedPlayers[index] && selectedCount < widget.maxSelection))
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
        onPhaseComplete: onPhaseComplete,
        disabledPlayerIndices: gameState.players
            .asMap()
            .entries
            .where((entry) => entry.value.role == role)
            .map((entry) => entry.key)
            .toList(),
        maxSelection: role.nightAction!.maxSelection,
        allowSelfSelect: role.nightAction!.allowSelfSelect,
        onConfirm: role.nightAction!.onConfirm ?? (_, __) {},
      ),
    );
  }
}

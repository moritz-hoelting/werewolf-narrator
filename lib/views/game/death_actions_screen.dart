import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/state/game.dart';

class DeathActionsScreen extends StatefulWidget {
  final VoidCallback onPhaseComplete;

  const DeathActionsScreen({super.key, required this.onPhaseComplete});

  @override
  State<DeathActionsScreen> createState() => _DeathActionsScreenState();
}

class _DeathActionsScreenState extends State<DeathActionsScreen> {
  List<(int, Widget Function(VoidCallback onPhaseComplete))> deathActions = [];

  void _reloadDeathActionsInternal() {
    deathActions.clear();
    Provider.of<GameState>(context, listen: false).players
        .asMap()
        .entries
        .where((player) => player.value.waitForDeathAction)
        .forEach((elem) {
          final (index, player) = (elem.key, elem.value);
          final deathScreenBuilder = player.role!.getDeathScreen(index);
          if (deathScreenBuilder != null) {
            deathActions.add((index, deathScreenBuilder));
          }
        });
  }

  @override
  void initState() {
    super.initState();
    _reloadDeathActionsInternal();
  }

  void reloadDeathActions() {
    setState(() {
      _reloadDeathActionsInternal();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (deathActions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Death Actions'),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: widget.onPhaseComplete,
            child: const Text('No death actions required. Continue.'),
          ),
        ),
      );
    }

    final (playerIndex, deathAction) = deathActions[0];

    return deathAction(() {
      GameState gameState = Provider.of<GameState>(context, listen: false);
      gameState.markPlayerUsedDeathAction(playerIndex);
      reloadDeathActions();
      if (deathActions.isEmpty) {
        widget.onPhaseComplete();
      }
    });
  }
}

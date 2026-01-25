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
  List<(int, WidgetBuilder Function(VoidCallback onPhaseComplete))>
  deathActions = [];

  void _reloadDeathActionsInternal() {
    deathActions.clear();
    final gameState = Provider.of<GameState>(context, listen: false);
    gameState.players.indexed
        .where(
          (player) =>
              player.$2.role != null &&
              player.$2.role!.hasDeathScreen(gameState) &&
              player.$2.waitForDeathAction(gameState),
        )
        .forEach((elem) {
          final (index, player) = (elem.$1, elem.$2);

          deathActions.add((
            index,
            (VoidCallback onComplete) =>
                player.role!.deathActionScreen(onComplete, index)!,
          ));
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
    assert(
      deathActions.isNotEmpty,
      "DeathActionsScreen built with no death actions",
    );

    final (playerIndex, deathAction) = deathActions[0];

    return deathAction(() {
      GameState gameState = Provider.of<GameState>(context, listen: false);
      gameState.markPlayerUsedDeathAction(playerIndex);
      reloadDeathActions();
      if (deathActions.isEmpty) {
        widget.onPhaseComplete();
      }
    })(context);
  }
}

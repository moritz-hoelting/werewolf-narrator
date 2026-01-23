import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/state/game.dart';
import 'package:werewolf_narrator/state/night_actions.dart';

class NightActionsScreen extends StatefulWidget {
  const NightActionsScreen({super.key, required this.onAllActionsComplete});

  final VoidCallback onAllActionsComplete;

  @override
  State<NightActionsScreen> createState() => _NightActionsScreenState();
}

class _NightActionsScreenState extends State<NightActionsScreen> {
  late final List<NightActionEntry> _phases;
  int _currentActionIndex = 0;

  @override
  void initState() {
    super.initState();

    final gameState = Provider.of<GameState>(context, listen: false);
    gameState.nightActionManager.ensureOrdered();
    _phases = gameState.nightActionManager.nightActions;

    _currentActionIndex = _phases.indexed
        .firstWhere((element) => element.$2.conditioned(gameState))
        .$1;
  }

  @override
  Widget build(BuildContext context) {
    final currentPhase = _phases[_currentActionIndex];
    return Consumer<GameState>(
      builder: (context, gameState, _) =>
          currentPhase.builder(gameState, onActionComplete)!(context),
    );
  }

  void onActionComplete() {
    final gameState = Provider.of<GameState>(context, listen: false);

    final nextIndex = _phases.indexed
        .skip(_currentActionIndex + 1)
        .firstWhereOrNull((element) => element.$2.conditioned(gameState))
        ?.$1;

    if (nextIndex != null) {
      setState(() {
        _currentActionIndex = nextIndex;
      });
    } else {
      widget.onAllActionsComplete();
    }
  }
}

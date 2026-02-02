import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/state/game.dart';
import 'package:werewolf_narrator/state/dynamic_actions.dart';

class DynamicActionsScreen extends StatefulWidget {
  const DynamicActionsScreen({
    super.key,
    required this.actionManager,
    required this.onAllActionsComplete,
  });

  final DynamicActionManager actionManager;
  final VoidCallback onAllActionsComplete;

  @override
  State<DynamicActionsScreen> createState() => _DynamicActionsScreenState();
}

class _DynamicActionsScreenState extends State<DynamicActionsScreen> {
  late final List<DynamicActionEntry> _actions;
  int _currentActionIndex = 0;

  @override
  void initState() {
    super.initState();

    final gameState = Provider.of<GameState>(context, listen: false);
    _actions = widget.actionManager.orderedActions;

    _currentActionIndex = _actions.indexed
        .firstWhere((element) => element.$2.conditioned(gameState))
        .$1;
  }

  @override
  Widget build(BuildContext context) {
    final currentPhase = _actions[_currentActionIndex];
    return Consumer<GameState>(
      builder: (context, gameState, _) =>
          currentPhase.builder(gameState, onActionComplete)!(context),
    );
  }

  void onActionComplete() {
    final gameState = Provider.of<GameState>(context, listen: false);

    final nextIndex = _actions.indexed
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

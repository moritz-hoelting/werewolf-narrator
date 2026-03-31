import 'package:collection/collection.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/util/dynamic_actions.dart';
import 'package:werewolf_narrator/game/util/hooks.dart' show ActionHook;

class DynamicActionsScreen extends StatefulWidget {
  const DynamicActionsScreen({
    super.key,
    required this.orderedActions,
    required this.actionHooks,
    required this.onAllActionsComplete,
  });

  final IList<DynamicActionEntry> orderedActions;
  final VoidCallback onAllActionsComplete;
  final IList<ActionHook> actionHooks;

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
    _actions = widget.orderedActions.where((entry) {
      final players = entry.players.lock;
      return widget.actionHooks.none(
        (hook) => hook(gameState, entry.identifier, players),
      );
    }).toList();

    _currentActionIndex =
        _actions.indexed
            .firstWhereOrNull((element) => element.$2.conditioned(gameState))
            ?.$1 ??
        -1;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentActionIndex == -1) {
      // No actions to perform, complete immediately
      Future.microtask(widget.onAllActionsComplete);
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
      gameState.finishBatch();
    } else {
      widget.onAllActionsComplete();
    }
  }
}

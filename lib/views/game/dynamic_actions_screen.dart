import 'package:collection/collection.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' show Option, FpdartOnOption;
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/game/game_command.dart' show GameCommand;
import 'package:werewolf_narrator/game/game_data.dart' show GameData;
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/util/dynamic_actions.dart';
import 'package:werewolf_narrator/game/util/hooks.dart' show ActionHook;

class DynamicActionsScreen extends StatelessWidget {
  const DynamicActionsScreen({
    super.key,
    required this.orderedActions,
    required this.actionHooks,
    required this.onAllActionsComplete,
    required this.night,
  });

  final IList<DynamicActionEntry> orderedActions;
  final VoidCallback onAllActionsComplete;
  final IList<ActionHook> actionHooks;
  final bool night;

  int _getCurrentActionIndex(BuildContext context) =>
      Provider.of<GameState>(context, listen: false).dynamicActionIndex ?? -1;

  void _setCurrentActionIndex(BuildContext context, int value) {
    Provider.of<GameState>(
      context,
      listen: false,
    ).finishBatch(SetDynamicActionIndexCommand(value));
  }

  @override
  Widget build(BuildContext context) {
    if (_getCurrentActionIndex(context) == -1) {
      // No actions to perform, complete immediately
      Future.microtask(onAllActionsComplete);
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentPhase = orderedActions[_getCurrentActionIndex(context)];
    return Consumer<GameState>(
      builder: (context, gameState, _) =>
          currentPhase.builder(gameState, onActionComplete(context))!(context),
    );
  }

  VoidCallback onActionComplete(BuildContext context) => () {
    final gameState = Provider.of<GameState>(context, listen: false);

    final nextIndex = _findNextValidIndex(
      gameState,
      night: night,
      startIndex: _getCurrentActionIndex(context) + 1,
    );

    if (nextIndex != null) {
      _setCurrentActionIndex(context, nextIndex);
    } else {
      onAllActionsComplete();
    }
  };
}

int? _findNextValidIndex(
  GameState gameState, {
  required bool night,
  int startIndex = 0,
}) {
  final orderedActions = night ? gameState.nightActions : gameState.dayActions;
  final actionHooks = night
      ? gameState.nightActionHooks
      : gameState.dayActionHooks;

  return orderedActions.indexed.skip(startIndex).firstWhereOrNull((entry) {
    final players = entry.$2.players.lock;
    return entry.$2.conditioned(gameState) &&
        actionHooks.none(
          (hook) => hook(gameState, entry.$2.identifier, players),
        );
  })?.$1;
}

class DetermineFirstDynamicActionIndexCommand implements GameCommand {
  final bool night;

  const DetermineFirstDynamicActionIndexCommand({required this.night});

  @override
  void apply(GameData gameData) {
    final index = _findNextValidIndex(gameData.state, night: night) ?? -1;

    gameData.state.apply(SetDynamicActionIndexCommand(index));
  }

  @override
  bool get canBeUndone => true;

  @override
  void undo(GameData gameData) {
    // handled within apply, no need to undo anything here
  }
}

class SetDynamicActionIndexCommand implements GameCommand {
  final int newIndex;

  SetDynamicActionIndexCommand(this.newIndex);

  Option<int?> previousIndex = Option.none();

  @override
  void apply(GameData data) {
    previousIndex = Option.of(data.dynamicActionIndex);
    data.dynamicActionIndex = newIndex;
  }

  @override
  bool get canBeUndone => previousIndex.isSome();

  @override
  void undo(GameData data) {
    if (previousIndex.isSome()) {
      data.dynamicActionIndex = previousIndex.getOrElse(() => null);
    }
  }
}

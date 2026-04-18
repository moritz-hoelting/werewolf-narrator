import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/widgets.dart';
import 'package:werewolf_narrator/game/commands/mark_dead.dart';
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/model/death_information.dart'
    show DeathInformation, DeathReason, DeathReasonMapper;
import 'package:werewolf_narrator/game/model/win_condition.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';

part 'lovers.mapper.dart';

// TODO: add option for setting lovers count to something other than 2
@MappableClass(discriminatorValue: 'lovers')
class Lovers with LoversMappable implements DeathReason, WinCondition {
  const Lovers(this.lovers);

  final ISet<int> lovers;

  void initialize(GameState gameState) {
    gameState.apply(InitializeLoversCommand(this));
  }

  @override
  String winningHeadline(BuildContext context) =>
      AppLocalizations.of(context).lovers_winHeadline;

  @override
  String deathReasonDescription(BuildContext context) =>
      AppLocalizations.of(context).lovers_deathReason;

  @override
  ISet<int> get responsiblePlayerIndices => lovers;

  @override
  bool hasWon(GameState gameState) => lovers.equalItems(
    gameState.players.indexed
        .where((player) => player.$2.isAlive)
        .map((player) => player.$1)
        .toSet(),
  );

  @override
  ISet<int> winningPlayers(GameState gameState) => lovers;
}

@MappableClass(discriminatorValue: 'initializeLovers')
class InitializeLoversCommand
    with InitializeLoversCommandMappable
    implements GameCommand {
  const InitializeLoversCommand(this.lovers);

  final Lovers lovers;

  @override
  void apply(GameData gameData) {
    gameData.deathHooks.add(deathHook);
    gameData.playerWinHooks.add(playerWinHook);
  }

  @override
  bool get canBeUndone => true;

  @override
  void undo(GameData gameData) {
    gameData.deathHooks.remove(deathHook);
    gameData.playerWinHooks.remove(playerWinHook);
  }

  bool deathHook(
    GameState gameState,
    int playerIndex,
    DeathInformation information,
  ) {
    if (information.reason is! Lovers && lovers.lovers.contains(playerIndex)) {
      final ISet<int> otherLovers = lovers.lovers.difference({playerIndex});
      gameState.apply(
        MarkDeadCommand(players: otherLovers, deathReason: lovers),
      );
    }

    return false;
  }

  bool? playerWinHook(
    GameState gameState,
    WinCondition winners,
    int playerIndex,
  ) {
    if (winners is! Lovers && lovers.lovers.contains(playerIndex)) {
      if (lovers.lovers
              .map(
                (playerIndex) =>
                    gameState.players[playerIndex].role?.team(gameState),
              )
              .toISet()
              .length >
          1) {
        return false;
      }
    }

    return null;
  }
}

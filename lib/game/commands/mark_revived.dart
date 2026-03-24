import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:fpdart/fpdart.dart';
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/model/death_information.dart'
    show DeathReason;

class MarkRevivedCommand implements GameCommand {
  const MarkRevivedCommand(this.players);
  MarkRevivedCommand.single(int player) : players = ISet({player});

  final ISet<int> players;

  final Map<int, DeathReason> deathReasons = const {};

  @override
  void apply(GameData gameData) {
    for (int playerIndex in players) {
      gameData.markPlayerRevived(playerIndex);
    }
  }

  @override
  bool get canBeUndone => players.all((key) => deathReasons.containsKey(key));

  @override
  void undo(GameData gameData) {
    for (final deathEntry in deathReasons.entries) {
      gameData.markPlayerDead(deathEntry.key, deathEntry.value);
    }
  }
}

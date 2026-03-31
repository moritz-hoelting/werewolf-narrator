import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:fpdart/fpdart.dart';
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/model/death_information.dart'
    show DeathInformation;

class MarkRevivedCommand implements GameCommand {
  MarkRevivedCommand(this.players);
  MarkRevivedCommand.single(int player) : players = ISet({player});

  final ISet<int> players;

  final Map<int, DeathInformation> deathInformations = {};

  @override
  void apply(GameData gameData) {
    for (int playerIndex in players) {
      final deathInformation = gameData.players[playerIndex].deathInformation;
      if (deathInformation != null) {
        deathInformations[playerIndex] = deathInformation;
      }
      gameData.markPlayerRevived(playerIndex);
    }
  }

  @override
  bool get canBeUndone =>
      players.all((key) => deathInformations.containsKey(key));

  @override
  void undo(GameData gameData) {
    for (final deathEntry in deathInformations.entries) {
      gameData.players[deathEntry.key].markDead(deathEntry.value);
    }
  }
}

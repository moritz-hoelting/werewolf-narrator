import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/model/death_information.dart'
    show DeathReason;

class MarkDeadCommand implements GameCommand {
  const MarkDeadCommand({required this.players, required this.deathReason});
  MarkDeadCommand.single({required int player, required this.deathReason})
    : players = ISet({player});

  final ISet<int> players;
  final DeathReason deathReason;

  @override
  void apply(GameData gameData) {
    for (int playerIndex in players) {
      gameData.markPlayerDead(playerIndex, deathReason);
    }
  }

  @override
  bool get canBeUndone => true;

  @override
  void undo(GameData gameData) {
    for (int playerIndex in players) {
      gameData.markPlayerRevived(playerIndex);
    }
  }
}

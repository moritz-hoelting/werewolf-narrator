import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/model/death_information.dart'
    show DeathReason, DeathReasonMapper;

part 'mark_dead.mapper.dart';

@MappableClass(discriminatorValue: 'markDead')
class MarkDeadCommand with MarkDeadCommandMappable implements GameCommand {
  @MappableConstructor()
  MarkDeadCommand({required this.players, required this.deathReason});
  MarkDeadCommand.single({required int player, required this.deathReason})
    : players = ISet({player});

  final ISet<int> players;
  final DeathReason deathReason;

  ISet<int>? _playersMarkedDead;

  @override
  void apply(GameData gameData) {
    _playersMarkedDead = players
        .where((playerIndex) => gameData.players[playerIndex].isAlive)
        .toISet();
    for (final int playerIndex in players) {
      gameData.markPlayerDead(playerIndex, deathReason);
    }
  }

  @override
  bool get canBeUndone => _playersMarkedDead != null;

  @override
  void undo(GameData gameData) {
    for (final int playerIndex in _playersMarkedDead!) {
      gameData.removeFromPendingDeaths(playerIndex, deathReason);
    }
  }
}

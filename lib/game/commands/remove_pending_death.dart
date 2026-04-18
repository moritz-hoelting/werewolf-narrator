import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/model/death_information.dart'
    show DeathReason, DeathReasonMapper;

part 'remove_pending_death.mapper.dart';

@MappableClass(discriminatorValue: 'removePendingDeath')
class RemovePendingDeathCommand
    with RemovePendingDeathCommandMappable
    implements GameCommand {
  @MappableConstructor()
  RemovePendingDeathCommand(this.players);
  RemovePendingDeathCommand.single(int player, DeathReason reason)
    : players = IMap({player: reason});

  final IMap<int, DeathReason> players;

  @override
  void apply(GameData gameData) {
    for (final entry in players.entries) {
      gameData.removeFromPendingDeaths(entry.key, entry.value);
    }
  }

  @override
  bool get canBeUndone => true;

  @override
  void undo(GameData gameData) {
    for (final entry in players.entries) {
      gameData.markPlayerDead(entry.key, entry.value);
    }
  }
}

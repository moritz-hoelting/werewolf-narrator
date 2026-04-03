import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:fpdart/fpdart.dart';
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/model/death_information.dart'
    show DeathInformation;

part 'mark_revived.mapper.dart';

@MappableClass(discriminatorValue: 'markRevived')
class MarkRevivedCommand
    with MarkRevivedCommandMappable
    implements GameCommand {
  @MappableConstructor()
  MarkRevivedCommand(this.players);
  MarkRevivedCommand.single(int player) : players = ISet({player});

  final ISet<int> players;

  final Map<int, DeathInformation> _deathInformations = {};

  @override
  void apply(GameData gameData) {
    for (final playerIndex in players) {
      final deathInformation = gameData.players[playerIndex].deathInformation;
      if (deathInformation != null) {
        _deathInformations[playerIndex] = deathInformation;
      }
      gameData.markPlayerRevived(playerIndex);
    }
  }

  @override
  bool get canBeUndone =>
      players.all((key) => _deathInformations.containsKey(key));

  @override
  void undo(GameData gameData) {
    for (final deathEntry in _deathInformations.entries) {
      gameData.players[deathEntry.key].markDead(deathEntry.value);
    }
  }
}

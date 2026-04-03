import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:fpdart/fpdart.dart';
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart' show GameData;

part 'composite.mapper.dart';

@MappableClass(discriminatorValue: 'composite')
class CompositeGameCommand
    with CompositeGameCommandMappable
    implements GameCommand {
  CompositeGameCommand(this.commands);

  final IList<GameCommand> commands;

  @override
  void apply(GameData gameData) {
    for (GameCommand command in commands) {
      command.apply(gameData);
    }
  }

  @override
  void undo(GameData gameData) {
    for (GameCommand command in commands.reversed) {
      command.undo(gameData);
    }
  }

  @override
  bool get canBeUndone => commands.all((command) => command.canBeUndone);
}

import 'package:dart_mappable/dart_mappable.dart';
import 'package:werewolf_narrator/game/game_data.dart';

part 'game_command.mapper.dart';

@MappableClass(discriminatorKey: 'type')
abstract interface class GameCommand with GameCommandMappable {
  void apply(GameData gameData);

  void undo(GameData gameData);

  bool get canBeUndone => true;
}

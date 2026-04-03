import 'package:dart_mappable/dart_mappable.dart';
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/model/win_condition.dart';

part 'register_win_condition.mapper.dart';

@MappableClass(discriminatorValue: 'registerWinCondition')
class RegisterWinConditionCommand
    with RegisterWinConditionCommandMappable
    implements GameCommand {
  const RegisterWinConditionCommand(this.winCondition);

  final WinCondition winCondition;

  @override
  void apply(GameData gameData) {
    gameData.winConditions.add(winCondition);
  }

  @override
  bool get canBeUndone => true;

  @override
  void undo(GameData gameData) {
    gameData.winConditions.remove(winCondition);
  }
}

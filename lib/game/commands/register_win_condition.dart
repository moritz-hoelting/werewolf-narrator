import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/model/win_condition.dart';

class RegisterWinConditionCommand implements GameCommand {
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

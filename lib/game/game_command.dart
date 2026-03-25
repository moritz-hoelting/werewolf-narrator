import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:fpdart/fpdart.dart';
import 'package:werewolf_narrator/game/game_data.dart';

abstract interface class GameCommand {
  void apply(GameData gameData);

  void undo(GameData gameData);

  bool get canBeUndone => true;
}

class CompositeGameCommand implements GameCommand {
  CompositeGameCommand(this._commands);

  final IList<GameCommand> _commands;

  @override
  void apply(GameData gameData) {
    for (GameCommand command in _commands) {
      command.apply(gameData);
    }
  }

  @override
  void undo(GameData gameData) {
    for (GameCommand command in _commands.reversed) {
      command.undo(gameData);
    }
  }

  @override
  bool get canBeUndone => _commands.all((command) => command.canBeUndone);

  @override
  String toString() {
    return "${super.toString()}$_commands";
  }
}

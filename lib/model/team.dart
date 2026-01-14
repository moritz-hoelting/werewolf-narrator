import 'package:werewolf_narrator/model/winner.dart';

enum Team {
  village,
  werewolves;

  Winner get toWinner {
    switch (this) {
      case Team.village:
        return Winner.village;
      case Team.werewolves:
        return Winner.werewolves;
    }
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/model/team.dart';
import 'package:werewolf_narrator/game/role/loner/angel.dart' show AngelRole;
import 'package:werewolf_narrator/game/role/village/cupid.dart' show CupidRole;
import 'package:werewolf_narrator/game/role/village/hunter.dart'
    show HunterRole;
import 'package:werewolf_narrator/game/role/village/seer.dart' show SeerRole;
import 'package:werewolf_narrator/game/role/werewolves/werewolf.dart'
    show WerewolfRole;
import 'package:werewolf_narrator/game/game_state.dart';

void main() {
  setUpAll(() {
    RoleManager.ensureRegistered();
    TeamManager.ensureRegistered();
  });

  test("Test game phase order", () {
    GameState state = GameState(
      players: List.generate(4, (index) => "Player $index"),
      roleConfigurations: {
        SeerRole.type: (count: 1, config: {}),
        HunterRole.type: (count: 1, config: {}),
        CupidRole.type: (count: 1, config: {}),
        WerewolfRole.type: (count: 1, config: {}),
      },
    );

    final List<GamePhase> expectedOrder = [
      GamePhase.dusk,
      GamePhase.checkRoles,
      GamePhase.nightActions,
      GamePhase.dawn,
      GamePhase.dayActions,
      GamePhase.dusk,
      GamePhase.nightActions,
      GamePhase.dawn,
      GamePhase.dayActions,
      GamePhase.dusk,
      GamePhase.nightActions,
      GamePhase.dawn,
      GamePhase.dayActions,
    ];

    for (int i = 0; i < expectedOrder.length; i++) {
      if (state.phase == GamePhase.checkRoles) {
        state.setPlayersRole(SeerRole.type, [0]);
        state.setPlayersRole(HunterRole.type, [1]);
        state.setPlayersRole(CupidRole.type, [2]);
        state.setPlayersRole(WerewolfRole.type, [3]);
      }
      expect(
        state.phase,
        equals(expectedOrder[i]),
        reason: "Expected phase ${expectedOrder[i]} at step $i",
      );
      final bool successful = state.transitionToNextPhase();
      expect(
        successful,
        isTrue,
        reason: "Expected successful transition at step $i",
      );
    }
  });

  test("Test game phase order with Angel role", () {
    GameState state = GameState(
      players: List.generate(4, (index) => "Player $index"),
      roleConfigurations: {
        SeerRole.type: (count: 1, config: {}),
        AngelRole.type: (count: 1, config: {}),
        CupidRole.type: (count: 1, config: {}),
        WerewolfRole.type: (count: 1, config: {}),
      },
    );

    final List<(GamePhase, int)> expectedOrder = [
      (GamePhase.dusk, 0),
      (GamePhase.checkRoles, 0),
      (GamePhase.dawn, 0),
      (GamePhase.dayActions, 0),
      (GamePhase.dusk, 0),
      (GamePhase.nightActions, 0),
      (GamePhase.dawn, 1),
      (GamePhase.dayActions, 1),
      (GamePhase.dusk, 1),
      (GamePhase.nightActions, 1),
      (GamePhase.dawn, 2),
      (GamePhase.dayActions, 2),
    ];

    for (int i = 0; i < expectedOrder.length; i++) {
      if (state.phase == GamePhase.checkRoles) {
        state.setPlayersRole(SeerRole.type, [0]);
        state.setPlayersRole(AngelRole.type, [1]);
        state.setPlayersRole(CupidRole.type, [2]);
        state.setPlayersRole(WerewolfRole.type, [3]);
      }
      expect(
        (state.phase, state.dayCounter),
        equals(expectedOrder[i]),
        reason: "Expected phase ${expectedOrder[i]} at step $i",
      );
      final bool successful = state.transitionToNextPhase();
      expect(
        successful,
        isTrue,
        reason: "Expected successful transition at step $i",
      );
    }
  });
}

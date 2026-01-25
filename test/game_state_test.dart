import 'package:flutter_test/flutter_test.dart';
import 'package:werewolf_narrator/model/role.dart';
import 'package:werewolf_narrator/model/team.dart';
import 'package:werewolf_narrator/role/cupid.dart' show CupidRole;
import 'package:werewolf_narrator/role/hunter.dart' show HunterRole;
import 'package:werewolf_narrator/role/seer.dart' show SeerRole;
import 'package:werewolf_narrator/role/werewolf.dart' show WerewolfRole;
import 'package:werewolf_narrator/state/game.dart';
import 'package:werewolf_narrator/state/game_phase.dart';

void main() {
  setUpAll(() {
    RoleManager.ensureRegistered();
    TeamManager.ensureRegistered();
  });

  test("Test game phase order", () {
    GameState state = GameState(
      players: List.generate(4, (index) => "Player $index"),
      roleCounts: {
        SeerRole.type: 1,
        HunterRole.type: 1,
        CupidRole.type: 1,
        WerewolfRole.type: 1,
      },
    );

    state.setPlayersRole(SeerRole.type, [0]);
    state.setPlayersRole(HunterRole.type, [1]);
    state.setPlayersRole(CupidRole.type, [2]);
    state.setPlayersRole(WerewolfRole.type, [3]);

    state.nightActionManager.ensureOrdered();

    final List<GamePhase> expectedOrder = [
      GamePhase.dusk,
      GamePhase.checkRoles,
      GamePhase.nightActions,
      GamePhase.dawn,
      GamePhase.sheriffElection,
      GamePhase.voting,
      GamePhase.dusk,
      GamePhase.nightActions,
      GamePhase.dawn,
      GamePhase.voting,
      GamePhase.dusk,
      GamePhase.nightActions,
      GamePhase.dawn,
      GamePhase.voting,
    ];

    for (int i = 0; i < expectedOrder.length; i++) {
      expect(
        state.phase,
        equals(expectedOrder[i]),
        reason: "Expected phase ${expectedOrder[i]} at step $i",
      );
      if (state.phase == GamePhase.sheriffElection) {
        state.sheriff = 0; // Assign a sheriff to proceed
      }
      final bool successful = state.transitionToNextPhase();
      expect(
        successful,
        isTrue,
        reason: "Expected successful transition at step $i",
      );
    }
  });
}

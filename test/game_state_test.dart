import 'package:flutter_test/flutter_test.dart';
import 'package:werewolf_narrator/model/role.dart';
import 'package:werewolf_narrator/state/game.dart';
import 'package:werewolf_narrator/state/game_phase.dart';

void main() {
  test("Test game phase order", () {
    GameState state = GameState(
      players: List.generate(4, (index) => "Player $index"),
      roles: {Role.seer: 1, Role.hunter: 1, Role.cupid: 1, Role.werewolf: 1},
    );

    state.players[0].role = Role.seer;
    state.players[1].role = Role.hunter;
    state.players[2].role = Role.cupid;
    state.players[3].role = Role.werewolf;

    final List<GamePhase> expectedOrder = [
      GamePhase.dusk,
      GamePhase.checkRoleSeer,
      GamePhase.checkRoleHunter,
      GamePhase.checkRoleCupid,
      GamePhase.checkRoleWerewolves,
      GamePhase.cupid,
      GamePhase.lovers,
      GamePhase.seer,
      GamePhase.werewolves,
      GamePhase.dawn,
      GamePhase.sheriffElection,
      GamePhase.voting,
      GamePhase.dusk,
      GamePhase.seer,
      GamePhase.werewolves,
      GamePhase.dawn,
      GamePhase.voting,
      GamePhase.dusk,
      GamePhase.seer,
      GamePhase.werewolves,
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

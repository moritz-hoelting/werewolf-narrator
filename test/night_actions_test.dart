import 'package:flutter_test/flutter_test.dart';
import 'package:werewolf_narrator/model/role.dart';
import 'package:werewolf_narrator/model/team.dart';
import 'package:werewolf_narrator/role/role.dart';
import 'package:werewolf_narrator/state/game.dart';
import 'package:werewolf_narrator/state/night_actions.dart';
import 'package:werewolf_narrator/team/team.dart';

void main() {
  setUpAll(() {
    RoleManager.ensureRegistered();
    TeamManager.ensureRegistered();
  });

  test("Test night action order", () {
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

    NightActionManager nightActionManager = state.nightActionManager;

    nightActionManager.ensureOrdered();

    final List<Object> actions = nightActionManager.nightActions
        .map((action) => action.identifier)
        .toList();

    final List<Object> expectedOrder = [
      CupidRole.type,
      SeerRole.type,
      WerewolvesTeam.type,
    ];

    expect(actions, equals(expectedOrder));
  });
}

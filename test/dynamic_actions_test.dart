import 'package:flutter_test/flutter_test.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/model/team.dart';
import 'package:werewolf_narrator/game/role/village/cupid.dart' show CupidRole;
import 'package:werewolf_narrator/game/role/village/hunter.dart'
    show HunterRole;
import 'package:werewolf_narrator/game/role/village/seer.dart' show SeerRole;
import 'package:werewolf_narrator/game/role/werewolves/werewolf.dart'
    show WerewolfRole;
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/util/dynamic_actions.dart';
import 'package:werewolf_narrator/game/team/werewolves.dart'
    show WerewolvesTeam;

void main() {
  setUpAll(() {
    RoleManager.ensureRegistered();
    TeamManager.ensureRegistered();
  });

  test("Test night action order", () {
    GameState state = GameState(
      playerNames: List.generate(4, (index) => "Player $index"),
      roleConfigurations: {
        SeerRole.type: (count: 1, config: {}),
        HunterRole.type: (count: 1, config: {}),
        CupidRole.type: (count: 1, config: {}),
        WerewolfRole.type: (count: 1, config: {}),
      },
    );

    state.setPlayersRole(SeerRole.type, [0]);
    state.setPlayersRole(HunterRole.type, [1]);
    state.setPlayersRole(CupidRole.type, [2]);
    state.setPlayersRole(WerewolfRole.type, [3]);

    DynamicActionManager nightActionManager = state.nightActionManager;

    final List<Object> actions = nightActionManager.orderedActions
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

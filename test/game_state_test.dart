import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:werewolf_narrator/game/commands/composite.dart';
import 'package:werewolf_narrator/game/commands/set_players_role.dart';
import 'package:werewolf_narrator/game/game_data.dart'
    show GamePhase, TransitionToNextPhaseCommand;
import 'package:werewolf_narrator/game/game_registry.g.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/role/loner/angel.dart' show AngelRole;
import 'package:werewolf_narrator/game/role/village/cupid.dart' show CupidRole;
import 'package:werewolf_narrator/game/role/village/hunter.dart'
    show HunterRole;
import 'package:werewolf_narrator/game/role/village/seer.dart' show SeerRole;
import 'package:werewolf_narrator/game/role/werewolves/werewolf.dart'
    show WerewolfRole;

void main() {
  setUpAll(() {
    GameRegistry.ensureInitialized();
  });

  test('Test game phase order', () {
    final state = GameState(
      playerNames: List.generate(4, (index) => 'Player $index'),
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

    for (var i = 0; i < expectedOrder.length; i++) {
      if (state.phase == GamePhase.checkRoles) {
        state.apply(
          CompositeGameCommand(
            [
              SetPlayersRoleCommand(SeerRole.type, ISet({0})),
              SetPlayersRoleCommand(HunterRole.type, ISet({1})),
              SetPlayersRoleCommand(CupidRole.type, ISet({2})),
              SetPlayersRoleCommand(WerewolfRole.type, ISet({3})),
            ].lock,
          ),
        );
      }
      expect(
        state.phase,
        equals(expectedOrder[i]),
        reason: 'Expected phase ${expectedOrder[i]} at step $i',
      );
      state.finishBatch(TransitionToNextPhaseCommand());
    }
  });

  test('Test game phase order with Angel role', () {
    final state = GameState(
      playerNames: List.generate(4, (index) => 'Player $index'),
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

    for (var i = 0; i < expectedOrder.length; i++) {
      if (state.phase == GamePhase.checkRoles) {
        state.apply(
          CompositeGameCommand(
            [
              SetPlayersRoleCommand(SeerRole.type, ISet({0})),
              SetPlayersRoleCommand(AngelRole.type, ISet({1})),
              SetPlayersRoleCommand(CupidRole.type, ISet({2})),
              SetPlayersRoleCommand(WerewolfRole.type, ISet({3})),
            ].lock,
          ),
        );
      }
      expect(
        (state.phase, state.dayCounter),
        equals(expectedOrder[i]),
        reason: 'Expected phase ${expectedOrder[i]} at step $i',
      );
      state.finishBatch(TransitionToNextPhaseCommand());
    }
  });
}

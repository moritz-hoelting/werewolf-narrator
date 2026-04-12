import 'package:drift/native.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:werewolf_narrator/database/database.dart';
import 'package:werewolf_narrator/game/commands/composite.dart';
import 'package:werewolf_narrator/game/commands/set_players_role.dart';
import 'package:werewolf_narrator/game/game_registry.g.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/model/configuration_options.dart'
    show fillDefaultGameConfiguration;
import 'package:werewolf_narrator/game/role/village/cupid.dart' show CupidRole;
import 'package:werewolf_narrator/game/role/village/hunter.dart'
    show HunterRole;
import 'package:werewolf_narrator/game/role/village/seer.dart' show SeerRole;
import 'package:werewolf_narrator/game/role/werewolves/werewolf.dart'
    show WerewolfRole;
import 'package:werewolf_narrator/game/team/werewolves.dart'
    show WerewolvesTeam;

void main() {
  const emptyConfig = <String, dynamic>{};

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GameRegistry.ensureInitialized();
  });

  test('Test night action order', () {
    AppDatabaseHolder(NativeDatabase.memory());

    final state = GameState(
      id: 0,
      playerNames: List.generate(4, (index) => 'Player $index'),
      gameConfiguration: fillDefaultGameConfiguration({}),
      roleConfigurations: {
        SeerRole.type: (count: 1, config: emptyConfig),
        HunterRole.type: (count: 1, config: emptyConfig),
        CupidRole.type: (count: 1, config: emptyConfig),
        WerewolfRole.type: (count: 1, config: emptyConfig),
      }.lock,
    );

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

    final List<Object> actions = state.nightActions
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

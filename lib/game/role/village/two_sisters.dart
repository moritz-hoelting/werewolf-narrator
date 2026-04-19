import 'package:collection/collection.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_annotations/register_role.dart' show RegisterRole;
import 'package:werewolf_narrator/game/game_command.dart'
    show GameCommand, GameCommandMapper;
import 'package:werewolf_narrator/game/game_data.dart' show GameData;
import 'package:werewolf_narrator/game/game_state.dart' show GameState;
import 'package:werewolf_narrator/game/model/configuration_options.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/widgets/bottom_continue_button.dart';
import 'package:werewolf_narrator/widgets/game/app_bar.dart';

part 'two_sisters.mapper.dart';

@RegisterRole()
class TwoSistersRole extends Role {
  TwoSistersRole._({
    required RoleConfiguration config,
    required super.playerIndex,
  }) : wakeEveryNthNight = wakeEveryNthNightOption.read(config);
  static final RoleType type = RoleType.of<TwoSistersRole>();
  @override
  RoleType get roleType => type;

  static final wakeEveryNthNightOption = IntOption(
    id: 'wakeEveryNthNight',
    label: (context) => AppLocalizations.of(
      context,
    ).role_twoSisters_option_wakeEveryNthNight_label,
    description: (context) => AppLocalizations.of(
      context,
    ).role_twoSisters_option_wakeEveryNthNight_description,
    defaultValue: 0,
    min: 0,
  );

  int wakeEveryNthNight;

  static void registerRole() {
    RoleManager.registerRole<TwoSistersRole>(
      type,
      RegisterRoleInformation(
        constructor: TwoSistersRole._,
        name: (context) => AppLocalizations.of(context).role_twoSisters_name,
        description: (context) =>
            AppLocalizations.of(context).role_twoSisters_description,
        initialTeam: VillageTeam.type,
        checkRoleInstruction: (context, count) => AppLocalizations.of(
          context,
        ).role_twoSisters_checkInstruction(count: count),
        validRoleCounts: const [2],
        options: IList([wakeEveryNthNightOption]),
        chooseRolesInformation: const ChooseRolesInformation(
          category: ChooseRolesCategory.village,
          priority: 40,
        ),
      ),
    );
  }

  @override
  void onAssign(GameState gameState) {
    super.onAssign(gameState);

    if (wakeEveryNthNight != 0) {
      final twoSisters = gameState.players.indexed
          .where((entry) => entry.$2.role is TwoSistersRole)
          .map((entry) => entry.$1)
          .sorted((a, b) => a.compareTo(b))
          .toList();
      if (twoSisters.length == 2) {
        final playerIndexA = twoSisters[0];
        final playerIndexB = twoSisters[1];

        gameState.apply(
          RegisterTwoSistersNightActionCommand(
            wakeEveryNthNight: wakeEveryNthNight,
            playerIndexA: playerIndexA,
            playerIndexB: playerIndexB,
          ),
        );
      }
    }
  }
}

@MappableClass(discriminatorValue: 'registerTwoSistersNightAction')
class RegisterTwoSistersNightActionCommand
    with RegisterTwoSistersNightActionCommandMappable
    implements GameCommand {
  const RegisterTwoSistersNightActionCommand({
    required this.wakeEveryNthNight,
    required this.playerIndexA,
    required this.playerIndexB,
  });

  final int wakeEveryNthNight;
  final int playerIndexA;
  final int playerIndexB;

  @override
  void apply(GameData gameData) {
    gameData.nightActionManager.registerAction(
      TwoSistersRole.type,
      (gameState, onComplete) =>
          (context) => TwoSistersScreen(
            playerIndexA: playerIndexA,
            playerIndexB: playerIndexB,
            onPhaseComplete: onComplete,
          ),
      conditioned: (gameState) =>
          gameState.dayCounter % wakeEveryNthNight == 0 &&
          gameState.players[playerIndexA].isAlive &&
          gameState.players[playerIndexB].isAlive,
      players: {playerIndexA, playerIndexB},
    );
  }

  @override
  bool get canBeUndone => true;

  @override
  void undo(GameData gameData) {
    gameData.nightActionManager.unregisterAction(TwoSistersRole.type);
  }
}

class TwoSistersScreen extends StatelessWidget {
  const TwoSistersScreen({
    required this.playerIndexA,
    required this.playerIndexB,
    required this.onPhaseComplete,
    super.key,
  });

  final int playerIndexA;
  final int playerIndexB;
  final VoidCallback onPhaseComplete;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: GameAppBar(title: Text(localizations.role_twoSisters_name)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Consumer<GameState>(
            builder: (context, gameState, _) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              spacing: 16.0,
              children: [
                Text(
                  localizations.role_twoSisters_nightAction_instruction,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                Text(gameState.players[playerIndexA].name),
                Text(gameState.players[playerIndexB].name),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomContinueButton(onPressed: onPhaseComplete),
    );
  }
}

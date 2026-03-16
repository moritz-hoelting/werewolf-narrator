import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/model/role_config.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/role/village/witch.dart' show WitchRole;
import 'package:werewolf_narrator/game/role/werewolves/big_bad_wolf.dart'
    show BigBadWolfRole;
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/game/team/werewolves.dart'
    show WerewolvesTeam;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/views/game/action_screen.dart';
import 'package:werewolf_narrator/widgets/bottom_continue_button.dart';

class PriestRole extends Role {
  PriestRole._(RoleConfiguration config)
    : blessAmountRemaining = config[PriestRole.blessCountOptionId];

  static final RoleType<PriestRole> type = RoleType<PriestRole>();
  @override
  RoleType<PriestRole> get objectType => type;

  static const String blessCountOptionId = 'blessCount';

  int blessAmountRemaining;

  Set<int> blessedPlayers = {};

  static void registerRole() {
    RoleManager.registerRole<PriestRole>(
      type,
      RegisterRoleInformation(
        constructor: PriestRole._,
        name: _name,
        description: (context) =>
            AppLocalizations.of(context).role_priest_description,
        initialTeam: VillageTeam.type,
        checkRoleInstruction: (context, count) => AppLocalizations.of(
          context,
        ).role_priest_checkInstruction(count: count),
        validRoleCounts: const [1],
        chooseRolesInformation: ChooseRolesInformation(
          category: ChooseRolesCategory.village,
        ),
        options: IList([
          IntOption(
            id: blessCountOptionId,
            label: (context) =>
                AppLocalizations.of(context).role_priest_option_blessCountLabel,
            description: (context) => AppLocalizations.of(
              context,
            ).role_priest_option_blessCountDescription,
            defaultValue: 1,
            min: 1,
          ),
        ]),
      ),
    );
  }

  static String _name(BuildContext context) =>
      AppLocalizations.of(context).role_priest_name;

  @override
  void onAssign(GameState gameState, int playerIndex) {
    super.onAssign(gameState, playerIndex);

    gameState.nightActionManager.registerAction(
      PriestRole.type,
      (gameState, onComplete) => nightActionScreen(playerIndex, onComplete),
      conditioned: (gameState) => gameState.playerAliveUntilDawn(playerIndex),
      before: IList([WerewolvesTeam.type, WitchRole.type, BigBadWolfRole.type]),
      players: {playerIndex},
    );

    gameState.deathHooks.add((gameState, deadPlayerIndex, reason) {
      return gameState.isNight && blessedPlayers.contains(deadPlayerIndex);
    });
  }

  WidgetBuilder nightActionScreen(
    int playerIndex,
    VoidCallback onComplete,
  ) => (BuildContext context) {
    return blessAmountRemaining > 0
        ? ActionScreen(
            key: UniqueKey(),
            appBarTitle: Text(_name(context)),
            instruction: Text(
              AppLocalizations.of(context).role_priest_nightAction_instruction,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            actionIdentifier: PriestRole.type,
            selectionCount: blessAmountRemaining,
            allowSelectLess: true,
            onConfirm: (selection, gameState) {
              blessedPlayers.addAll(selection);
              blessAmountRemaining -= selection.length;
              onComplete();
            },
            currentActorIndices: ISet({playerIndex}),
            disabledPlayerIndices: ISet(blessedPlayers),
          )
        : Scaffold(
            appBar: AppBar(title: Text(_name(context))),
            body: Center(
              child: Text(
                AppLocalizations.of(context).role_priest_nightAction_noBlesses,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
            bottomNavigationBar: BottomContinueButton(onPressed: onComplete),
          );
  };
}

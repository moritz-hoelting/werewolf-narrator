import 'package:werewolf_annotations/register_role.dart' show RegisterRole;
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/model/death_information.dart'
    show DeathReason;
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

@RegisterRole()
class PriestRole extends Role {
  PriestRole._({required RoleConfiguration config, required super.playerIndex})
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
  void onAssign(GameState gameState) {
    super.onAssign(gameState);

    gameState.apply(OnAssignPriestCommand(playerIndex));
  }
}

class OnAssignPriestCommand implements GameCommand {
  const OnAssignPriestCommand(this.playerIndex);

  final int playerIndex;

  @override
  void apply(GameData gameData) {
    gameData.nightActionManager.registerAction(
      PriestRole.type,
      (gameState, onComplete) => nightActionScreen(gameState, onComplete),
      conditioned: (gameState) => gameState.playerAliveUntilDawn(playerIndex),
      before: IList([WerewolvesTeam.type, WitchRole.type, BigBadWolfRole.type]),
      players: {playerIndex},
    );

    gameData.deathHooks.add(deathHook);
  }

  @override
  bool get canBeUndone => true;

  @override
  void undo(GameData gameData) {
    gameData.nightActionManager.unregisterAction(PriestRole.type);

    gameData.deathHooks.remove(deathHook);
  }

  bool deathHook(GameState gameState, int deadPlayerIndex, DeathReason reason) {
    final priest = gameState.players[playerIndex].role as PriestRole;
    return gameState.isNight && priest.blessedPlayers.contains(deadPlayerIndex);
  }

  WidgetBuilder nightActionScreen(
    GameState gameState,
    VoidCallback onComplete,
  ) => (BuildContext context) {
    final priest = gameState.players[playerIndex].role as PriestRole;
    return priest.blessAmountRemaining > 0
        ? ActionScreen(
            key: UniqueKey(),
            appBarTitle: Text(PriestRole._name(context)),
            instruction: Text(
              AppLocalizations.of(context).role_priest_nightAction_instruction,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            actionIdentifier: PriestRole.type,
            selectionCount: priest.blessAmountRemaining,
            allowSelectLess: true,
            onConfirm: (selection, gameState) {
              gameState.apply(
                PriestBlessPlayersCommand(
                  playerIndex: playerIndex,
                  playersToBless: selection,
                ),
              );
              onComplete();
            },
            currentActorIndices: ISet({playerIndex}),
            disabledPlayerIndices: ISet(priest.blessedPlayers),
          )
        : Scaffold(
            appBar: AppBar(title: Text(PriestRole._name(context))),
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

class PriestBlessPlayersCommand implements GameCommand {
  const PriestBlessPlayersCommand({
    required this.playerIndex,
    required this.playersToBless,
  });

  final int playerIndex;
  final ISet<int> playersToBless;

  @override
  void apply(GameData gameData) {
    final priest = gameData.players[playerIndex].role as PriestRole;
    priest.blessedPlayers.addAll(playersToBless);
    priest.blessAmountRemaining -= playersToBless.length;
  }

  @override
  bool get canBeUndone => true;

  @override
  void undo(GameData gameData) {
    final priest = gameData.players[playerIndex].role as PriestRole;

    priest.blessedPlayers.removeAll(playersToBless);
    priest.blessAmountRemaining += playersToBless.length;
  }
}

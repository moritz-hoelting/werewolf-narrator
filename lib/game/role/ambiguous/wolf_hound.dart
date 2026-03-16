import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:werewolf_narrator/game/model/role_config.dart';
import 'package:werewolf_narrator/game/model/team.dart';
import 'package:werewolf_narrator/game/team/team.dart';
import 'package:werewolf_narrator/game/team/werewolves.dart'
    show WerewolvesTeam;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/views/game/binary_selection_screen.dart';

class WolfHoundRole extends Role {
  WolfHoundRole._(RoleConfiguration config);

  static final RoleType<WolfHoundRole> type = RoleType<WolfHoundRole>();
  @override
  RoleType<WolfHoundRole> get objectType => type;

  bool? selectedWerewolf;

  @override
  String name(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (selectedWerewolf == null) {
      return super.name(context);
    } else if (selectedWerewolf!) {
      return localizations.role_wolfHound_name_werewolf;
    } else {
      return localizations.role_wolfHound_name_dog;
    }
  }

  @override
  TeamType<Team>? team(GameState gameState) => overrideTeam.getOrElse(() {
    if (selectedWerewolf == true) {
      return WerewolvesTeam.type;
    }
    return super.team(gameState);
  });

  static void registerRole() {
    RoleManager.registerRole<WolfHoundRole>(
      type,
      RegisterRoleInformation(
        constructor: WolfHoundRole._,
        name: (context) => AppLocalizations.of(context).role_wolfHound_name,
        description: (context) =>
            AppLocalizations.of(context).role_wolfHound_description,
        initialTeam: VillageTeam.type,
        checkRoleInstruction: (context, count) => AppLocalizations.of(
          context,
        ).role_wolfHound_checkInstruction(count: count),
        validRoleCounts: const [1],
        chooseRolesInformation: ChooseRolesInformation(
          category: ChooseRolesCategory.ambiguous,
          priority: 2,
        ),
      ),
    );
  }

  @override
  void onAssign(GameState gameState, int playerIndex) {
    super.onAssign(gameState, playerIndex);

    gameState.nightActionManager.registerAction(
      WolfHoundRole.type,
      (gameState, onComplete) {
        return nightActionScreen(playerIndex, onComplete);
      },
      conditioned: (gameState) =>
          gameState.playerAliveUntilDawn(playerIndex) &&
          selectedWerewolf == null,
      players: {playerIndex},
      before: IList([WerewolvesTeam.type]),
    );
  }

  WidgetBuilder nightActionScreen(int playerIndex, VoidCallback onComplete) =>
      (context) {
        final localizations = AppLocalizations.of(context);
        return BinarySelectionScreen(
          key: UniqueKey(),
          appBarTitle: Text(localizations.role_wolfHound_name),
          instruction: Text(
            localizations.role_wolfHound_nightAction_instruction,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          firstOption: Text(localizations.team_village_name),
          secondOption: Text(localizations.team_werewolves_name),
          onComplete: (selectedFirst) {
            selectedWerewolf = !selectedFirst!;
            onComplete();
          },
        );
      };
}

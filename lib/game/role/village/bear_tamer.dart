import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:werewolf_narrator/game/misc/phases/voting.dart'
    show VillageVoteScreen;
import 'package:werewolf_narrator/game/model/role_config.dart';
import 'package:werewolf_narrator/game/team/werewolves.dart'
    show WerewolvesTeam;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/util/set.dart';
import 'package:werewolf_narrator/widgets/bottom_continue_button.dart';

class BearTamerRole extends Role {
  BearTamerRole._(RoleConfiguration config);
  static final RoleType<BearTamerRole> type = RoleType<BearTamerRole>();
  @override
  RoleType<BearTamerRole> get objectType => type;

  static void registerRole() {
    RoleManager.registerRole<BearTamerRole>(
      type,
      RegisterRoleInformation(
        constructor: BearTamerRole._,
        name: (context) => AppLocalizations.of(context).role_bearTamer_name,
        description: (context) =>
            AppLocalizations.of(context).role_bearTamer_description,
        initialTeam: VillageTeam.type,
        checkRoleInstruction: (context, count) => AppLocalizations.of(
          context,
        ).role_bearTamer_checkInstruction(count: count),
        validRoleCounts: const [1],
        chooseRolesInformation: ChooseRolesInformation(
          category: ChooseRolesCategory.village,
          priority: 10,
        ),
      ),
    );
  }

  @override
  void onAssign(GameState gameState, int playerIndex) {
    super.onAssign(gameState, playerIndex);

    // TODO: change to dawn message
    gameState.dayActionManager.registerAction(
      BearTamerRole,
      (gameState, onComplete) =>
          (context) =>
              BearGruntScreen(playerIndex: playerIndex, onComplete: onComplete),
      conditioned: (gameState) => gameState
          .getAliveNeighbors(playerIndex)
          .toISet()
          .union(ISet({playerIndex}))
          .intersection(WerewolvesTeam.werewolfPlayerIndices(gameState))
          .isNotEmpty,
      players: {playerIndex},
      beforeAll: true,
      before: IList([VillageVoteScreen]),
    );
  }
}

class BearGruntScreen extends StatelessWidget {
  final int playerIndex;
  final VoidCallback onComplete;

  const BearGruntScreen({
    super.key,
    required this.playerIndex,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.role_bearTamer_name),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              localizations.role_bearTamer_growl,
              style: Theme.of(context).textTheme.displayMedium,
            ),
            Text(
              localizations.role_bearTamer_growl_subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomContinueButton(onPressed: onComplete),
    );
  }
}

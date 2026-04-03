import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:werewolf_annotations/register_role.dart' show RegisterRole;
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/misc/phases/voting.dart'
    show VillageVoteScreen;
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/model/role_config.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/game/team/werewolves.dart'
    show WerewolvesTeam;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/util/set.dart';
import 'package:werewolf_narrator/widgets/bottom_continue_button.dart';
import 'package:werewolf_narrator/widgets/game/app_bar.dart';

part 'bear_tamer.mapper.dart';

@RegisterRole()
class BearTamerRole extends Role {
  BearTamerRole._({
    required RoleConfiguration config,
    required super.playerIndex,
  });
  static final RoleType type = RoleType.of<BearTamerRole>();
  @override
  RoleType get roleType => type;

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
        chooseRolesInformation: const ChooseRolesInformation(
          category: ChooseRolesCategory.village,
          priority: 10,
        ),
      ),
    );
  }

  @override
  void onAssign(GameState gameState) {
    super.onAssign(gameState);

    gameState.apply(RegisterBearTamerDawnMessageCommand(playerIndex));
  }
}

class BearGruntScreen extends StatelessWidget {
  final int playerIndex;
  final VoidCallback onComplete;

  const BearGruntScreen({
    required this.playerIndex,
    required this.onComplete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: GameAppBar(title: Text(localizations.role_bearTamer_name)),
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

@MappableClass(discriminatorValue: 'registerBearTamerDawnMessage')
class RegisterBearTamerDawnMessageCommand
    with RegisterBearTamerDawnMessageCommandMappable
    implements GameCommand {
  const RegisterBearTamerDawnMessageCommand(this.playerIndex);

  final int playerIndex;

  @override
  void apply(GameData gameData) {
    // TODO: change to dawn message
    gameData.dayActionManager.registerAction(
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

  @override
  bool get canBeUndone => true;

  @override
  void undo(GameData gameData) {
    gameData.dayActionManager.unregisterAction(BearTamerRole);
  }
}

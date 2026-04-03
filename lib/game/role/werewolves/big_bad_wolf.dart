import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_annotations/register_role.dart' show RegisterRole;
import 'package:werewolf_narrator/game/commands/mark_dead.dart';
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/model/role_config.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/role/village/witch.dart' show WitchRole;
import 'package:werewolf_narrator/game/role/werewolves/ancient_werewolf.dart'
    show AncientWerewolfRole;
import 'package:werewolf_narrator/game/team/werewolves.dart'
    show WerewolvesDeathReason, WerewolvesTeam;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/views/game/action_screen.dart';

part 'big_bad_wolf.mapper.dart';

@RegisterRole()
class BigBadWolfRole extends Role {
  BigBadWolfRole._({
    required RoleConfiguration config,
    required super.playerIndex,
  });
  static final RoleType type = RoleType.of<BigBadWolfRole>();
  @override
  RoleType get roleType => type;

  static void registerRole() {
    RoleManager.registerRole<BigBadWolfRole>(
      type,
      RegisterRoleInformation(
        constructor: BigBadWolfRole._,
        name: _name,
        description: (context) =>
            AppLocalizations.of(context).role_bigBadWolf_description,
        initialTeam: WerewolvesTeam.type,
        checkRoleInstruction: (context, count) => AppLocalizations.of(
          context,
        ).role_bigBadWolf_checkInstruction(count: count),
        validRoleCounts: const [1],
        chooseRolesInformation: const ChooseRolesInformation(
          category: ChooseRolesCategory.werewolves,
          priority: 5,
        ),
      ),
    );
  }

  static String _name(BuildContext context) =>
      AppLocalizations.of(context).role_bigBadWolf_name;

  @override
  void onAssign(GameState gameState) {
    super.onAssign(gameState);

    gameState.apply(RegisterBigBadWolfNightActionCommand(playerIndex));
  }
}

bool werewolfHasDied(GameState gameState) => gameState.players.indexed
    .where((entry) => entry.$2.role?.team(gameState) == WerewolvesTeam.type)
    .map((entry) => entry.$1)
    .toISet()
    .intersection(gameState.knownDeadPlayerIndices)
    .isNotEmpty;

@MappableClass(discriminatorValue: 'registerBigBadWolfNightAction')
class RegisterBigBadWolfNightActionCommand
    with RegisterBigBadWolfNightActionCommandMappable
    implements GameCommand {
  const RegisterBigBadWolfNightActionCommand(this.playerIndex);

  final int playerIndex;

  @override
  void apply(GameData gameData) {
    gameData.nightActionManager.registerAction(
      BigBadWolfRole.type,
      (gameState, onComplete) => nightActionScreen(playerIndex, onComplete),
      conditioned: (gameState) =>
          gameState.playerAliveUntilDawn(playerIndex) &&
          !werewolfHasDied(gameState),
      after: IList([WerewolvesTeam.type, AncientWerewolfRole.type]),
      before: IList([WitchRole.type]),
      players: {playerIndex},
    );
  }

  @override
  bool get canBeUndone => true;

  @override
  void undo(GameData gameData) {
    gameData.nightActionManager.unregisterAction(BigBadWolfRole.type);
  }

  WidgetBuilder nightActionScreen(int playerIndex, VoidCallback onComplete) =>
      (context) {
        final localizations = AppLocalizations.of(context);
        final gameState = Provider.of<GameState>(context, listen: false);

        final werewolfIndices = WerewolvesTeam.werewolfPlayerIndices(gameState);

        final werewolvesOrDead = werewolfIndices.union(
          gameState.knownDeadPlayerIndices,
        );

        return ActionScreen(
          appBarTitle: Text(BigBadWolfRole._name(context)),
          instruction: Text(
            localizations.role_bigBadWolf_nightAction_instruction,
          ),
          actionIdentifier: BigBadWolfRole.type,
          selectionCount: 1,
          onConfirm: (selectedPlayers, gameState) {
            gameState.apply(
              MarkDeadCommand.single(
                player: selectedPlayers.single,
                deathReason: WerewolvesDeathReason(ISet({playerIndex})),
              ),
            );
            onComplete();
          },
          disabledPlayerIndices: werewolvesOrDead,
          currentActorIndices: ISet({playerIndex}),
        );
      };
}

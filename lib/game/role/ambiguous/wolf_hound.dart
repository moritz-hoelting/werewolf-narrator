import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_annotations/register_role.dart' show RegisterRole;
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart' show GameData;
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/model/role_config.dart';
import 'package:werewolf_narrator/game/model/team.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/game/team/werewolves.dart'
    show WerewolvesTeam;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/views/game/binary_selection_screen.dart';

part 'wolf_hound.mapper.dart';

@RegisterRole()
class WolfHoundRole extends Role {
  WolfHoundRole._({
    required RoleConfiguration config,
    required super.playerIndex,
  });

  static final RoleType type = RoleType.of<WolfHoundRole>();
  @override
  RoleType get roleType => type;

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
  TeamType? team(GameState gameState) => overrideTeam.getOrElse(() {
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
        chooseRolesInformation: const ChooseRolesInformation(
          category: ChooseRolesCategory.ambiguous,
          priority: 2,
        ),
      ),
    );
  }

  @override
  void onAssign(GameState gameState) {
    super.onAssign(gameState);

    gameState.apply(RegisterWolfHoundNightActionCommand(playerIndex));
  }
}

@MappableClass(discriminatorValue: 'registerWolfHoundNightAction')
class RegisterWolfHoundNightActionCommand
    with RegisterWolfHoundNightActionCommandMappable
    implements GameCommand {
  final int playerIndex;

  const RegisterWolfHoundNightActionCommand(this.playerIndex);

  @override
  void apply(GameData gameData) {
    gameData.nightActionManager.registerAction(
      WolfHoundRole.type,
      (gameState, onComplete) => nightActionScreen(playerIndex, onComplete),
      conditioned: (gameState) =>
          gameState.playerAliveUntilDawn(playerIndex) &&
          (gameState.players[playerIndex].role as WolfHoundRole)
                  .selectedWerewolf ==
              null,
      players: {playerIndex},
      before: IList([WerewolvesTeam.type]),
    );
  }

  @override
  bool get canBeUndone => true;

  @override
  void undo(GameData gameData) {
    gameData.nightActionManager.unregisterAction(WolfHoundRole.type);
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
            Provider.of<GameState>(
              context,
              listen: false,
            ).apply(WolfHoundChooseCommand(playerIndex, !selectedFirst!));
            onComplete();
          },
        );
      };
}

@MappableClass(discriminatorValue: 'wolfHoundChoose')
class WolfHoundChooseCommand
    with WolfHoundChooseCommandMappable
    implements GameCommand {
  final int playerIndex;
  final bool selectedWerewolf;

  WolfHoundChooseCommand(this.playerIndex, this.selectedWerewolf);

  Option<bool?> _previousChoice = const Option.none();

  @override
  void apply(GameData gameData) {
    final role = gameData.players[playerIndex].role as WolfHoundRole;
    _previousChoice = Option.of(role.selectedWerewolf);
    role.selectedWerewolf = selectedWerewolf;
  }

  @override
  bool get canBeUndone => _previousChoice.isSome();

  @override
  void undo(GameData gameData) {
    final role = gameData.players[playerIndex].role as WolfHoundRole;
    role.selectedWerewolf = _previousChoice.getOrElse(() => null);
    _previousChoice = const Option.none();
  }
}

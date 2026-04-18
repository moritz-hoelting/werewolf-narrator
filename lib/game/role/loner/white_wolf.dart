import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_annotations/register_role.dart' show RegisterRole;
import 'package:werewolf_narrator/game/commands/composite.dart';
import 'package:werewolf_narrator/game/commands/mark_dead.dart';
import 'package:werewolf_narrator/game/commands/register_win_condition.dart';
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/model/configuration_options.dart';
import 'package:werewolf_narrator/game/model/death_information.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/model/win_condition.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/team/werewolves.dart'
    show WerewolvesTeam, WerewolvesWinCondition;
import 'package:werewolf_narrator/game/util/solo_role.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/views/game/action_screen.dart';

part 'white_wolf.mapper.dart';

@RegisterRole()
class WhiteWolfRole extends Role {
  WhiteWolfRole._({
    required RoleConfiguration config,
    required super.playerIndex,
  }) : wakeEveryNthNight = config[wakeEveryNthNightOptionKey];
  static final RoleType type = RoleType.of<WhiteWolfRole>();
  @override
  RoleType get roleType => type;

  static const String wakeEveryNthNightOptionKey = 'wakeEveryNthNight';

  final int wakeEveryNthNight;

  static void registerRole() {
    RoleManager.registerRole<WhiteWolfRole>(
      type,
      RegisterRoleInformation(
        constructor: WhiteWolfRole._,
        name: _name,
        description: (context) =>
            AppLocalizations.of(context).role_whiteWolf_description,
        initialTeam: WerewolvesTeam.type,
        checkRoleInstruction: (context, count) => AppLocalizations.of(
          context,
        ).role_whiteWolf_checkInstruction(count: count),
        validRoleCounts: const [1],
        options: IList([
          IntOption(
            id: wakeEveryNthNightOptionKey,
            label: (context) => AppLocalizations.of(
              context,
            ).role_whiteWolf_option_wakeEveryNthNight_label,
            description: (context) => AppLocalizations.of(
              context,
            ).role_whiteWolf_option_wakeEveryNthNight_description,
            defaultValue: 2,
            min: 1,
          ),
        ]),
        chooseRolesInformation: const ChooseRolesInformation(
          category: ChooseRolesCategory.loner,
          priority: 3,
        ),
      ),
    );
  }

  @override
  void onAssign(GameState gameState) {
    super.onAssign(gameState);

    gameState.apply(
      CompositeGameCommand(
        [
          RegisterWinConditionCommand(WhiteWolfWinCondition(playerIndex)),
          OnAssignWhiteWolfCommand(
            playerIndex: playerIndex,
            wakeEveryNthNight: wakeEveryNthNight,
          ),
        ].lock,
      ),
    );
  }

  static String _name(BuildContext context) =>
      AppLocalizations.of(context).role_whiteWolf_name;
}

@MappableClass(discriminatorValue: 'whiteWolf')
class WhiteWolfWinCondition
    with WhiteWolfWinConditionMappable
    implements WinCondition {
  const WhiteWolfWinCondition(this.playerIndex);

  final int playerIndex;

  @override
  bool hasWon(GameState gameState) => soloRoleHasWon(gameState, playerIndex);

  @override
  String winningHeadline(BuildContext context) =>
      AppLocalizations.of(context).role_whiteWolf_winHeadline;

  @override
  ISet<int> winningPlayers(GameState gameState) => ISet({playerIndex});
}

@MappableClass(discriminatorValue: 'whiteWolf')
class WhiteWolfDeathReason
    with WhiteWolfDeathReasonMappable
    implements DeathReason {
  WhiteWolfDeathReason(this.playerIndex);

  final int playerIndex;

  @override
  String deathReasonDescription(BuildContext context) =>
      AppLocalizations.of(context).role_whiteWolf_deathReason;

  @override
  ISet<int> get responsiblePlayerIndices => ISet({playerIndex});
}

@MappableClass(discriminatorValue: 'onAssignWhiteWolf')
class OnAssignWhiteWolfCommand
    with OnAssignWhiteWolfCommandMappable
    implements GameCommand {
  const OnAssignWhiteWolfCommand({
    required this.playerIndex,
    required this.wakeEveryNthNight,
  });

  final int playerIndex;
  final int wakeEveryNthNight;

  @override
  void apply(GameData gameData) {
    gameData.playerWinHooks.add(playerWinHook);

    gameData.nightActionManager.registerAction(
      WhiteWolfRole,
      (gameState, onComplete) => nightActionScreen(onComplete),
      conditioned: (gameState) =>
          gameState.players[playerIndex].isAlive &&
          gameState.dayCounter % wakeEveryNthNight == 0,
      players: {playerIndex},
      after: ISet({WerewolvesTeam.type}),
    );
  }

  @override
  bool get canBeUndone => true;

  @override
  void undo(GameData gameData) {
    gameData.playerWinHooks.remove(playerWinHook);
    gameData.nightActionManager.unregisterAction(WhiteWolfRole);
  }

  bool? playerWinHook(
    GameState gameState,
    WinCondition winner,
    int playerIndex,
  ) {
    if (gameState.teams.containsKey(WerewolvesTeam.type) &&
        winner is WerewolvesWinCondition &&
        playerIndex == this.playerIndex) {
      return false;
    }
    return null;
  }

  WidgetBuilder nightActionScreen(VoidCallback onComplete) => (context) {
    final localizations = AppLocalizations.of(context);
    final gameState = Provider.of<GameState>(context, listen: false);

    final werewolfIndices = WerewolvesTeam.werewolfPlayerIndices(gameState);

    final nonWerewolvesOrDead = List.generate(gameState.playerCount, (i) => i)
        .toISet()
        .difference(werewolfIndices)
        .union(gameState.deadPlayerIndices)
        .union({playerIndex});

    return ActionScreen(
      key: UniqueKey(),
      actionIdentifier: WhiteWolfRole,
      appBarTitle: Text(WhiteWolfRole._name(context)),
      instruction: Text(
        localizations.role_whiteWolf_nightAction_instruction,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      selectionCount: 1,
      allowSelectLess: true,
      currentActorIndices: ISet({playerIndex}),
      disabledPlayerIndices: nonWerewolvesOrDead,
      onConfirm: (selectedPlayers, gameState) {
        if (selectedPlayers.isNotEmpty) {
          gameState.apply(
            MarkDeadCommand.single(
              player: selectedPlayers.single,
              deathReason: WhiteWolfDeathReason(playerIndex),
            ),
          );
        }
        onComplete();
      },
    );
  };
}

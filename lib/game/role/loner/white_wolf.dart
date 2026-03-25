import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/game/commands/mark_dead.dart';
import 'package:werewolf_narrator/game/commands/register_win_condition.dart';
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/model/death_information.dart';
import 'package:werewolf_narrator/game/model/role_config.dart';
import 'package:werewolf_narrator/game/model/win_condition.dart';
import 'package:werewolf_narrator/game/util/solo_role.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/team/werewolves.dart'
    show WerewolvesTeam;
import 'package:werewolf_narrator/views/game/action_screen.dart';

class WhiteWolfRole extends Role implements WinCondition, DeathReason {
  WhiteWolfRole._({
    required RoleConfiguration config,
    required super.playerIndex,
  }) : wakeEveryNthNight = config[wakeEveryNthNightOptionKey];
  static final RoleType<WhiteWolfRole> type = RoleType<WhiteWolfRole>();
  @override
  RoleType<WhiteWolfRole> get objectType => type;

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
        chooseRolesInformation: ChooseRolesInformation(
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
          RegisterWinConditionCommand(this),
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

  @override
  bool hasWon(GameState gameState) => soloRoleHasWon(gameState, playerIndex);

  @override
  String winningHeadline(BuildContext context) =>
      AppLocalizations.of(context).role_whiteWolf_winHeadline;

  @override
  ISet<int> winningPlayers(GameState gameState) {
    return ISet({playerIndex});
  }

  @override
  String deathReasonDescription(BuildContext context) =>
      AppLocalizations.of(context).role_whiteWolf_deathReason;

  @override
  ISet<int> get responsiblePlayerIndices => ISet({playerIndex});
}

class OnAssignWhiteWolfCommand implements GameCommand {
  const OnAssignWhiteWolfCommand({
    required this.playerIndex,
    required this.wakeEveryNthNight,
  });

  final int playerIndex;
  final int wakeEveryNthNight;

  @override
  void apply(GameData gameData) {
    gameData.playerWinHooks.add((gameState, winner, playerIndex) {
      if (gameState.teams.containsKey(WerewolvesTeam.type) &&
          winner == (gameState.teams[WerewolvesTeam.type] as WerewolvesTeam) &&
          playerIndex == this.playerIndex) {
        return false;
      }
      return null;
    });

    gameData.nightActionManager.registerAction(
      WhiteWolfRole,
      (gameState, onComplete) => nightActionScreen(onComplete),
      conditioned: (gameState) =>
          gameState.playerAliveUntilDawn(playerIndex) &&
          gameState.dayCounter % wakeEveryNthNight == 0,
      players: {playerIndex},
      after: IList([WerewolvesTeam.type]),
    );
  }

  @override
  bool get canBeUndone => false;

  @override
  void undo(GameData gameData) {
    // TODO: implement undo
    throw UnimplementedError();
  }

  WidgetBuilder nightActionScreen(VoidCallback onComplete) => (context) {
    final localizations = AppLocalizations.of(context);
    final gameState = Provider.of<GameState>(context, listen: false);

    final werewolfIndices = WerewolvesTeam.werewolfPlayerIndices(gameState);

    final nonWerewolvesOrDead = List.generate(gameState.playerCount, (i) => i)
        .toISet()
        .difference(werewolfIndices)
        .union(gameState.knownDeadPlayerIndices)
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
              deathReason: gameState.players[playerIndex].role as WhiteWolfRole,
            ),
          );
        }
        onComplete();
      },
    );
  };
}

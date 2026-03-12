import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/model/death_information.dart';
import 'package:werewolf_narrator/game/model/player.dart';
import 'package:werewolf_narrator/game/model/win_condition.dart';
import 'package:werewolf_narrator/game/util/solo_role.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/team/werewolves.dart'
    show WerewolvesTeam;
import 'package:werewolf_narrator/views/game/action_screen.dart';

class WhiteWolfRole extends Role implements WinCondition, DeathReason {
  WhiteWolfRole._();
  static final RoleType type = RoleType<WhiteWolfRole>();
  @override
  RoleType get objectType => type;

  int? playerIndex;

  static void registerRole() {
    RoleManager.registerRole<WhiteWolfRole>(
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
        chooseRolesInformation: ChooseRolesInformation(
          category: ChooseRolesCategory.loner,
          priority: 3,
        ),
      ),
    );
  }

  @override
  void onAssign(GameState gameState, int playerIndex) {
    super.onAssign(gameState, playerIndex);

    this.playerIndex = playerIndex;
    gameState.winConditions.add(this);

    gameState.playerWinHooks.add((gameState, winner, playerIndex) {
      if (gameState.teams.containsKey(WerewolvesTeam.type) &&
          winner == (gameState.teams[WerewolvesTeam.type] as WerewolvesTeam) &&
          playerIndex == this.playerIndex) {
        return false;
      }
      return null;
    });

    gameState.nightActionManager.registerAction(
      WhiteWolfRole,
      (gameState, onComplete) => nightActionScreen(onComplete),
      conditioned: (gameState) =>
          gameState.playerAliveUntilDawn(playerIndex) &&
          gameState.dayCounter % 2 == 0,
      players: {playerIndex},
      after: IList([WerewolvesTeam.type]),
    );
  }

  static String _name(BuildContext context) =>
      AppLocalizations.of(context).role_whiteWolf_name;

  @override
  bool hasWon(GameState gameState) => soloRoleHasWon(gameState, playerIndex!);

  @override
  String winningHeadline(BuildContext context) =>
      AppLocalizations.of(context).role_whiteWolf_winHeadline;

  @override
  List<(int, Player)> winningPlayers(GameState gameState) {
    return [(playerIndex!, gameState.players[playerIndex!])];
  }

  WidgetBuilder nightActionScreen(VoidCallback onComplete) => (context) {
    final localizations = AppLocalizations.of(context);
    final gameState = Provider.of<GameState>(context, listen: false);

    final werewolfIndices = WerewolvesTeam.werewolfPlayerIndices(gameState);

    final nonWerewolvesOrDead = List.generate(gameState.playerCount, (i) => i)
        .toISet()
        .difference(werewolfIndices)
        .union(gameState.knownDeadPlayerIndices)
        .union({playerIndex!});

    return ActionScreen(
      key: UniqueKey(),
      actionIdentifier: WhiteWolfRole,
      appBarTitle: Text(_name(context)),
      instruction: Text(
        localizations.role_whiteWolf_nightAction_instruction,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      selectionCount: 1,
      allowSelectLess: true,
      currentActorIndices: ISet({playerIndex!}),
      disabledPlayerIndices: nonWerewolvesOrDead,
      onConfirm: (selectedPlayers, gameState) {
        gameState.markPlayerDead(selectedPlayers.single, this);
        onComplete();
      },
    );
  };

  @override
  String deathReasonDescription(BuildContext context) =>
      AppLocalizations.of(context).role_whiteWolf_deathReason;

  @override
  ISet<int> get responsiblePlayerIndices => ISet({playerIndex!});
}

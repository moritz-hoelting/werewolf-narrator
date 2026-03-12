import 'package:flutter/material.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/model/player.dart';
import 'package:werewolf_narrator/game/model/win_condition.dart';
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';

class AngelRole extends Role implements WinCondition {
  AngelRole._();
  static final RoleType type = RoleType<AngelRole>();
  @override
  RoleType get objectType => type;

  int? playerIndex;

  static void registerRole() {
    RoleManager.registerRole<AngelRole>(
      RegisterRoleInformation(
        constructor: AngelRole._,
        name: _name,
        description: (context) =>
            AppLocalizations.of(context).role_angel_description,
        initialTeam: VillageTeam.type,
        checkRoleInstruction: (context, count) => AppLocalizations.of(
          context,
        ).role_angel_checkInstruction(count: count),
        validRoleCounts: const [1],
        requireStartGameWithDay: true,
        chooseRolesInformation: ChooseRolesInformation(
          category: ChooseRolesCategory.loner,
          priority: 1,
        ),
      ),
    );
  }

  @override
  void onAssign(GameState gameState, int playerIndex) {
    super.onAssign(gameState, playerIndex);

    this.playerIndex = playerIndex;
    gameState.winConditions.add(this);
  }

  static String _name(BuildContext context) =>
      AppLocalizations.of(context).role_angel_name;

  @override
  bool hasWon(GameState gameState) =>
      playerIndex != null &&
      gameState.players[playerIndex!].deathInformation?.day == 0;

  @override
  String winningHeadline(BuildContext context) =>
      AppLocalizations.of(context).role_angel_winHeadline;

  @override
  List<(int, Player)> winningPlayers(GameState gameState) {
    return [(playerIndex!, gameState.players[playerIndex!])];
  }
}

import 'package:werewolf_annotations/register_role.dart' show RegisterRole;
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:werewolf_narrator/game/commands/register_win_condition.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/model/role_config.dart';
import 'package:werewolf_narrator/game/model/win_condition.dart';
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';

@RegisterRole()
class AngelRole extends Role implements WinCondition {
  AngelRole._({required RoleConfiguration config, required super.playerIndex});
  static final RoleType<AngelRole> type = RoleType<AngelRole>();
  @override
  RoleType<AngelRole> get objectType => type;

  static void registerRole() {
    RoleManager.registerRole<AngelRole>(
      type,
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
  void onAssign(GameState gameState) {
    super.onAssign(gameState);

    gameState.apply(RegisterWinConditionCommand(this));
  }

  static String _name(BuildContext context) =>
      AppLocalizations.of(context).role_angel_name;

  @override
  bool hasWon(GameState gameState) =>
      gameState.players[playerIndex].deathInformation?.day == 0;

  @override
  String winningHeadline(BuildContext context) =>
      AppLocalizations.of(context).role_angel_winHeadline;

  @override
  ISet<int> winningPlayers(GameState gameState) => ISet({playerIndex});
}

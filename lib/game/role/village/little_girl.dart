import 'package:flutter/material.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/model/team.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;

class LittleGirlRole extends Role {
  LittleGirlRole._();
  static final RoleType type = RoleType<LittleGirlRole>();
  @override
  RoleType get objectType => type;

  static final Role instance = LittleGirlRole._();

  static void registerRole() {
    RoleManager.registerRole<LittleGirlRole>(
      RegisterRoleInformation(LittleGirlRole._, instance),
    );
  }

  @override
  bool get isUnique => true;
  @override
  TeamType get initialTeam => VillageTeam.type;

  @override
  String name(BuildContext context) {
    return AppLocalizations.of(context).role_littleGirl_name;
  }

  @override
  String description(BuildContext context) {
    return AppLocalizations.of(context).role_littleGirl_description;
  }

  @override
  String checkRoleInstruction(BuildContext context, int count) {
    final localizations = AppLocalizations.of(context);
    return localizations.role_littleGirl_checkInstruction(count: count);
  }
}

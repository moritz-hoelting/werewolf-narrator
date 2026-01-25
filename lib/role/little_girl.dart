import 'package:flutter/material.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/model/role.dart';
import 'package:werewolf_narrator/model/team.dart';
import 'package:werewolf_narrator/role/role.dart';
import 'package:werewolf_narrator/team/village.dart' show VillageTeam;

class LittleGirlRole extends Role {
  const LittleGirlRole._();
  static final RoleType type = RoleType<LittleGirlRole>();
  @override
  RoleType get objectType => type;

  static const Role instance = LittleGirlRole._();

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
    return AppLocalizations.of(context)!.role_littleGirl_name;
  }

  @override
  String description(BuildContext context) {
    return AppLocalizations.of(context)!.role_littleGirl_description;
  }

  @override
  String checkRoleInstruction(BuildContext context, int count) {
    final localizations = AppLocalizations.of(context)!;
    return localizations.screen_checkRoles_instruction_littleGirl(count);
  }
}

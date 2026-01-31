import 'package:flutter/material.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/model/role.dart';
import 'package:werewolf_narrator/model/team.dart';
import 'package:werewolf_narrator/role/role.dart';
import 'package:werewolf_narrator/team/village.dart' show VillageTeam;

class VillagerRole extends Role {
  const VillagerRole._();
  static final RoleType type = RoleType<VillagerRole>();
  @override
  RoleType get objectType => type;

  static const Role instance = VillagerRole._();

  static void registerRole() {
    RoleManager.registerRole<VillagerRole>(
      RegisterRoleInformation(VillagerRole._, instance),
    );
  }

  @override
  bool get isUnique => false;
  @override
  TeamType get initialTeam => VillageTeam.type;

  @override
  String name(BuildContext context) {
    return AppLocalizations.of(context).role_villager_name;
  }

  @override
  String description(BuildContext context) {
    return AppLocalizations.of(context).role_villager_description;
  }

  @override
  String checkRoleInstruction(BuildContext context, int count) {
    throw UnimplementedError('Villager has no check role screen');
  }
}

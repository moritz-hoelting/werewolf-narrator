import 'package:flutter/material.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/model/team.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/l10n/app_localizations.dart';

class TwoSistersRole extends Role {
  TwoSistersRole._();
  static final RoleType type = RoleType<TwoSistersRole>();
  @override
  RoleType get objectType => type;

  static final Role instance = TwoSistersRole._();

  static void registerRole() {
    RoleManager.registerRole<TwoSistersRole>(
      RegisterRoleInformation(TwoSistersRole._, instance),
    );
  }

  @override
  Iterable<int> get validRoleCounts => const [2];
  @override
  TeamType get initialTeam => VillageTeam.type;

  @override
  String name(BuildContext context) {
    return AppLocalizations.of(context).role_twoSisters_name;
  }

  @override
  String description(BuildContext context) {
    return AppLocalizations.of(context).role_twoSisters_description;
  }

  @override
  String checkRoleInstruction(BuildContext context, int count) {
    return AppLocalizations.of(
      context,
    ).role_twoSisters_checkInstruction(count: count);
  }
}

import 'package:flutter/material.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/model/role.dart';
import 'package:werewolf_narrator/model/team.dart';
import 'package:werewolf_narrator/role/role.dart';
import 'package:werewolf_narrator/team/werewolves.dart' show WerewolvesTeam;

class WerewolfRole extends Role {
  const WerewolfRole._();
  static final RoleType type = RoleType<WerewolfRole>();
  @override
  RoleType get objectType => type;

  static const Role instance = WerewolfRole._();

  static void registerRole() {
    RoleManager.registerRole<WerewolfRole>(
      RegisterRoleInformation(WerewolfRole._, instance),
    );
  }

  @override
  bool get isUnique => false;
  @override
  TeamType get initialTeam => WerewolvesTeam.type;

  @override
  String name(BuildContext context) {
    return AppLocalizations.of(context)!.role_werewolf_name;
  }

  @override
  String description(BuildContext context) {
    return AppLocalizations.of(context)!.role_werewolf_description;
  }

  @override
  String checkRoleInstruction(BuildContext context, int count) {
    final localizations = AppLocalizations.of(context)!;
    return localizations.team_werewolves_checkInstruction(count);
  }
}

part of 'role.dart';

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

  // TODO: team night action

  @override
  bool get isUnique => false;
  @override
  Team get initialTeam => Team.werewolves;

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
    return localizations.screen_checkRoles_instruction_werewolf(count);
  }
}

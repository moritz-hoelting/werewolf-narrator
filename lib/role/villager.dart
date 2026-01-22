part of 'role.dart';

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
  Team get initialTeam => Team.village;

  @override
  String name(BuildContext context) {
    return AppLocalizations.of(context)!.role_villager_name;
  }

  @override
  String description(BuildContext context) {
    return AppLocalizations.of(context)!.role_villager_description;
  }

  @override
  String checkRoleInstruction(BuildContext context, int count) {
    throw UnimplementedError('Villager has no check role screen');
  }
}

import 'package:werewolf_narrator/game/model/role_config.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/util/iterable.dart';

class VillagerRole extends Role {
  VillagerRole._({
    required RoleConfiguration config,
    required super.playerIndex,
  });
  static final RoleType<VillagerRole> type = RoleType<VillagerRole>();
  @override
  RoleType<VillagerRole> get objectType => type;

  static void registerRole() {
    RoleManager.registerRole<VillagerRole>(
      type,
      RegisterRoleInformation(
        constructor: VillagerRole._,
        name: (context) => AppLocalizations.of(context).role_villager_name,
        description: (context) =>
            AppLocalizations.of(context).role_villager_description,
        initialTeam: VillageTeam.type,
        checkRoleInstruction: (context, count) =>
            throw UnimplementedError('Villager has no check role screen'),
        validRoleCounts: infiniteIterableStartingAt(1),
        chooseRolesInformation: ChooseRolesInformation(
          category: ChooseRolesCategory.village,
          priority: 1000,
        ),
      ),
    );
  }
}

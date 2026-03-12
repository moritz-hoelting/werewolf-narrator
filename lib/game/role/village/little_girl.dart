import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;

class LittleGirlRole extends Role {
  LittleGirlRole._();
  static final RoleType type = RoleType<LittleGirlRole>();
  @override
  RoleType get objectType => type;

  static void registerRole() {
    RoleManager.registerRole<LittleGirlRole>(
      RegisterRoleInformation(
        constructor: LittleGirlRole._,
        name: (context) => AppLocalizations.of(context).role_littleGirl_name,
        description: (context) =>
            AppLocalizations.of(context).role_littleGirl_description,
        initialTeam: VillageTeam.type,
        checkRoleInstruction: (context, count) => AppLocalizations.of(
          context,
        ).role_littleGirl_checkInstruction(count: count),
        validRoleCounts: const [1],
        chooseRolesInformation: ChooseRolesInformation(
          category: ChooseRolesCategory.village,
          priority: 35,
        ),
      ),
    );
  }
}

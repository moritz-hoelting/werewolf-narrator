import 'package:werewolf_annotations/register_role.dart' show RegisterRole;
import 'package:werewolf_narrator/game/model/configuration_options.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/l10n/app_localizations.dart';

@RegisterRole()
class LittleGirlRole extends Role {
  LittleGirlRole._({
    required RoleConfiguration config,
    required super.playerIndex,
  });
  static final RoleType type = RoleType.of<LittleGirlRole>();
  @override
  RoleType get roleType => type;

  static void registerRole() {
    RoleManager.registerRole<LittleGirlRole>(
      type,
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
        chooseRolesInformation: const ChooseRolesInformation(
          category: ChooseRolesCategory.village,
          priority: 35,
        ),
      ),
    );
  }
}

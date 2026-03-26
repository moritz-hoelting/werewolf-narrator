import 'package:werewolf_annotations/register_role.dart' show RegisterRole;
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/model/role_config.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/l10n/app_localizations.dart';

@RegisterRole()
class TwoSistersRole extends Role {
  TwoSistersRole._({
    required RoleConfiguration config,
    required super.playerIndex,
  });
  static final RoleType<TwoSistersRole> type = RoleType<TwoSistersRole>();
  @override
  RoleType<TwoSistersRole> get objectType => type;

  static void registerRole() {
    RoleManager.registerRole<TwoSistersRole>(
      type,
      RegisterRoleInformation(
        constructor: TwoSistersRole._,
        name: (context) => AppLocalizations.of(context).role_twoSisters_name,
        description: (context) =>
            AppLocalizations.of(context).role_twoSisters_description,
        initialTeam: VillageTeam.type,
        checkRoleInstruction: (context, count) => AppLocalizations.of(
          context,
        ).role_twoSisters_checkInstruction(count: count),
        validRoleCounts: const [2],
        chooseRolesInformation: ChooseRolesInformation(
          category: ChooseRolesCategory.village,
          priority: 40,
        ),
      ),
    );
  }
}

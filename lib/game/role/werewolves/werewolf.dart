import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/team/werewolves.dart'
    show WerewolvesTeam;
import 'package:werewolf_narrator/util/iterable.dart';

class WerewolfRole extends Role {
  WerewolfRole._();
  static final RoleType type = RoleType<WerewolfRole>();
  @override
  RoleType get objectType => type;

  static void registerRole() {
    RoleManager.registerRole<WerewolfRole>(
      RegisterRoleInformation(
        constructor: WerewolfRole._,
        name: (context) => AppLocalizations.of(context).role_werewolf_name,
        description: (context) =>
            AppLocalizations.of(context).role_werewolf_description,
        initialTeam: WerewolvesTeam.type,
        checkRoleInstruction: (context, count) => throw UnimplementedError(
          'Werewolf has no individual check role screen',
        ),
        validRoleCounts: infiniteIterableStartingAt(1),
        chooseRolesInformation: ChooseRolesInformation(
          category: ChooseRolesCategory.werewolves,
          priority: 1000,
        ),
      ),
    );
  }
}

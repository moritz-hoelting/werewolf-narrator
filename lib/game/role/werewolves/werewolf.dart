import 'package:werewolf_annotations/register_role.dart' show RegisterRole;
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/model/role_config.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/team/werewolves.dart'
    show WerewolvesTeam;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/util/iterable.dart';

@RegisterRole()
class WerewolfRole extends Role {
  WerewolfRole._({
    required RoleConfiguration config,
    required super.playerIndex,
  });
  static final RoleType type = RoleType.of<WerewolfRole>();
  @override
  RoleType get roleType => type;

  static void registerRole() {
    RoleManager.registerRole<WerewolfRole>(
      type,
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
        chooseRolesInformation: const ChooseRolesInformation(
          category: ChooseRolesCategory.werewolves,
          priority: 1000,
        ),
      ),
    );
  }
}

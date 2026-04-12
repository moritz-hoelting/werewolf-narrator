import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_annotations/register_role.dart' show RegisterRole;
import 'package:werewolf_narrator/game/commands/mark_dead.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/model/configuration_options.dart';
import 'package:werewolf_narrator/game/model/death_information.dart'
    show DeathReason, DeathReasonMapper;
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/views/game/action_screen.dart';

part 'hunter.mapper.dart';

@RegisterRole()
class HunterRole extends Role {
  HunterRole._({required RoleConfiguration config, required super.playerIndex});
  static final RoleType type = RoleType.of<HunterRole>();
  @override
  RoleType get roleType => type;

  static void registerRole() {
    RoleManager.registerRole<HunterRole>(
      type,
      RegisterRoleInformation(
        constructor: HunterRole._,
        name: (context) => AppLocalizations.of(context).role_hunter_name,
        description: (context) =>
            AppLocalizations.of(context).role_hunter_description,
        initialTeam: VillageTeam.type,
        checkRoleInstruction: (context, count) => AppLocalizations.of(
          context,
        ).role_hunter_checkInstruction(count: count),
        validRoleCounts: const [1],
        chooseRolesInformation: const ChooseRolesInformation(
          category: ChooseRolesCategory.village,
          priority: 5,
        ),
      ),
    );
  }

  @override
  bool hasDeathScreen(GameState gameState) => true;
  @override
  WidgetBuilder? deathActionScreen(VoidCallback onComplete, int playerIndex) =>
      (context) =>
          HunterScreen(playerIndex: playerIndex, onPhaseComplete: onComplete);
}

@MappableClass(discriminatorValue: 'hunter')
class HunterDeathReason with HunterDeathReasonMappable implements DeathReason {
  const HunterDeathReason(this.playerIndex);

  final int playerIndex;

  @override
  String deathReasonDescription(BuildContext context) =>
      AppLocalizations.of(context).role_hunter_deathReason;

  @override
  ISet<int> get responsiblePlayerIndices => ISet({playerIndex});
}

class HunterScreen extends StatelessWidget {
  final int playerIndex;
  final VoidCallback onPhaseComplete;

  const HunterScreen({
    required this.playerIndex,
    required this.onPhaseComplete,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Consumer<GameState>(
    builder: (context, gameState, _) {
      final localizations = AppLocalizations.of(context);

      return ActionScreen(
        appBarTitle: Text(localizations.role_hunter_name),
        instruction: Text(
          localizations.role_hunter_deathAction_instruction,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actionIdentifier: HunterRole.type,
        currentActorIndices: ISet({playerIndex}),
        disabledPlayerIndices: ISet({playerIndex}),
        selectionCount: 1,
        onConfirm: (selectedPlayers, gameState) {
          gameState.apply(
            MarkDeadCommand.single(
              player: selectedPlayers.single,
              deathReason: HunterDeathReason(playerIndex),
            ),
          );
          onPhaseComplete();
        },
      );
    },
  );
}

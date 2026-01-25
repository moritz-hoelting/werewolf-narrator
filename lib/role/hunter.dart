import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/model/death_information.dart';
import 'package:werewolf_narrator/model/role.dart';
import 'package:werewolf_narrator/model/team.dart';
import 'package:werewolf_narrator/role/role.dart';
import 'package:werewolf_narrator/state/game.dart';
import 'package:werewolf_narrator/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/views/game/action_screen.dart';

class HunterRole extends Role {
  const HunterRole._();
  static final RoleType type = RoleType<HunterRole>();
  @override
  RoleType get objectType => type;

  static const Role instance = HunterRole._();

  static void registerRole() {
    RoleManager.registerRole<HunterRole>(
      RegisterRoleInformation(HunterRole._, instance),
    );
  }

  @override
  bool get isUnique => true;
  @override
  TeamType get initialTeam => VillageTeam.type;

  @override
  String name(BuildContext context) {
    return AppLocalizations.of(context)!.role_hunter_name;
  }

  @override
  String description(BuildContext context) {
    return AppLocalizations.of(context)!.role_hunter_description;
  }

  @override
  String checkRoleInstruction(BuildContext context, int count) {
    final localizations = AppLocalizations.of(context)!;
    return localizations.screen_checkRoles_instruction_hunter(count);
  }

  @override
  bool hasDeathScreen(GameState gameState) => true;
  @override
  WidgetBuilder? deathActionScreen(VoidCallback onComplete, int playerIndex) {
    return (context) =>
        HunterScreen(onPhaseComplete: onComplete, playerIndex: playerIndex);
  }
}

class HunterScreen extends StatelessWidget {
  final int playerIndex;
  final VoidCallback onPhaseComplete;

  const HunterScreen({
    super.key,
    required this.playerIndex,
    required this.onPhaseComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        final localizations = AppLocalizations.of(context)!;

        return ActionScreen(
          appBarTitle: Text(localizations.role_hunter_name),
          instruction: Text(
            localizations.screen_roleAction_instruction_hunter,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          disabledPlayerIndices: {playerIndex},
          selectionCount: 1,
          onConfirm: (selectedPlayers, gameState) {
            assert(
              selectedPlayers.length == 1,
              'Hunter must select exactly one player to shoot.',
            );
            gameState.markPlayerDead(selectedPlayers.first, DeathReason.hunter);
            onPhaseComplete();
          },
        );
      },
    );
  }
}

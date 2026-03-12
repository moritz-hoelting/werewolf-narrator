import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/death_information.dart'
    show DeathReason;
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/views/game/action_screen.dart';

class HunterRole extends Role implements DeathReason {
  HunterRole._();
  static final RoleType type = RoleType<HunterRole>();
  @override
  RoleType get objectType => type;

  int? playerIndex;

  static void registerRole() {
    RoleManager.registerRole<HunterRole>(
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
      ),
    );
  }

  @override
  void onAssign(GameState gameState, int playerIndex) {
    super.onAssign(gameState, playerIndex);

    this.playerIndex = playerIndex;
  }

  @override
  String deathReasonDescription(BuildContext context) =>
      AppLocalizations.of(context).role_hunter_deathReason;

  @override
  ISet<int> get responsiblePlayerIndices => ISet({playerIndex!});

  @override
  bool hasDeathScreen(GameState gameState) => true;
  @override
  WidgetBuilder? deathActionScreen(VoidCallback onComplete, int playerIndex) {
    return (context) => HunterScreen(
      playerIndex: playerIndex,
      hunterRole: this,
      onPhaseComplete: onComplete,
    );
  }
}

class HunterScreen extends StatelessWidget {
  final int playerIndex;
  final HunterRole hunterRole;
  final VoidCallback onPhaseComplete;

  const HunterScreen({
    super.key,
    required this.playerIndex,
    required this.hunterRole,
    required this.onPhaseComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        final localizations = AppLocalizations.of(context);

        return ActionScreen(
          appBarTitle: Text(localizations.role_hunter_name),
          instruction: Text(
            localizations.role_hunter_deathAction_instruction,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          currentActorIndices: ISet({playerIndex}),
          disabledPlayerIndices: ISet({playerIndex}),
          selectionCount: 1,
          onConfirm: (selectedPlayers, gameState) {
            gameState.markPlayerDead(selectedPlayers.single, hunterRole);
            onPhaseComplete();
          },
        );
      },
    );
  }
}

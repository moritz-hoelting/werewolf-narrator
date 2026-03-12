import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/model/player.dart' show Player;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/team/werewolves.dart'
    show WerewolvesTeam, WerewolvesDeathReason;
import 'package:werewolf_narrator/views/game/binary_selection_screen.dart';
import 'package:werewolf_narrator/widgets/bottom_continue_button.dart';

class AncientWerewolfRole extends Role {
  AncientWerewolfRole._();
  static final RoleType type = RoleType<AncientWerewolfRole>();
  @override
  RoleType get objectType => type;

  int? convertedPlayerIndex;

  static void registerRole() {
    RoleManager.registerRole<AncientWerewolfRole>(
      RegisterRoleInformation(
        constructor: AncientWerewolfRole._,
        name: (context) =>
            AppLocalizations.of(context).role_ancientWerewolf_name,
        description: (context) =>
            AppLocalizations.of(context).role_ancientWerewolf_description,
        initialTeam: WerewolvesTeam.type,
        checkRoleInstruction: (context, count) => AppLocalizations.of(
          context,
        ).role_ancientWerewolf_checkInstruction(count: count),
        validRoleCounts: const [1],
      ),
    );
  }

  @override
  void onAssign(GameState gameState, int playerIndex) {
    super.onAssign(gameState, playerIndex);

    gameState.nightActionManager.registerAction(
      AncientWerewolfRole.type,
      (gameState, onComplete) =>
          (context) => AncientWerewolfScreen(
            ancientWerewolfRole: this,
            playerIndex: playerIndex,
            onPhaseComplete: onComplete,
          ),
      conditioned: (gameState) => gameState.playerAliveUntilDawn(playerIndex),
      after: [WerewolvesTeam.type],
      players: {playerIndex},
    );
  }
}

class AncientWerewolfScreen extends StatelessWidget {
  const AncientWerewolfScreen({
    super.key,
    required this.ancientWerewolfRole,
    required this.playerIndex,
    required this.onPhaseComplete,
  });

  final AncientWerewolfRole ancientWerewolfRole;
  final int playerIndex;
  final VoidCallback onPhaseComplete;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final localizations = AppLocalizations.of(context);

        if (ancientWerewolfRole.convertedPlayerIndex != null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(localizations.role_ancientWerewolf_name),
              automaticallyImplyLeading: false,
            ),
            body: Center(
              child: Text(
                localizations.role_ancientWerewolf_nightAction_hasUsedAbility,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            bottomNavigationBar: BottomContinueButton(
              onPressed: () {
                submit(gameState, false);
              },
            ),
          );
        }

        return BinarySelectionScreen(
          key: UniqueKey(),
          appBarTitle: Text(localizations.role_ancientWerewolf_name),
          instruction: Text(
            localizations.role_ancientWerewolf_nightAction_instruction(
              playerName: findLastAttackedPlayer(gameState)?.$2.name ?? "?",
            ),
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          firstOption: Text(localizations.button_yesLabel),
          secondOption: Text(localizations.button_noLabel),
          onComplete: (selectedFirst) {
            submit(gameState, selectedFirst!);
          },
        );
      },
    );
  }

  void submit(GameState gameState, bool selectedFirst) {
    if (selectedFirst) {
      final lastAttackedPlayer = findLastAttackedPlayer(gameState);
      if (lastAttackedPlayer != null) {
        useAbilityOn(gameState, lastAttackedPlayer.$1, lastAttackedPlayer.$2);
      }
    }
    onPhaseComplete();
  }

  (int, Player)? findLastAttackedPlayer(GameState gameState) {
    final lastAttackedPlayerIndex = gameState.currentCycleDeaths.entries
        .where((entry) => entry.value is WerewolvesDeathReason)
        .map((entry) => entry.key)
        .lastOrNull;
    if (lastAttackedPlayerIndex == null) {
      return null;
    }
    final player = gameState.players[lastAttackedPlayerIndex];
    return (lastAttackedPlayerIndex, player);
  }

  void useAbilityOn(GameState gameState, int playerIndex, Player player) {
    gameState.markPlayerRevived(playerIndex);
    player.role?.overrideTeam = WerewolvesTeam.type;
    ancientWerewolfRole.convertedPlayerIndex = playerIndex;
  }
}

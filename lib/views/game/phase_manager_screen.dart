import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/model/death_information.dart';
import 'package:werewolf_narrator/role/role.dart';
import 'package:werewolf_narrator/state/game.dart';
import 'package:werewolf_narrator/state/game_phase.dart';
import 'package:werewolf_narrator/views/game/action_screen.dart';
import 'package:werewolf_narrator/views/game/dawn.dart';
import 'package:werewolf_narrator/views/game/dusk.dart';
import 'package:werewolf_narrator/views/game/check_role_screen.dart';
import 'package:werewolf_narrator/views/game/game_over_screen.dart';
import 'package:werewolf_narrator/views/game/sheriff_election_screen.dart';
import 'package:werewolf_narrator/views/game/village_vote_screen.dart';

class GamePhaseScreen extends StatelessWidget {
  final GamePhase phase;
  final VoidCallback onPhaseComplete;

  const GamePhaseScreen({
    super.key,
    required this.phase,
    required this.onPhaseComplete,
  });

  @override
  Widget build(BuildContext context) {
    switch (phase) {
      case GamePhase.dusk:
        return DuskScreen(
          key: ValueKey(phase),
          onPhaseComplete: onPhaseComplete,
        );
      case GamePhase.checkRoleSeer:
        return CheckRoleScreen(
          key: ValueKey(phase),
          role: SeerRole.type,
          onPhaseComplete: onPhaseComplete,
        );
      case GamePhase.checkRoleCupid:
        return CheckRoleScreen(
          key: ValueKey(phase),
          role: CupidRole.type,
          onPhaseComplete: onPhaseComplete,
        );
      case GamePhase.checkRoleHunter:
        return CheckRoleScreen(
          key: ValueKey(phase),
          role: HunterRole.type,
          onPhaseComplete: onPhaseComplete,
        );
      case GamePhase.checkRoleWitch:
        return CheckRoleScreen(
          key: ValueKey(phase),
          role: WitchRole.type,
          onPhaseComplete: onPhaseComplete,
        );
      case GamePhase.checkRoleLittleGirl:
        return CheckRoleScreen(
          key: ValueKey(phase),
          role: LittleGirlRole.type,
          onPhaseComplete: onPhaseComplete,
        );
      case GamePhase.checkRoleWerewolves:
        return CheckRoleScreen(
          key: ValueKey(phase),
          role: WerewolfRole.type,
          onPhaseComplete: onPhaseComplete,
        );
      case GamePhase.checkRoleThief:
        return CheckRoleScreen(
          key: ValueKey(phase),
          role: ThiefRole.type,
          onPhaseComplete: onPhaseComplete,
        );
      case GamePhase.thief:
        return ThiefScreen(onPhaseComplete: onPhaseComplete);
      case GamePhase.cupid:
        final cupid = Provider.of<GameState>(
          context,
          listen: false,
        ).getRoleTypePlayer<CupidRole>()!.$2.role!;
        return cupid.nightActionScreen(onPhaseComplete)!(context);
      case GamePhase.lovers:
        return WakeLoversScreen(onPhaseComplete: onPhaseComplete);
      case GamePhase.seer:
        return SeerScreen(onPhaseComplete: onPhaseComplete);
      case GamePhase.werewolves:
        final localizations = AppLocalizations.of(context)!;
        final werewolvesOrDead = Provider.of<GameState>(context, listen: false)
            .players
            .indexed
            .where(
              (player) => player.$2.role is WerewolfRole || !player.$2.isAlive,
            )
            .map((player) => player.$1)
            .toList();
        return ActionScreen(
          appBarTitle: Text(localizations.role_werewolf_name),
          instruction: Text(
            localizations.screen_roleAction_instruction_werewolf,
          ),
          selectionCount: 1,
          disabledPlayerIndices: werewolvesOrDead,
          onConfirm: (selectedPlayers, gameState) {
            gameState.markPlayerDead(selectedPlayers[0], DeathReason.werewolf);
            onPhaseComplete();
          },
        );
      case GamePhase.witch:
        final gameState = Provider.of<GameState>(context, listen: false);
        return WitchScreen(
          onPhaseComplete: onPhaseComplete,
          hasHealPotion: gameState.witchHasHealPotion,
          hasKillPotion: gameState.witchHasKillPotion,
        );
      case GamePhase.dawn:
        return DawnScreen(onPhaseComplete: onPhaseComplete);
      case GamePhase.sheriffElection:
        return SheriffElectionScreen(onPhaseComplete: onPhaseComplete);
      case GamePhase.voting:
        return VillageVoteScreen(onPhaseComplete: onPhaseComplete);
      case GamePhase.gameOver:
        return GameOverScreen();
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/state/game.dart';
import 'package:werewolf_narrator/state/game_phase.dart';
import 'package:werewolf_narrator/views/game/dawn.dart';
import 'package:werewolf_narrator/views/game/dusk.dart';
import 'package:werewolf_narrator/views/game/check_roles_screen.dart';
import 'package:werewolf_narrator/views/game/game_over_screen.dart';
import 'package:werewolf_narrator/views/game/night_actions_screen.dart';
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
      case GamePhase.checkRoles:
        return CheckRolesScreen(
          key: ValueKey(phase),
          onPhaseComplete: () {
            Provider.of<GameState>(
              context,
              listen: false,
            ).nightActionManager.orderActions();
            onPhaseComplete();
          },
        );
      case GamePhase.nightActions:
        return NightActionsScreen(onAllActionsComplete: onPhaseComplete);
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

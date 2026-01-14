import 'package:flutter/material.dart';
import 'package:werewolf_narrator/model/role.dart';
import 'package:werewolf_narrator/state/game.dart';
import 'package:werewolf_narrator/views/game/action_screen.dart';
import 'package:werewolf_narrator/views/game/dawn.dart';
import 'package:werewolf_narrator/views/game/dusk.dart';
import 'package:werewolf_narrator/views/game/check_role_screen.dart';
import 'package:werewolf_narrator/views/game/seer_screen.dart';
import 'package:werewolf_narrator/views/game/village_vote_screen.dart';
import 'package:werewolf_narrator/views/game/wake_lovers_screen.dart';
import 'package:werewolf_narrator/views/game/witch_screen.dart';

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
          role: Role.seer,
          onPhaseComplete: onPhaseComplete,
        );
      case GamePhase.checkRoleCupid:
        return CheckRoleScreen(
          key: ValueKey(phase),
          role: Role.cupid,
          onPhaseComplete: onPhaseComplete,
        );
      case GamePhase.checkRoleHunter:
        return CheckRoleScreen(
          key: ValueKey(phase),
          role: Role.hunter,
          onPhaseComplete: onPhaseComplete,
        );
      case GamePhase.checkRoleWitch:
        return CheckRoleScreen(
          key: ValueKey(phase),
          role: Role.witch,
          onPhaseComplete: onPhaseComplete,
        );
      case GamePhase.checkRoleWerewolves:
        return CheckRoleScreen(
          key: ValueKey(phase),
          role: Role.werewolf,
          onPhaseComplete: onPhaseComplete,
        );
      case GamePhase.cupid:
        return ActionScreen(
          key: ValueKey(phase),
          role: Role.cupid,
          onPhaseComplete: onPhaseComplete,
        );
      case GamePhase.lovers:
        return WakeLoversScreen(onPhaseComplete: onPhaseComplete);
      case GamePhase.seer:
        return SeerScreen(onPhaseComplete: onPhaseComplete);
      case GamePhase.werewolves:
        return ActionScreen(
          key: ValueKey(phase),
          role: Role.werewolf,
          onPhaseComplete: onPhaseComplete,
        );
      case GamePhase.witch:
        return WitchScreen(onPhaseComplete: onPhaseComplete);
      case GamePhase.dawn:
        return DawnScreen(onPhaseComplete: onPhaseComplete);
      case GamePhase.voting:
        return VillageVoteScreen(onPhaseComplete: onPhaseComplete);
    }
  }
}

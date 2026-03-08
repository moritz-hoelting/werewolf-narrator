import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/model/player.dart' show Player;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/team/werewolves.dart'
    show WerewolvesTeam, WerewolvesDeathReason;
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

class AncientWerewolfScreen extends StatefulWidget {
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
  State<AncientWerewolfScreen> createState() => _AncientWerewolfScreenState();
}

class _AncientWerewolfScreenState extends State<AncientWerewolfScreen> {
  bool? _selectionFirst;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final localizations = AppLocalizations.of(context);

        return Scaffold(
          appBar: AppBar(
            title: Text(localizations.role_ancientWerewolf_name),
            automaticallyImplyLeading: false,
          ),
          body: widget.ancientWerewolfRole.convertedPlayerIndex != null
              ? Center(
                  child: Text(
                    localizations
                        .role_ancientWerewolf_nightAction_hasUsedAbility,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        localizations
                            .role_ancientWerewolf_nightAction_instruction(
                              playerName:
                                  findLastAttackedPlayer(gameState)?.$2.name ??
                                  "?",
                            ),
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectionFirst = true;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(150, 150),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                            backgroundColor: _selectionFirst == true
                                ? Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.5)
                                : null,
                            elevation: 4,
                          ),
                          child: Text(localizations.button_yesLabel),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectionFirst = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(150, 150),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                            backgroundColor: _selectionFirst == false
                                ? Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.5)
                                : null,
                            elevation: 4,
                          ),
                          child: Text(localizations.button_noLabel),
                        ),
                      ],
                    ),
                  ],
                ),
          bottomNavigationBar: BottomContinueButton(
            onPressed:
                _selectionFirst != null ||
                    widget.ancientWerewolfRole.convertedPlayerIndex != null
                ? () {
                    submit(gameState);
                  }
                : null,
          ),
        );
      },
    );
  }

  void submit(GameState gameState) {
    if (_selectionFirst == true) {
      final lastAttackedPlayer = findLastAttackedPlayer(gameState);
      if (lastAttackedPlayer != null) {
        useAbilityOn(gameState, lastAttackedPlayer.$1, lastAttackedPlayer.$2);
      }
    }
    widget.onPhaseComplete();
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
    widget.ancientWerewolfRole.convertedPlayerIndex = playerIndex;
  }
}

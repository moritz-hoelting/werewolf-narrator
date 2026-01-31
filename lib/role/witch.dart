import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/model/death_information.dart'
    show DeathReason;
import 'package:werewolf_narrator/model/role.dart';
import 'package:werewolf_narrator/model/team.dart';
import 'package:werewolf_narrator/role/cupid.dart' show CupidRole;
import 'package:werewolf_narrator/role/role.dart';
import 'package:werewolf_narrator/state/game.dart';
import 'package:werewolf_narrator/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/team/werewolves.dart' show WerewolvesTeam;
import 'package:werewolf_narrator/util/set.dart';
import 'package:werewolf_narrator/widgets/bottom_continue_button.dart';

class WitchRole extends Role implements DeathReason {
  WitchRole._();
  static final RoleType type = RoleType<WitchRole>();
  @override
  RoleType get objectType => type;

  static final Role instance = WitchRole._();

  static void registerRole() {
    RoleManager.registerRole<WitchRole>(
      RegisterRoleInformation(WitchRole._, instance),
    );
  }

  @override
  void onAssign(GameState gameState, int playerIndex) {
    super.onAssign(gameState, playerIndex);

    gameState.nightActionManager.registerAction(
      WitchRole.type,
      (gameState, onComplete) => nightActionScreen(playerIndex, onComplete),
      conditioned: (gameState) => gameState.playerAliveUntilDawn(playerIndex),
      after: [WerewolvesTeam.type, CupidRole.type],
    );
  }

  int healPotions = 1;
  int killPotions = 1;

  @override
  bool get isUnique => true;
  @override
  TeamType get initialTeam => VillageTeam.type;

  @override
  String name(BuildContext context) {
    return AppLocalizations.of(context).role_witch_name;
  }

  @override
  String description(BuildContext context) {
    return AppLocalizations.of(context).role_witch_description;
  }

  @override
  String checkRoleInstruction(BuildContext context, int count) {
    final localizations = AppLocalizations.of(context);
    return localizations.role_witch_checkInstruction(count: count);
  }

  @override
  String deathReasonDescription(BuildContext context) =>
      AppLocalizations.of(context).role_witch_deathReason;

  WidgetBuilder nightActionScreen(int playerIndex, VoidCallback onComplete) =>
      (context) => WitchScreen(
        witchRole: this,
        playerIndex: playerIndex,
        onPhaseComplete: onComplete,
        useUpPotions: ({heal = 0, kill = 0}) {
          healPotions -= heal;
          killPotions -= kill;
          if (heal > 0 || kill > 0) {
            Provider.of<GameState>(context, listen: false).notifyUpdate();
          }
        },
      );
}

class WitchScreen extends StatefulWidget {
  final WitchRole witchRole;
  final int playerIndex;
  final VoidCallback onPhaseComplete;
  final void Function({int heal, int kill}) useUpPotions;

  const WitchScreen({
    super.key,
    required this.witchRole,
    required this.playerIndex,
    required this.onPhaseComplete,
    required this.useUpPotions,
  });

  @override
  State<WitchScreen> createState() => _WitchScreenState();
}

class _WitchScreenState extends State<WitchScreen> {
  final Set<int> _selectedKillPlayers = {};
  final Set<int> _selectedHealPlayers = {};

  late bool _killModeActive = widget.witchRole.healPotions == 0;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.role_witch_name),
        automaticallyImplyLeading: false,
      ),
      body: widget.witchRole.healPotions > 0 || widget.witchRole.killPotions > 0
          ? HasPotionsBody(
              healPotions: widget.witchRole.healPotions,
              killPotions: widget.witchRole.killPotions,
              killModeActive: _killModeActive,
              enableKillMode: () {
                setState(() {
                  _killModeActive = true;
                });
              },
              disableKillMode: () {
                setState(() {
                  _killModeActive = false;
                });
              },
              playerEnabled: playerEnabled,
              selectedHealPlayers: _selectedHealPlayers,
              selectedKillPlayers: _selectedKillPlayers,
              onTapHeal: onTapHeal,
              onTapKill: onTapKill,
            )
          : Center(
              child: Text(
                localizations.screen_roleAction_instruction_witch_noPotionsLeft,
                style: TextStyle(fontSize: 18),
              ),
            ),
      bottomNavigationBar: BottomContinueButton(
        onPressed: () {
          final GameState gameState = Provider.of<GameState>(
            context,
            listen: false,
          );
          if (_selectedHealPlayers.isNotEmpty) {
            for (final healIndex in _selectedHealPlayers) {
              gameState.markPlayerRevived(healIndex);
            }
          }
          if (_selectedKillPlayers.isNotEmpty) {
            for (final killIndex in _selectedKillPlayers) {
              gameState.markPlayerDead(killIndex, widget.witchRole);
            }
          }
          widget.useUpPotions(
            heal: _selectedHealPlayers.length,
            kill: _selectedKillPlayers.length,
          );
          widget.onPhaseComplete();
        },
      ),
    );
  }

  bool playerEnabled(GameState gameState, int index) {
    final killedByWerewolves =
        gameState.currentCycleDeaths.containsKey(index) &&
        gameState.currentCycleDeaths[index] is WerewolvesTeam;
    return gameState.playerAliveOrKilledThisCycle(index) &&
        (_killModeActive
            ? (index != widget.playerIndex &&
                  gameState.playerAliveOrKilledThisCycle(index) &&
                  !killedByWerewolves)
            : (killedByWerewolves));
  }

  VoidCallback? onTapKill(GameState gameState, int index) => handleOnTap(
    gameState,
    index,
    _selectedKillPlayers,
    widget.witchRole.killPotions,
  );

  VoidCallback? onTapHeal(GameState gameState, int index) => handleOnTap(
    gameState,
    index,
    _selectedHealPlayers,
    widget.witchRole.healPotions,
  );
  VoidCallback? handleOnTap(
    GameState gameState,
    int index,
    Set<int> selectedSet,
    int maxSelectable,
  ) {
    if (!playerEnabled(gameState, index)) return null;

    if (maxSelectable == 1) {
      if (selectedSet.contains(index)) {
        return () {
          setState(() {
            selectedSet.remove(index);
          });
        };
      } else {
        return () {
          setState(() {
            selectedSet.clear();
            selectedSet.add(index);
          });
        };
      }
    }

    if (maxSelectable <= selectedSet.length && !selectedSet.contains(index)) {
      return null;
    }

    return () {
      setState(() {
        selectedSet.toggle(index);
      });
    };
  }
}

class HasPotionsBody extends StatelessWidget {
  const HasPotionsBody({
    super.key,
    required this.killModeActive,
    required this.healPotions,
    required this.killPotions,
    required this.enableKillMode,
    required this.disableKillMode,
    required this.playerEnabled,
    required this.selectedHealPlayers,
    required this.selectedKillPlayers,
    required this.onTapHeal,
    required this.onTapKill,
  });

  final bool killModeActive;
  final int healPotions;
  final int killPotions;
  final VoidCallback enableKillMode;
  final VoidCallback disableKillMode;
  final bool Function(GameState, int) playerEnabled;
  final Set<int> selectedHealPlayers;
  final Set<int> selectedKillPlayers;
  final VoidCallback? Function(GameState, int) onTapHeal;
  final VoidCallback? Function(GameState, int) onTapKill;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    final modeButtonStyle = TextButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.onSurface,
    );
    final selectedModeButtonStyle = TextButton.styleFrom(
      disabledForegroundColor: Theme.of(context).colorScheme.primary,
    );

    return Column(
      children: [
        TextButton.icon(
          style: !killModeActive ? selectedModeButtonStyle : modeButtonStyle,
          onPressed: killModeActive && healPotions > 0 ? disableKillMode : null,
          label: Text(
            localizations.screen_roleAction_instruction_witch_heal +
                (healPotions > 1 ? ' ($healPotions)' : ''),
          ),
          icon: const Icon(Icons.healing),
        ),
        TextButton.icon(
          style: killModeActive ? selectedModeButtonStyle : modeButtonStyle,
          onPressed: !killModeActive && killPotions > 0 ? enableKillMode : null,
          label: Text(
            localizations.screen_roleAction_instruction_witch_kill +
                (killPotions > 1 ? ' ($killPotions)' : ''),
          ),
          icon: const Icon(Icons.science),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            localizations.screen_roleAction_instruction_witch,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        Consumer<GameState>(
          builder: (context, gameState, child) => Expanded(
            child: ListView.builder(
              itemCount: gameState.playerCount,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(gameState.players[index].name),
                  trailing: selectedHealPlayers.contains(index)
                      ? const Icon(Icons.healing)
                      : (selectedKillPlayers.contains(index)
                            ? const Icon(Icons.science)
                            : null),
                  onTap: killModeActive
                      ? onTapKill(gameState, index)
                      : onTapHeal(gameState, index),
                  selected:
                      (selectedKillPlayers.contains(index) && killModeActive) ||
                      (selectedHealPlayers.contains(index) && !killModeActive),
                  enabled: playerEnabled(gameState, index),
                  selectedTileColor: killModeActive
                      ? Colors.red.withAlpha(50)
                      : Colors.green.withAlpha(50),
                  tileColor: killModeActive
                      ? (selectedHealPlayers.contains(index)
                            ? Colors.green.withAlpha(30)
                            : null)
                      : (selectedKillPlayers.contains(index)
                            ? Colors.red.withAlpha(30)
                            : null),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

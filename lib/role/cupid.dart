import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/model/role.dart';
import 'package:werewolf_narrator/model/team.dart';
import 'package:werewolf_narrator/role/role.dart';
import 'package:werewolf_narrator/state/game.dart';
import 'package:werewolf_narrator/team/lovers.dart' show LoversTeam;
import 'package:werewolf_narrator/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/views/game/action_screen.dart';

class CupidRole extends Role {
  CupidRole._();

  static final Role instance = CupidRole._();
  static final RoleType type = RoleType<CupidRole>();
  @override
  RoleType get objectType => type;

  static void registerRole() {
    RoleManager.registerRole<CupidRole>(
      RegisterRoleInformation(CupidRole._, instance),
    );
  }

  @override
  void onAssign(GameState gameState, int playerIndex) {
    super.onAssign(gameState, playerIndex);

    gameState.nightActionManager.registerAction(
      CupidRole.type,
      (gameState, onComplete) {
        return nightActionScreen(onComplete);
      },
      conditioned: (gameState) =>
          !gameState.teams.containsKey(LoversTeam.type) &&
          gameState.playerAliveUntilDawn(playerIndex),
    );
  }

  @override
  bool get isUnique => true;
  @override
  TeamType get initialTeam => VillageTeam.type;

  @override
  String name(BuildContext context) {
    return AppLocalizations.of(context).role_cupid_name;
  }

  @override
  String description(BuildContext context) {
    return AppLocalizations.of(context).role_cupid_description;
  }

  @override
  String checkRoleInstruction(BuildContext context, int count) {
    final localizations = AppLocalizations.of(context);
    return localizations.role_cupid_checkInstruction(count: count);
  }

  WidgetBuilder nightActionScreen(VoidCallback onComplete) {
    return (context) => CupidScreen(onComplete: onComplete, cupidRole: this);
  }
}

class CupidScreen extends StatefulWidget {
  const CupidScreen({
    super.key,
    required this.onComplete,
    required this.cupidRole,
  });

  final CupidRole cupidRole;
  final VoidCallback onComplete;

  @override
  State<CupidScreen> createState() => _CupidScreenState();
}

class _CupidScreenState extends State<CupidScreen> {
  LoversTeam? loversTeam;

  @override
  Widget build(BuildContext context) {
    if (loversTeam == null) {
      return ActionScreen(
        appBarTitle: Text(widget.cupidRole.name(context)),
        instruction: Text(
          AppLocalizations.of(context).screen_roleAction_instruction_cupid,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        selectionCount: 2,
        onConfirm: onAssignLovers,
      );
    } else {
      return WakeLoversScreen(
        onPhaseComplete: widget.onComplete,
        lovers: loversTeam!.lovers!,
      );
    }
  }

  void onAssignLovers(Set<int> selectedIndices, GameState gameState) {
    assert(
      selectedIndices.length == 2,
      'Cupid must select exactly two players as lovers.',
    );
    final selectedList = selectedIndices.toList()..sort();
    final team = LoversTeam.withLovers((selectedList[0], selectedList[1]));
    loversTeam = team;
    gameState.teams[LoversTeam.type] = team;
    team.initialize(gameState);

    gameState.notifyUpdate();
  }
}

class WakeLoversScreen extends StatelessWidget {
  final VoidCallback onPhaseComplete;
  final (int, int) lovers;

  const WakeLoversScreen({
    super.key,
    required this.onPhaseComplete,
    required this.lovers,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        final localizations = AppLocalizations.of(context);
        return Scaffold(
          appBar: AppBar(
            title: Text(localizations.screen_wakeLovers_title),
            automaticallyImplyLeading: false,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                spacing: 16.0,
                children: [
                  const Icon(Icons.favorite, color: Colors.red, size: 160),
                  Text(
                    localizations.screen_wakeLovers_instructions(
                      playerA: gameState.players[lovers.$1].name,
                      playerB: gameState.players[lovers.$2].name,
                    ),
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
              ),
              onPressed: onPhaseComplete,
              label: Text(localizations.button_continueLabel),
              icon: const Icon(Icons.arrow_forward),
            ),
          ),
        );
      },
    );
  }
}

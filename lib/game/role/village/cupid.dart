import 'package:collection/collection.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/game/model/role_config.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/misc/winners/lovers.dart' show Lovers;
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/views/game/action_screen.dart';

class CupidRole extends Role {
  CupidRole._(RoleConfiguration config);

  static final RoleType<CupidRole> type = RoleType<CupidRole>();
  @override
  RoleType<CupidRole> get objectType => type;

  static void registerRole() {
    RoleManager.registerRole<CupidRole>(
      type,
      RegisterRoleInformation(
        constructor: CupidRole._,
        name: (context) => AppLocalizations.of(context).role_cupid_name,
        description: (context) =>
            AppLocalizations.of(context).role_cupid_description,
        initialTeam: VillageTeam.type,
        checkRoleInstruction: (context, count) => AppLocalizations.of(
          context,
        ).role_cupid_checkInstruction(count: count),
        validRoleCounts: const [1],
        chooseRolesInformation: ChooseRolesInformation(
          category: ChooseRolesCategory.village,
          priority: 50,
        ),
      ),
    );
  }

  @override
  void onAssign(GameState gameState, int playerIndex) {
    super.onAssign(gameState, playerIndex);

    gameState.nightActionManager.registerAction(
      CupidRole.type,
      (gameState, onComplete) {
        return nightActionScreen(playerIndex, onComplete);
      },
      conditioned: (gameState) =>
          gameState.winConditions.whereType<Lovers>().toList().isEmpty &&
          gameState.playerAliveUntilDawn(playerIndex),
      players: {playerIndex},
    );
  }

  WidgetBuilder nightActionScreen(int playerIndex, VoidCallback onComplete) {
    return (context) => CupidScreen(
      onComplete: onComplete,
      cupidIndex: playerIndex,
      cupidRole: this,
    );
  }
}

class CupidScreen extends StatefulWidget {
  const CupidScreen({
    super.key,
    required this.onComplete,
    required this.cupidRole,
    required this.cupidIndex,
  });

  final CupidRole cupidRole;
  final int cupidIndex;
  final VoidCallback onComplete;

  @override
  State<CupidScreen> createState() => _CupidScreenState();
}

class _CupidScreenState extends State<CupidScreen> {
  Lovers? lovers;

  @override
  Widget build(BuildContext context) {
    if (lovers == null) {
      return ActionScreen(
        appBarTitle: Text(widget.cupidRole.name(context)),
        instruction: Text(
          AppLocalizations.of(context).role_cupid_nightAction_instruction,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actionIdentifier: CupidRole.type,
        currentActorIndices: ISet({widget.cupidIndex}),
        selectionCount: 2,
        onConfirm: onAssignLovers,
      );
    } else {
      return WakeLoversScreen(
        onPhaseComplete: widget.onComplete,
        lovers: lovers!.lovers,
      );
    }
  }

  void onAssignLovers(ISet<int> selectedIndices, GameState gameState) {
    assert(
      selectedIndices.length == 2,
      'Cupid must select exactly two players as lovers.',
    );
    final selectedList = selectedIndices.toList()..sort();
    final lovers_ = Lovers(selectedList.toISet());
    lovers = lovers_;
    gameState.winConditions.add(lovers_);
    lovers_.initialize(gameState);

    gameState.notifyUpdate();
  }
}

class WakeLoversScreen extends StatelessWidget {
  final VoidCallback onPhaseComplete;
  final ISet<int> lovers;

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
                    localizations.screen_wakeLovers_instructions,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  ...lovers
                      .sorted((a, b) => a.compareTo(b))
                      .map(
                        (playerIndex) =>
                            Text(gameState.players[playerIndex].name),
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

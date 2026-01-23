part of 'role.dart';

class CupidRole extends Role {
  CupidRole._();

  static final Role instance = CupidRole._();
  static final RoleType type = RoleType<CupidRole>();
  @override
  RoleType get objectType => type;

  (int, int)? lovers;

  static void registerRole() {
    RoleManager.registerRole<CupidRole>(
      RegisterRoleInformation(CupidRole._, instance),
    );
  }

  @override
  void onAssign(GameState gameState, int playerIndex) {
    gameState.deathHooks.add((gameState, playerIndex, reason) {
      if (reason != DeathReason.lover &&
          lovers != null &&
          (playerIndex == lovers!.$1 || playerIndex == lovers!.$2)) {
        final int otherLoverIndex = playerIndex == lovers!.$1
            ? lovers!.$2
            : lovers!.$1;
        gameState.markPlayerDead(otherLoverIndex, DeathReason.lover);
      }

      return false;
    });

    gameState.reviveHooks.add((gameState, playerIndex) {
      if (lovers != null &&
          (playerIndex == lovers!.$1 || playerIndex == lovers!.$2)) {
        final int otherLoverIndex = playerIndex == lovers!.$1
            ? lovers!.$2
            : lovers!.$1;
        gameState.markPlayerRevived(otherLoverIndex);
      }

      return false;
    });
  }

  @override
  bool get isUnique => true;
  @override
  TeamType get initialTeam => VillageTeam.type;

  @override
  String name(BuildContext context) {
    return AppLocalizations.of(context)!.role_cupid_name;
  }

  @override
  String description(BuildContext context) {
    return AppLocalizations.of(context)!.role_cupid_description;
  }

  @override
  String checkRoleInstruction(BuildContext context, int count) {
    final localizations = AppLocalizations.of(context)!;
    return localizations.screen_checkRoles_instruction_cupid(count);
  }

  @override
  bool hasNightScreen(GameState gameState) => lovers == null;
  @override
  WidgetBuilder? nightActionScreen(VoidCallback onComplete) {
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
  @override
  Widget build(BuildContext context) {
    if (widget.cupidRole.lovers == null) {
      return ActionScreen(
        appBarTitle: Text(CupidRole.instance.name(context)),
        selectionCount: 2,
        onConfirm: (selectedIndices, gameState) {
          assert(
            selectedIndices.length == 2,
            'Cupid must select exactly two players as lovers.',
          );
          widget.cupidRole.lovers = (selectedIndices[0], selectedIndices[1]);
          gameState.notifyUpdate();
        },
      );
    } else {
      return WakeLoversScreen(
        onPhaseComplete: widget.onComplete,
        lovers: widget.cupidRole.lovers!,
      );
    }
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
        final localizations = AppLocalizations.of(context)!;
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
                spacing: 16.0,
                children: [
                  const Icon(Icons.favorite, color: Colors.red, size: 160),
                  Text(
                    localizations.screen_wakeLovers_instructions(
                      gameState.players[lovers.$1].name,
                      gameState.players[lovers.$2].name,
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

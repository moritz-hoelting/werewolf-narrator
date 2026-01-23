part of 'role.dart';

class CupidRole extends Role {
  CupidRole._();

  static final Role instance = CupidRole._();
  static final RoleType type = RoleType<CupidRole>();
  @override
  RoleType get objectType => type;

  // TODO: register death handler
  (int, int)? lovers;

  static void registerRole() {
    RoleManager.registerRole<CupidRole>(
      RegisterRoleInformation(CupidRole._, instance),
    );
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
  bool _loversSelected = false;

  @override
  Widget build(BuildContext context) {
    if (!_loversSelected) {
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
          setState(() {
            _loversSelected = true;
          });
        },
      );
    } else {
      return WakeLoversScreen(onPhaseComplete: widget.onComplete);
    }
  }
}

class WakeLoversScreen extends StatelessWidget {
  final VoidCallback onPhaseComplete;

  const WakeLoversScreen({super.key, required this.onPhaseComplete});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        assert(
          gameState.lovers != null,
          'Lovers should be set when waking them up.',
        );

        final localizations = AppLocalizations.of(context)!;
        return Scaffold(
          appBar: AppBar(
            title: Text(localizations.screen_wakeLovers_title),
            automaticallyImplyLeading: false,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 16.0,
              children: [
                const Icon(Icons.favorite, color: Colors.red, size: 160),
                Text(
                  localizations.screen_wakeLovers_instructions(
                    gameState.players[gameState.lovers!.$1].name,
                    gameState.players[gameState.lovers!.$2].name,
                  ),
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ],
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

part of 'role.dart';

class SeerRole extends Role {
  const SeerRole._();
  static final RoleType type = RoleType<SeerRole>();
  @override
  RoleType get objectType => type;

  static const Role instance = SeerRole._();

  static void registerRole() {
    RoleManager.registerRole<SeerRole>(
      RegisterRoleInformation(SeerRole._, instance),
    );
  }

  @override
  bool get isUnique => true;
  @override
  Team get initialTeam => Team.village;

  @override
  String name(BuildContext context) {
    return AppLocalizations.of(context)!.role_seer_name;
  }

  @override
  String description(BuildContext context) {
    return AppLocalizations.of(context)!.role_seer_description;
  }

  @override
  String checkRoleInstruction(BuildContext context, int count) {
    final localizations = AppLocalizations.of(context)!;
    return localizations.screen_checkRoles_instruction_seer(count);
  }

  @override
  bool hasNightScreen(GameState gameState) => true;
  @override
  WidgetBuilder? nightActionScreen(VoidCallback onComplete) {
    return (context) => SeerScreen(onPhaseComplete: onComplete);
  }
}

class SeerScreen extends StatefulWidget {
  final VoidCallback onPhaseComplete;

  const SeerScreen({super.key, required this.onPhaseComplete});

  @override
  State<SeerScreen> createState() => _SeerScreenState();
}

class _SeerScreenState extends State<SeerScreen> {
  int? _selectedPlayer;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        final localizations = AppLocalizations.of(context)!;

        return Scaffold(
          appBar: AppBar(
            title: Text(localizations.role_seer_name),
            automaticallyImplyLeading: false,
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  localizations.screen_roleAction_instruction_seer,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: gameState.playerCount,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(gameState.players[index].name),
                      subtitle: _selectedPlayer == index
                          ? Text(
                              gameState.players[index].role?.name(context) ??
                                  localizations.role_unknown_name,
                              style: Theme.of(context).textTheme.bodyLarge,
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedPlayer = index;
                        });
                      },
                      selected: _selectedPlayer == index,
                      enabled:
                          gameState.players[index].isAlive &&
                          gameState.players[index].role.runtimeType != SeerRole,
                      selectedTileColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.2),
                    );
                  },
                ),
              ),
            ],
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
              ),
              onPressed: _selectedPlayer != null
                  ? widget.onPhaseComplete
                  : null,
              label: Text(localizations.button_continueLabel),
              icon: const Icon(Icons.arrow_forward),
            ),
          ),
        );
      },
    );
  }
}

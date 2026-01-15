import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/state/game.dart';
import 'package:werewolf_narrator/util/gradient.dart';
import 'package:werewolf_narrator/views/game/death_actions_screen.dart';

class DeathsScreen extends StatefulWidget {
  final VoidCallback onPhaseComplete;
  final Widget? title;
  final Color? beamColor;

  const DeathsScreen({
    super.key,
    required this.onPhaseComplete,
    this.title,
    this.beamColor,
  });

  @override
  State<DeathsScreen> createState() => _DeathsScreenState();
}

class _DeathsScreenState extends State<DeathsScreen> {
  bool showDeathActions = false;

  @override
  Widget build(BuildContext context) {
    if (showDeathActions) {
      return DeathActionsScreen(onPhaseComplete: widget.onPhaseComplete);
    }

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: widget.title ?? const Text('Death Announcements'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.bottomCenter,
            radius: 2,
            colors: [
              widget.beamColor ?? Colors.grey.shade700,
              Colors.transparent,
            ],
            stops: const [0.0, 0.7],
            transform: ScaleGradient(scaleX: 1.25, scaleY: 0.75),
          ),
        ),
        height: double.infinity,
        child: Consumer<GameState>(
          builder: (context, gameState, child) {
            final unannouncedDeaths = gameState.unannouncedDeaths;
            if (unannouncedDeaths.isEmpty) {
              return Center(
                child: Text(
                  'No one died.',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              );
            }

            return ListView.builder(
              itemBuilder: (context, index) {
                final playerIndex = unannouncedDeaths.keys.elementAt(index);
                final player = gameState.players[playerIndex];
                final deathInformation = unannouncedDeaths[playerIndex]!;
                return ListTile(
                  title: Text(
                    'Player ${player.name} has died.',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  subtitle: Text(
                    '${player.role?.name(context) ?? 'Unknown Role'} - ${deathInformation.reason.name(context)}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                );
              },
              itemCount: unannouncedDeaths.length,
              shrinkWrap: true,
            );
          },
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(60),
          ),
          onPressed: () {
            GameState gameState = Provider.of<GameState>(
              context,
              listen: false,
            );
            gameState.markDeathsAnnounced();

            if (gameState.pendingDeathActions) {
              setState(() {
                showDeathActions = true;
              });
            } else {
              widget.onPhaseComplete();
            }
          },
          label: const Text('Continue'),
          icon: const Icon(Icons.arrow_forward),
        ),
      ),
    );
  }
}

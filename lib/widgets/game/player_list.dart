import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/util/hooks.dart';

class PlayerList extends StatelessWidget {
  const PlayerList({
    super.key,
    required this.phaseIdentifier,
    this.selectedPlayers = const ISet.empty(),
    this.disabledPlayers = const ISet.empty(),
    this.hiddenPlayers = const ISet.empty(),
    this.currentActorIndices = const ISet.empty(),
    this.playerDisplayData,
    this.playerSpecificDisplayData = const IMap.empty(),
    this.onPlayerTap,
  });

  final Object? phaseIdentifier;
  final ISet<int> selectedPlayers;
  final ISet<int> disabledPlayers;
  final ISet<int> hiddenPlayers;
  final ISet<int> currentActorIndices;
  final PlayerDisplayData? playerDisplayData;
  final IMap<int, PlayerDisplayData> playerSpecificDisplayData;
  final VoidCallback? Function(int index)? onPlayerTap;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final playerDisplayHooks = gameState.playerDisplayHooks;
        final showPlayers = List.generate(
          gameState.playerCount,
          (i) => i,
        ).where((index) => !hiddenPlayers.contains(index)).toIList();

        return ListView.builder(
          itemCount: showPlayers.length,
          itemBuilder: (context, index) {
            int playerIndex = showPlayers[index];
            final VoidCallback? onTap = onPlayerTap?.call(playerIndex);

            return PlayerListTile(
              index: playerIndex,
              name: gameState.players[playerIndex].name,
              playerDisplayHooks: playerDisplayHooks,
              phaseIdentifier: phaseIdentifier,
              selected: selectedPlayers.contains(playerIndex),
              enabled: !disabledPlayers.contains(playerIndex),
              currentActor: currentActorIndices.contains(playerIndex),
              playerDisplayData: PlayerDisplayData.merge(
                [
                  playerSpecificDisplayData[playerIndex],
                  playerDisplayData,
                ].nonNulls,
              ),
              onTap: onTap,
            );
          },
        );
      },
    );
  }
}

class PlayerListTile extends StatelessWidget {
  const PlayerListTile({
    super.key,
    required this.index,
    required this.name,
    required this.playerDisplayHooks,
    this.onTap,
    required this.phaseIdentifier,
    this.selected = false,
    this.enabled = true,
    this.playerDisplayData,
    this.currentActor = false,
  });

  final int index;
  final String name;
  final bool currentActor;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;
  final IList<PlayerDisplayHook> playerDisplayHooks;
  final Object? phaseIdentifier;
  final PlayerDisplayData? playerDisplayData;

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context, listen: true);

    final hookPlayerDisplayData = PlayerDisplayData.merge(
      playerDisplayHooks
          .map((hook) => hook(gameState, phaseIdentifier, index))
          .nonNulls,
    );

    final playerDisplayData = this.playerDisplayData != null
        ? PlayerDisplayData.merge([
            this.playerDisplayData!,
            hookPlayerDisplayData,
          ])
        : hookPlayerDisplayData;

    final tileEnabled = enabled && !playerDisplayData.disabled;

    return ListTile(
      title: Text(name),
      subtitle: playerDisplayData.subtitle != null
          ? playerDisplayData.subtitle!(context)
          : null,
      trailing: playerDisplayData.trailing != null
          ? playerDisplayData.trailing!(context)
          : null,
      onTap: onTap,
      selected: selected,
      enabled: tileEnabled,
      tileColor: currentActor
          ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1)
          : playerDisplayData.tileColor,
      selectedTileColor:
          playerDisplayData.selectedTileColor ??
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
    );
  }
}

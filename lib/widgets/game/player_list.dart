import 'package:collection/collection.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/game/game_data.dart' show GamePhase;
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/util/hooks.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';

class PlayerList extends StatelessWidget {
  const PlayerList({
    required this.phaseIdentifier,
    super.key,
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
  Widget build(BuildContext context) => Consumer<GameState>(
    builder: (context, gameState, child) {
      final playerDisplayHooks = gameState.playerDisplayHooks;
      final showPlayers = List.generate(
        gameState.playerCount,
        (i) => i,
      ).where((index) => !hiddenPlayers.contains(index)).toIList();

      return ListView.builder(
        itemCount: showPlayers.length,
        itemBuilder: (context, index) {
          final int playerIndex = showPlayers[index];
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

class PlayerListTile extends StatelessWidget {
  const PlayerListTile({
    required this.index,
    required this.name,
    required this.playerDisplayHooks,
    required this.phaseIdentifier,
    super.key,
    this.onTap,
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
    final localizations = AppLocalizations.of(context);
    final gameState = Provider.of<GameState>(context, listen: true);

    final isCheckRoles =
        phaseIdentifier is (GamePhase, Object?) &&
        (phaseIdentifier as (GamePhase, Object?)).$1 == GamePhase.checkRoles;

    final checkRolesTeamRole = isCheckRoles
        ? gameState.checkRolesData.assignedPlayersByTeam.entries
              .firstWhereOrNull((entry) => entry.value.contains(index))
              ?.key
              .information
              .checkTeamTogether
              ?.defaultRole
        : null;

    final role =
        gameState.players[index].role?.name(context) ??
        checkRolesTeamRole?.information.name(context);

    final hookPlayerDisplayData = PlayerDisplayData.merge(
      playerDisplayHooks
          .map((hook) => hook(gameState, phaseIdentifier, index))
          .nonNulls,
    );

    final playerDisplayData = this.playerDisplayData != null
        ? PlayerDisplayData.merge([
            if (gameState.additionalInformationVisible)
              PlayerDisplayData(
                subtitle: (context) => Text(
                  localizations.widget_playerList_additionalInformationSubtitle(
                    role: role ?? localizations.role_unknown_name,
                  ),
                ),
              ),
            this.playerDisplayData!,
            hookPlayerDisplayData,
          ])
        : hookPlayerDisplayData;

    final tileEnabled = enabled && !playerDisplayData.disabled;

    return ListTile(
      title: Text(name),
      subtitle: playerDisplayData.subtitle?.call(context),
      trailing: playerDisplayData.trailing?.call(context),
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

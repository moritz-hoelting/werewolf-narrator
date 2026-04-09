import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/database/database.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/views/game.dart';

final DateFormat _dateFormatter = DateFormat.yMd().add_jm();

class GamesOverview extends StatefulWidget {
  const GamesOverview({super.key});

  @override
  State<GamesOverview> createState() => _GamesOverviewState();
}

class _GamesOverviewState extends State<GamesOverview> {
  bool showArchived = false;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(localizations.screen_gamesOverview_title)),
      body: CustomScrollView(
        slivers: [
          _SectionHeader(
            title: localizations.screen_gamesOverview_runningGames,
          ),
          _GameListSliver(
            archived: false,
            active: true,
            noGamesFoundMessage:
                localizations.screen_gamesOverview_noRunningGames,
          ),

          _SectionHeader(
            title: localizations.screen_gamesOverview_finishedGames,
          ),
          _GameListSliver(
            archived: false,
            active: false,
            noGamesFoundMessage:
                localizations.screen_gamesOverview_noFinishedGames,
          ),

          SliverToBoxAdapter(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(localizations.screen_gamesOverview_archivedGames),
              trailing: Icon(
                showArchived ? Icons.expand_less : Icons.expand_more,
              ),
              onTap: () {
                setState(() => showArchived = !showArchived);
              },
            ),
          ),

          if (showArchived)
            _GameListSliver(
              archived: true,
              active: null,
              noGamesFoundMessage:
                  localizations.screen_gamesOverview_noArchivedGames,
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _GameListSliver extends StatelessWidget {
  const _GameListSliver({
    required this.archived,
    required this.active,
    required this.noGamesFoundMessage,
  });

  final bool archived;
  final bool? active;
  final String noGamesFoundMessage;

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context, listen: false);

    return StreamBuilder<List<Game>>(
      stream: db.gamesDao.watchGames(archived: archived, active: active),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final games = snapshot.data!;

        if (games.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(noGamesFoundMessage),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final game = games[index];
            return _GameTile(game: game, key: ValueKey(game.id));
          }, childCount: games.length),
        );
      },
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({required this.game, super.key});

  final Game game;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    final ended = game.endedAt != null;
    final archived = game.archived;

    final startedAt = _dateFormatter.format(game.startedAt);
    final endedAt = ended ? _dateFormatter.format(game.endedAt!) : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        title: Text(
          localizations.screen_gamesOverview_gameTitle(id: game.id),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.screen_gamesOverview_gameStarted(
                dateTime: startedAt,
              ),
            ),
            if (endedAt != null)
              Text(
                localizations.screen_gamesOverview_gameEnded(dateTime: endedAt),
              ),
            const SizedBox(height: 4),
            _PlayerNames(gameId: game.id),
          ],
        ),

        isThreeLine: true,

        onTap: () => ended || archived
            ? _showInformation(context)
            : _resumeGame(context, game.id),

        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!ended && !archived)
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => _showInformation(context),
              ),
            const IconButton(
              // TODO: implement reusing game data to create new game with same players and roles
              onPressed: null,
              icon: Icon(Icons.copy),
            ),
            IconButton(
              icon: Icon(
                archived ? Icons.unarchive_outlined : Icons.archive_outlined,
              ),
              onPressed: () => _toggleGameArchived(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }

  void _resumeGame(BuildContext context, int gameId) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => GameView(gameId: gameId)));
  }

  void _showInformation(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _GameInformationDialog(game: game),
    );
  }

  void _toggleGameArchived(BuildContext context) {
    Provider.of<AppDatabase>(
      context,
      listen: false,
    ).gamesDao.setGameArchived(game.id, !game.archived);
  }

  void _confirmDelete(BuildContext context) async {
    final answer = await showDialog<bool>(
      useRootNavigator: false,
      context: context,
      builder: (dialogContext) {
        final localizations = AppLocalizations.of(dialogContext);
        return AlertDialog(
          icon: const Icon(Icons.delete),
          title: Text(localizations.alert_deleteGame_title),
          content: Text(localizations.alert_deleteGame_message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
            ),
          ],
        );
      },
    );

    if (answer == true && context.mounted) {
      unawaited(
        Provider.of<AppDatabase>(
          context,
          listen: false,
        ).gamesDao.deleteGame(game.id),
      );
    }
  }
}

class _PlayerNames extends StatelessWidget {
  const _PlayerNames({required this.gameId});

  final int gameId;

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context, listen: false);

    return FutureBuilder(
      future: db.gamesDao.getOrderedPlayerNamesForGame(gameId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Text('...');
        return Text(
          snapshot.data!.map((player) => player.name).join(', '),
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

class _GameInformationDialog extends StatelessWidget {
  _GameInformationDialog({required this.game})
    : playersFuture = AppDatabaseHolder().database.gamesDao
          .getOrderedPlayerNamesForGame(game.id);

  final Game game;
  final Future<List<({bool hasWon, String name})>> playersFuture;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(localizations.alert_gameInformation_title(id: game.id)),
      content: FutureBuilder<List<({bool hasWon, String name})>>(
        future: playersFuture,
        builder: (context, snapshot) {
          final players = snapshot.data ?? [];

          final winnerNames = players.where((p) => p.hasWon).map((p) => p.name);

          final allNames = players.map((p) => p.name).join(', ');

          final theme = Theme.of(context);
          final textTheme = theme.textTheme;
          final colorScheme = theme.colorScheme;

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (game.winner != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      game.winner!.winningHeadline(context),
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(localizations.alert_gameInformation_startedAt),
                  subtitle: Text(_dateFormatter.format(game.startedAt)),
                ),
                if (game.endedAt != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(Icons.flag),
                    title: Text(localizations.alert_gameInformation_endedAt),
                    subtitle: Text(_dateFormatter.format(game.endedAt!)),
                  ),
                const SizedBox(height: 12),
                Text(
                  localizations.alert_gameInformation_players,
                  style: textTheme.labelLarge,
                ),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(allNames.isNotEmpty ? allNames : '...'),
                ),
                if (winnerNames.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    localizations.alert_gameInformation_winners(
                      count: winnerNames.length,
                    ),
                    style: textTheme.labelLarge,
                  ),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(winnerNames.join(', ')),
                  ),
                ],
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    );
  }
}

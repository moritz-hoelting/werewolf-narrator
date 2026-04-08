import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/database/database.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/views/game.dart';

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
      // TODO: better layout
      body: ListView(
        children: [
          const Text('Running games'),
          const _GameList(archived: false, active: true),
          const Text('Finished games'),
          const _GameList(archived: false, active: false),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Archived games'),
              IconButton(
                onPressed: () {
                  setState(() {
                    showArchived = !showArchived;
                  });
                },
                icon: Icon(
                  showArchived ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                ),
              ),
            ],
          ),
          if (showArchived) const _GameList(archived: true, active: null),
        ],
      ),
    );
  }
}

class _GameList extends StatelessWidget {
  const _GameList({required this.archived, required this.active});

  final bool archived;
  final bool? active;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return StreamBuilder(
      stream: Provider.of<AppDatabase>(
        context,
        listen: false,
      ).gamesDao.watchGames(archived: archived, active: active),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.active) {
          return const Center(child: CircularProgressIndicator());
        }
        final games = snapshot.data ?? [];
        if (games.isEmpty) {
          return Center(
            child: Text(localizations.screen_gamesOverview_noGamesFound),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          itemCount: games.length,
          itemBuilder: (context, index) {
            final game = games[index];
            return _GameTile(
              key: ValueKey(game.id),
              archived: archived,

              id: game.id,
              startedAt: game.startedAt,
              finishedAt: game.endedAt,
            );
          },
        );
      },
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({
    required this.id,
    required this.startedAt,
    required this.archived,
    this.finishedAt,
    super.key,
  });

  final bool archived;

  final int id;
  final DateTime startedAt;
  final DateTime? finishedAt;

  static final DateFormat dateFormatter = DateFormat.yMd().add_jm();

  @override
  Widget build(BuildContext context) {
    final finished = this.finishedAt != null;
    final localizations = AppLocalizations.of(context);

    final startedAt = dateFormatter.format(this.startedAt);
    final finishedAt = this.finishedAt != null
        ? dateFormatter.format(this.finishedAt!)
        : null;

    return ListTile(
      title: FutureBuilder(
        future: Provider.of<AppDatabase>(
          context,
          listen: false,
        ).gamesDao.getOrderedPlayerNamesForGame(id),
        builder: (context, gamePlayers) {
          final text = gamePlayers.hasData
              ? localizations.screen_gameOverview_gameTitleWithPlayers(
                  id: id,
                  playerNames: gamePlayers.data!.join(', '),
                )
              : localizations.screen_gameOverview_gameTitleOfId(id: id);

          return Text(text);
        },
      ),
      subtitle: Text(
        finished
            ? localizations.screen_gameOverview_gameSubtitleFinished(
                startedAt: startedAt,
                finishedAt: finishedAt!,
              )
            : localizations.screen_gameOverview_gameSubtitleOngoing(
                startedAt: startedAt,
              ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: localizations.screen_gameOverview_resumeGameTooltip,
            onPressed: finished || archived
                ? null
                : () {
                    _resumeGame(context, id);
                  },
          ),
          const IconButton(
            // TODO: implement reusing game data to create new game with same players and roles
            onPressed: null,
            icon: Icon(Icons.copy),
          ),
          IconButton(
            icon: Icon(archived ? Icons.unarchive : Icons.archive),
            onPressed: () {
              Provider.of<AppDatabase>(
                context,
                listen: false,
              ).gamesDao.setGameArchived(id, !archived);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final answer = await showDialog<bool>(
                useRootNavigator: false,
                context: context,
                builder: (dialogContext) => AlertDialog(
                  icon: const Icon(Icons.delete),
                  title: Text(localizations.alert_deleteGame_title),
                  content: Text(localizations.alert_deleteGame_message),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        MaterialLocalizations.of(context).cancelButtonLabel,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(
                        MaterialLocalizations.of(context).okButtonLabel,
                      ),
                    ),
                  ],
                ),
              );

              if (answer == true && context.mounted) {
                unawaited(
                  Provider.of<AppDatabase>(
                    context,
                    listen: false,
                  ).gamesDao.deleteGame(id),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _resumeGame(BuildContext context, int gameId) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => GameView(gameId: gameId)));
  }
}

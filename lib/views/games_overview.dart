import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/database/database.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/views/game.dart';

class GamesOverview extends StatelessWidget {
  const GamesOverview({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(localizations.screen_gamesOverview_title)),
      body: StreamBuilder(
        stream: Provider.of<AppDatabase>(
          context,
          listen: false,
        ).gamesDao.watchGames(),
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
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              return GameTile(
                id: game.id,
                startedAt: game.startedAt,
                finishedAt: game.endedAt,
              );
            },
          );
        },
      ),
    );
  }
}

class GameTile extends StatelessWidget {
  const GameTile({
    required this.id,
    required this.startedAt,
    this.finishedAt,
    super.key,
  });

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
          if (!gamePlayers.hasData) {
            return Text(
              localizations.screen_gameOverview_gameTitleOfId(id: id),
            );
          }
          return Text(
            localizations.screen_gameOverview_gameTitleWithPlayers(
              id: id,
              playerNames: gamePlayers.data!.join(', '),
            ),
          );
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
          const IconButton(
            // TODO: implement reusing game data to create new game with same players and roles
            onPressed: null,
            icon: Icon(Icons.copy),
          ),
          IconButton(
            onPressed: finished
                ? null
                : () {
                    _resumeGame(context, id);
                  },
            icon: const Icon(Icons.play_arrow),
            tooltip: localizations.screen_gameOverview_resumeGameTooltip,
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

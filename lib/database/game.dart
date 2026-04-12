import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:werewolf_narrator/database/database.dart';
import 'package:werewolf_narrator/database/player_names.dart' show PlayerNames;
import 'package:werewolf_narrator/game/game_command.dart'
    show GameCommand, GameCommandMapper;
import 'package:werewolf_narrator/game/model/configuration_options.dart'
    show GameConfiguration, RoleConfiguration;
import 'package:werewolf_narrator/game/model/role.dart' show RoleType;
import 'package:werewolf_narrator/game/model/win_condition.dart'
    show WinCondition, WinConditionMapper;

part 'game.g.dart';

@TableIndex(name: 'archivedGames', columns: {#archived})
class Games extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startedAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get endedAt => dateTime().nullable()();
  BlobColumn get configuration => blob().map(jsonIMapConverter)();
  BlobColumn get winner => blob().map(winnerBinaryConverter).nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  @override
  bool get isStrict => true;
}

class GamePlayers extends Table {
  IntColumn get gameId =>
      integer().references(Games, #id, onDelete: KeyAction.cascade)();
  IntColumn get playerId =>
      integer().references(PlayerNames, #id, onDelete: KeyAction.restrict)();
  IntColumn get order => integer()();
  BoolColumn get hasWon => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {gameId, playerId};

  @override
  bool get isStrict => true;
}

class GameRoles extends Table {
  IntColumn get gameId =>
      integer().references(Games, #id, onDelete: KeyAction.cascade)();
  TextColumn get role => text().map(const RoleTypeConverter())();
  // ignore: recursive_getters
  IntColumn get count => integer().check(count.isBiggerOrEqualValue(1))();
  BlobColumn get configuration => blob().map(jsonMapConverter)();

  @override
  Set<Column> get primaryKey => {gameId, role};

  @override
  bool get isStrict => true;
}

@TableIndex(
  name: 'gameid_order',
  columns: {#gameId, #orderInGame},
  unique: true,
)
@DataClassName('CommandBatch')
class CommandBatches extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get gameId =>
      integer().references(Games, #id, onDelete: KeyAction.cascade)();
  IntColumn get orderInGame => integer()();
  BoolColumn get wasUndone => boolean().withDefault(const Constant(false))();

  @override
  bool get isStrict => true;
}

@TableIndex(
  name: 'batchid_orderinbatch',
  columns: {#batchId, #orderInBatch},
  unique: true,
)
@DataClassName('CommandEntry')
class CommandEntries extends Table {
  IntColumn get batchId =>
      integer().references(CommandBatches, #id, onDelete: KeyAction.cascade)();
  IntColumn get orderInBatch => integer()();
  TextColumn get type => text()();
  BlobColumn get data => blob().map(commandBinaryConverter)();

  @override
  Set<Column> get primaryKey => {batchId, orderInBatch};

  @override
  bool get isStrict => true;
}

@DriftAccessor(
  tables: [Games, GamePlayers, GameRoles, CommandBatches, CommandEntries],
)
class GamesDao extends DatabaseAccessor<AppDatabase> with _$GamesDaoMixin {
  GamesDao(super.attachedDatabase);

  Future<int> createGame(
    IList<String> playerNames,
    GameConfiguration config,
    IMap<RoleType, ({Map<String, dynamic> config, int count})>
    rolesWithCountAndConfig,
  ) => transaction(() async {
    // Insert game and get id
    final id = await into(games)
        .insertReturning(GamesCompanion.insert(configuration: config))
        .then((game) => game.id);

    // Insert player names and get their ids
    final playerNamesIds = await attachedDatabase.playerNamesDao.insertNames(
      playerNames,
    );
    assert(
      playerNamesIds.length == playerNames.length,
      'All player names should have an id at this point',
    );

    final sortedPlayerNamesIds = playerNamesIds
        .sortedBy((e) => playerNames.indexOf(e.name))
        .toList();

    // Insert game players
    await batch((batch) {
      batch.insertAll(
        gamePlayers,
        sortedPlayerNamesIds.indexed.map(
          (entry) => GamePlayersCompanion.insert(
            gameId: id,
            playerId: entry.$2.id,
            order: entry.$1,
          ),
        ),
      );
    });

    // Insert game roles
    await batch((batch) {
      batch.insertAll(
        gameRoles,
        rolesWithCountAndConfig.entries.map(
          (entry) => GameRolesCompanion.insert(
            gameId: id,
            role: entry.key,
            configuration: entry.value.config,
            count: entry.value.count,
          ),
        ),
      );
    });

    return id;
  });

  Future<void> endGame(
    int gameId, {
    required WinCondition? winner,
    required ISet<int> winnerIndices,
  }) => transaction(() async {
    await (update(games)..where((tbl) => tbl.id.equals(gameId))).write(
      GamesCompanion(
        endedAt: Value(DateTime.now()),
        winner: Value.absentIfNull(winner),
      ),
    );
    await batch((batch) {
      batch.update(
        gamePlayers,
        const GamePlayersCompanion(hasWon: Value(true)),
        where: (tbl) =>
            tbl.gameId.equals(gameId) & tbl.order.isIn(winnerIndices),
      );
    });
  });

  MultiSelectable<Game> getGames({bool? active, bool? archived}) {
    final query = select(games);

    final predicates = <Expression<bool> Function($GamesTable tbl)>[
      if (active != null)
        (tbl) => (active ? tbl.endedAt.isNull() : tbl.endedAt.isNotNull()),
      if (archived != null)
        (tbl) => tbl.archived.equalsExp(
          archived ? const Constant(true) : const Constant(false),
        ),
    ];

    if (predicates.isNotEmpty) {
      query.where(
        (tbl) => Expression.and(predicates.map((predFn) => predFn(tbl))),
      );
    }

    return query..orderBy([(tbl) => OrderingTerm.desc(tbl.startedAt)]);
  }

  Future<void> setGameArchived(int gameId, bool status) =>
      (update(games)..where((tbl) => tbl.id.equals(gameId))).write(
        GamesCompanion(archived: Value(status)),
      );

  Future<void> deleteGame(int gameId) =>
      (delete(games)..where((tbl) => tbl.id.equals(gameId))).go();

  Future<List<Game>> deleteArchivedGames() =>
      (delete(games)
            ..where((tbl) => tbl.archived.equalsExp(const Constant(true))))
          .goAndReturn();

  MultiSelectable<({String name, bool hasWon})> getOrderedPlayerNamesForGame(
    int gameId,
  ) =>
      (select(gamePlayers)
            ..where((tbl) => tbl.gameId.equals(gameId))
            ..orderBy([(tbl) => OrderingTerm(expression: tbl.order)]))
          .join([
            innerJoin(
              playerNames,
              playerNames.id.equalsExp(gamePlayers.playerId),
            ),
          ])
          .map(
            (row) => (
              name: row.readTable(playerNames).name,
              hasWon: row.readTable(gamePlayers).hasWon,
            ),
          );

  Future<Map<RoleType, ({RoleConfiguration config, int count})>>
  getRolesForGame(int gameId) async => Map.fromEntries(
    await (select(gameRoles)..where((tbl) => tbl.gameId.equals(gameId)))
        .map(
          (row) =>
              MapEntry(row.role, (count: row.count, config: row.configuration)),
        )
        .get(),
  );

  SingleOrNullSelectable<GameConfiguration> getGameConfiguration(int gameId) =>
      (select(
        games,
      )..where((tbl) => tbl.id.equals(gameId))).map((row) => row.configuration);

  Future<void> insertCommandBatch(
    int gameId,
    Iterable<GameCommand> commands,
  ) async {
    await transaction(() async {
      // clear redo stack
      await (delete(commandBatches)..where(
            (tbl) =>
                tbl.gameId.equals(gameId) &
                tbl.wasUndone.equalsExp(const Constant(true)),
          ))
          .go();

      final maxOrder =
          await (selectOnly(commandBatches)
                ..addColumns([commandBatches.orderInGame.max()])
                ..where(commandBatches.gameId.equals(gameId)))
              .map((row) => row.read(commandBatches.orderInGame.max()))
              .getSingle();

      final nextOrder = (maxOrder ?? -1) + 1;

      final batchId = await into(commandBatches)
          .insertReturning(
            CommandBatchesCompanion.insert(
              gameId: gameId,
              orderInGame: nextOrder,
            ),
          )
          .then((batch) => batch.id);

      await batch((batch) {
        batch.insertAll(
          commandEntries,
          commands.indexed.map((entry) {
            final (:type, :serializedData) = SerializedCommandData.fromCommand(
              entry.$2,
            );
            return CommandEntriesCompanion.insert(
              batchId: batchId,
              orderInBatch: entry.$1,
              type: type,
              data: serializedData,
            );
          }),
        );
      });
    });
  }

  Future<void> setBatchUndoStatus(
    int gameId,
    int batchOrder,
    bool wasUndone,
  ) async {
    await (update(commandBatches)..where(
          (tbl) =>
              tbl.gameId.equals(gameId) & tbl.orderInGame.equals(batchOrder),
        ))
        .write(CommandBatchesCompanion(wasUndone: Value(wasUndone)));
  }

  Future<({List<IList<GameCommand>> run, List<IList<GameCommand>> undone})>
  getCommandBatchesForGame(int gameId) async {
    final batches =
        await (select(commandBatches)
              ..where((tbl) => tbl.gameId.equals(gameId))
              ..orderBy([(tbl) => OrderingTerm(expression: tbl.orderInGame)]))
            .join([
              innerJoin(
                commandEntries,
                commandEntries.batchId.equalsExp(commandBatches.id),
              ),
            ])
            .map((row) {
              final batch = row.readTable(commandBatches);
              final entry = row.readTable(commandEntries);
              final command = entry.data.toCommand(entry.type);
              return (batch: batch, command: command);
            })
            .get();

    final batchesById = batches.groupListsBy((e) => e.batch.id);

    final run = <IList<GameCommand>>[];
    final undone = <IList<GameCommand>>[];

    for (final batchCommands in batchesById.values) {
      final commands = batchCommands
          .sortedBy((e) => e.batch.orderInGame)
          .map((e) => e.command)
          .toIList();
      if (batchCommands.first.batch.wasUndone) {
        undone.add(commands);
      } else {
        run.add(commands);
      }
    }

    return (run: run, undone: undone.reversed.toList());
  }
}

class SerializedCommandData {
  final Map<String, dynamic> data;

  const SerializedCommandData(this.data);

  GameCommand toCommand(String type) {
    data['type'] = type;
    return GameCommandMapper.fromJson(data);
  }

  static ({String type, SerializedCommandData serializedData}) fromCommand(
    GameCommand command,
  ) {
    final data = command.toJson();
    final type = data['type'] as String;
    data.remove('type');
    return (type: type, serializedData: SerializedCommandData(data));
  }
}

JsonTypeConverter2<SerializedCommandData, Uint8List, Object?>
commandBinaryConverter = TypeConverter.jsonb(
  fromJson: (json) => SerializedCommandData(json as Map<String, Object?>),
  toJson: (pref) {
    pref.data.remove('type');
    return pref.data;
  },
);

JsonTypeConverter2<WinCondition, Uint8List, Object?> winnerBinaryConverter =
    TypeConverter.jsonb(
      fromJson: (json) =>
          WinConditionMapper.fromJson(json as Map<String, Object?>),
      toJson: (pref) => pref.toJson(),
    );

class RoleTypeConverter extends TypeConverter<RoleType, String> {
  const RoleTypeConverter();

  @override
  RoleType fromSql(String fromDb) => RoleType.fromId(fromDb);

  @override
  String toSql(RoleType value) => value.id;
}

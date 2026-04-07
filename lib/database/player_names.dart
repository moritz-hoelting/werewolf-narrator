import 'package:drift/drift.dart';
import 'package:werewolf_narrator/database/database.dart';

part 'player_names.g.dart';

@TableIndex(name: 'name_suggestions', columns: {#name, #hideSuggestion})
class PlayerNames extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1).unique()();
  BoolColumn get hideSuggestion =>
      boolean().withDefault(const Constant(false))();

  @override
  bool get isStrict => true;
}

@DriftAccessor(tables: [PlayerNames])
class PlayerNamesDao extends DatabaseAccessor<AppDatabase>
    with _$PlayerNamesDaoMixin {
  PlayerNamesDao(super.attachedDatabase);

  Future<void> addNameSuggestions(List<String> names) async {
    await batch((batch) {
      batch.insertAll(
        playerNames,
        names.map((name) => PlayerNamesCompanion.insert(name: name)),
        onConflict: DoUpdate(
          (old) => const PlayerNamesCompanion(hideSuggestion: Value(false)),
          target: [playerNames.name],
        ),
      );
    });
  }

  Future<void> disableNameSuggestion(String name) async {
    await transaction(() async {
      final playerId =
          await (select(playerNames)..where((tbl) => tbl.name.equals(name)))
              .map((row) => row.id)
              .getSingleOrNull();
      if (playerId == null) {
        return;
      }
      final isUsedInGame =
          await (select(
            attachedDatabase.gamePlayers,
          )..where((gp) => gp.playerId.equals(playerId))).getSingleOrNull() !=
          null;
      if (isUsedInGame) {
        await (update(playerNames)..where((tbl) => tbl.id.equals(playerId)))
            .write(const PlayerNamesCompanion(hideSuggestion: Value(true)));
      } else {
        await (delete(
          playerNames,
        )..where((tbl) => tbl.id.equals(playerId))).go();
      }
    });
  }

  Future<List<String>> getAllNameSuggestionsStartingWith(String prefix) =>
      (select(playerNames)..where(
            (tbl) =>
                tbl.hideSuggestion.equals(false) &
                tbl.name.lower().like('${prefix.toLowerCase()}%'),
          ))
          .map((row) => row.name)
          .get();

  Stream<List<String>> watchAllNameSuggestions() =>
      (select(playerNames)..where((tbl) => tbl.hideSuggestion.equals(false)))
          .map((row) => row.name)
          .watch();

  void disableAllNameSuggestions() async {
    await transaction(() async {
      final query = selectOnly(attachedDatabase.gamePlayers);
      query
        ..addColumns([attachedDatabase.gamePlayers.playerId])
        ..groupBy([attachedDatabase.gamePlayers.playerId]);
      final playerIdsInUse = await query
          .map((row) => row.read<int>(attachedDatabase.gamePlayers.playerId)!)
          .get();
      await (delete(
        playerNames,
      )..where((tbl) => tbl.id.isIn(playerIdsInUse).not())).go();
      await (update(playerNames)..where((tbl) => tbl.id.isIn(playerIdsInUse)))
          .write(const PlayerNamesCompanion(hideSuggestion: Value(true)));
    });
  }

  Future<List<({int id, String name})>> insertNames(
    Iterable<String> names,
  ) async {
    await batch(
      (batch) => batch.insertAll(
        playerNames,
        names.map(
          (name) => PlayerNamesCompanion.insert(
            name: name,
            hideSuggestion: const Value(false),
          ),
        ),
        onConflict: DoNothing(target: [playerNames.name]),
      ),
    );

    return (select(playerNames)..where((tbl) => tbl.name.isIn(names)))
        .map((row) => (id: row.id, name: row.name))
        .get();
  }
}

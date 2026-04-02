import 'package:drift/drift.dart';
import 'package:werewolf_narrator/database/database.dart';

part 'name_cache.g.dart';

class NameCache extends Table {
  TextColumn get name => text().withLength(min: 1)();

  @override
  Set<Column> get primaryKey => {name};
}

@DriftAccessor(tables: [NameCache])
class NameCacheDao extends DatabaseAccessor<AppDatabase>
    with _$NameCacheDaoMixin {
  NameCacheDao(super.attachedDatabase);

  void addNamesToCache(List<String> names) => batch((batch) {
    batch.insertAll(
      nameCache,
      names.map((name) => NameCacheData(name: name)).toList(),
      mode: InsertMode.insertOrIgnore,
    );
  });

  void deleteNameFromCache(String name) =>
      (delete(nameCache)..where((tbl) => tbl.name.equals(name))).go();

  Future<List<String>> getAllNamesStartingWith(String prefix) =>
      (select(
            nameCache,
          )..where((tbl) => tbl.name.lower().like('${prefix.toLowerCase()}_%')))
          .map((row) => row.name)
          .get();

  Stream<List<String>> watchAllNames() =>
      select(nameCache).map((row) => row.name).watch();

  void emptyCache() => delete(nameCache).go();
}

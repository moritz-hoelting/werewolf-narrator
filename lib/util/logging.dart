import 'package:drift/drift.dart'
    show
        BatchedStatements,
        QueryExecutor,
        QueryInterceptor,
        TransactionExecutor;
import 'package:talker_flutter/talker_flutter.dart';

final Talker logger = TalkerFlutter.init(
  filter: TalkerFilter(disabledKeys: [DatabaseLog.keyValue]),
  settings: TalkerSettings(timeFormat: TimeFormat.yearMonthDayAndTime),
);

extension LoggerExtensions on Talker {
  bool get hasLogsRelevantToUser => history.any(_logRelevantToUser);

  int get relevantUserLogCount => history.where(_logRelevantToUser).length;
}

Set<LogLevel> _relevantLogLevels = {
  LogLevel.critical,
  LogLevel.error,
  LogLevel.warning,
};

bool _logRelevantToUser(TalkerData data) {
  return data.logLevel != null && _relevantLogLevels.contains(data.logLevel!);
}

class TalkerQueryInterceptor extends QueryInterceptor {
  TalkerQueryInterceptor(this.talker);

  final Talker talker;

  @override
  TransactionExecutor beginTransaction(QueryExecutor parent) {
    _log('Beginning database transaction');
    return super.beginTransaction(parent);
  }

  @override
  Future<void> rollbackTransaction(TransactionExecutor inner) {
    _log('Rolling back database transaction');
    return super.rollbackTransaction(inner);
  }

  @override
  Future<void> commitTransaction(TransactionExecutor inner) {
    _log('Committing database transaction');
    return super.commitTransaction(inner);
  }

  @override
  Future<void> close(QueryExecutor inner) async {
    _log('Closing database connection');
    await super.close(inner);
    _log('Database connection closed');
  }

  @override
  Future<void> runBatched(
    QueryExecutor executor,
    BatchedStatements statements,
  ) {
    _log('Running batched queries: $statements');
    return super.runBatched(executor, statements);
  }

  @override
  Future<void> runCustom(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    _log('Running custom query: $statement with args: $args');
    return super.runCustom(executor, statement, args);
  }

  @override
  Future<int> runDelete(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    _log('Running delete query: $statement with args: $args');
    return super.runDelete(executor, statement, args);
  }

  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    _log('Running insert query: $statement with args: $args');
    return super.runInsert(executor, statement, args);
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    _log('Executing query: $statement with args: $args');
    return super.runSelect(executor, statement, args);
  }

  @override
  Future<int> runUpdate(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    _log('Running update query: $statement with args: $args');
    return super.runUpdate(executor, statement, args);
  }

  @override
  QueryExecutor beginExclusive(QueryExecutor parent) {
    _log('Beginning exclusive database access');
    return super.beginExclusive(parent);
  }

  @override
  bool transactionCanBeNested(TransactionExecutor inner) {
    final canBeNested = super.transactionCanBeNested(inner);
    _log('Transaction can be nested: $canBeNested');
    return canBeNested;
  }

  void _log(String message) {
    talker.logCustom(DatabaseLog(message));
  }
}

class DatabaseLog extends TalkerLog {
  DatabaseLog(super.message) : super(logLevel: LogLevel.verbose);

  static const String keyValue = 'db';

  @override
  AnsiPen? get pen => AnsiPen()..cyan();

  @override
  String? get key => keyValue;

  @override
  String get title => 'database';
}

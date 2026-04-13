import 'package:flutter/material.dart';
import 'package:restart_app/restart_app.dart';
import 'package:werewolf_narrator/database/database.dart'
    show AppDatabaseHolder;

class ErrorLoadingDb extends StatelessWidget {
  const ErrorLoadingDb({
    required this.error,
    required this.dbHolder,
    super.key,
  });

  final Object error;
  final AppDatabaseHolder dbHolder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(child: Text('Error initializing database: $error')),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(60),
          ),
          onPressed: () async {
            await dbHolder.recreateDatabase();
            await Restart.restartApp();
          },
          label: const Text('Delete and recreate database'),
          icon: const Icon(Icons.delete),
        ),
      ),
    );
  }
}

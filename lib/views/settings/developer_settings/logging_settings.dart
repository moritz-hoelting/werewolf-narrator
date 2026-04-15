import 'package:flutter/material.dart';
import 'package:provider/provider.dart' show Consumer;
import 'package:werewolf_narrator/util/developer_settings.dart'
    show DeveloperSettings;

class LogSettingsDialog extends StatelessWidget {
  const LogSettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Logging Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Show database logs'),
            subtitle: const Text('Toggle logging of database queries'),
            trailing: Consumer<DeveloperSettings>(
              builder: (context, settings, child) => Switch(
                value: settings.logDatabaseQueries,
                onChanged: (value) {
                  settings.logDatabaseQueries = value;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

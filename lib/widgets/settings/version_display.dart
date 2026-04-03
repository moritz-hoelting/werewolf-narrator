import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/util/developer_settings.dart';

class VersionDisplay extends StatefulWidget {
  const VersionDisplay({required this.packageInfo, super.key});

  final PackageInfo packageInfo;

  @override
  State<VersionDisplay> createState() => _VersionDisplayState();
}

class _VersionDisplayState extends State<VersionDisplay> {
  final List<DateTime> _clickTimes = [];

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return ListTile(
      title: Text(localizations.screen_settings_version),
      leading: const Icon(Icons.info_outline),
      subtitle: Text(widget.packageInfo.version),
      onTap: () {
        final now = DateTime.now();
        _clickTimes.add(now);

        if (_clickTimes.length < 5) {
          // Remove clicks that are older than 10 second
          _clickTimes.removeWhere(
            (time) => now.difference(time) > const Duration(seconds: 10),
          );
        } else if (_clickTimes.length >= 10) {
          Provider.of<DeveloperSettings>(context, listen: false).enabled = true;
          _clickTimes.clear();
        } else if (_clickTimes.length == 5) {
          final messenger = ScaffoldMessenger.of(context);
          messenger.clearSnackBars();
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'Click ${10 - _clickTimes.length} more times to enable developer settings!',
              ),
            ),
          );
        }
      },
    );
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:werewolf_narrator/database/database.dart'
    show AppDatabase, AppDatabaseHolder;
import 'package:werewolf_narrator/game/game_registry.g.dart' show GameRegistry;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/themes.dart';
import 'package:werewolf_narrator/util/developer_settings.dart';
import 'package:werewolf_narrator/util/fast_immutable_collections.dart';
import 'package:werewolf_narrator/util/flavors.dart';
import 'package:werewolf_narrator/util/logging.dart' show logger;
import 'package:werewolf_narrator/util/settings.dart';
import 'package:werewolf_narrator/views/error_loading_db.dart';
import 'package:werewolf_narrator/views/game.dart';
import 'package:werewolf_narrator/views/games_overview.dart';
import 'package:werewolf_narrator/views/roles_overview.dart';
import 'package:werewolf_narrator/views/settings.dart' show SettingsScreen;

void main() async {
  registerFastImmutableCollectionsMappers();

  WidgetsFlutterBinding.ensureInitialized();
  GameRegistry.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    logger.handle(
      details.exception,
      details.stack,
      'Flutter error in library ${details.library}',
    );
    if (kDebugMode || !appFlavor.isProd) {
      FlutterError.presentError(details);
    }
  };

  // Preload settings
  final dbHolder = AppDatabaseHolder();

  var errorLoadingDb = false;
  try {
    await AppSettings.init(dbHolder);
    unawaited(DeveloperSettings.init(dbHolder));
  } catch (e, st) {
    errorLoadingDb = true;
    logger.handle(e, st, 'Error initializing database');
    runApp(
      MaterialApp(
        home: ErrorLoadingDb(error: e, dbHolder: dbHolder),
      ),
    );
  }

  if (!errorLoadingDb) {
    runApp(
      ChangeNotifierProvider(
        create: (context) => dbHolder,
        builder: (context, child) =>
            ProxyProvider<AppDatabaseHolder, AppDatabase>(
              update: (context, holder, previous) => holder.database,
              child: const WerewolfNarratorApp(),
            ),
      ),
    );
  }
}

class WerewolfNarratorApp extends StatelessWidget {
  const WerewolfNarratorApp({super.key});

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => AppSettings.instance),
      ChangeNotifierProvider(create: (context) => DeveloperSettings.instance),
    ],
    child: Consumer<AppSettings>(
      builder: (context, settings, child) => MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        theme: Themes.lightThemeForMaterialApp(settings),
        darkTheme: Themes.darkThemeForMaterialApp(settings),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: settings.locale,
        home: TalkerWrapper(
          talker: logger,
          options: const TalkerWrapperOptions(enableErrorAlerts: true),
          child: const HomePage(),
        ),
      ),
    ),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.inversePrimary,
        title: Text(localizations.appTitle),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          primary: true,
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 50,
                children: [
                  SvgPicture.asset(
                    'assets/icon/icon.svg',
                    width: 200,
                    height: 200,
                  ),
                  const _MainMenuButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MainMenuButtons extends StatelessWidget {
  const _MainMenuButtons();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return SizedBox(
      width: 200,
      child: Column(
        spacing: 16,
        children: [
          // Start new game button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              label: Text(localizations.button_newGameLabel),
              icon: const Icon(Icons.play_arrow),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const GameView()),
                );
              },
              style: ElevatedButton.styleFrom(
                elevation: 8,
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 40),
                tapTargetSize: MaterialTapTargetSize.padded,
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Game overview button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              label: Text(localizations.screen_gamesOverview_title),
              icon: const Icon(Icons.history),
              style: ElevatedButton.styleFrom(
                elevation: 4,
                padding: const EdgeInsets.symmetric(vertical: 25),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const GamesOverview(),
                  ),
                );
              },
            ),
          ),

          // Roles overview button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              label: Text(localizations.screen_rolesOverview_title),
              icon: const Icon(Icons.person),
              style: ElevatedButton.styleFrom(
                elevation: 4,
                padding: const EdgeInsets.symmetric(vertical: 25),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const RolesOverviewScreen(),
                  ),
                );
              },
            ),
          ),

          // Settings button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              label: Text(localizations.screen_settings_title),
              icon: const Icon(Icons.settings),
              style: ElevatedButton.styleFrom(
                elevation: 4,
                padding: const EdgeInsets.symmetric(vertical: 25),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

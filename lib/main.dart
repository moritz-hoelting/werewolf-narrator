import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/model/team.dart';
import 'package:werewolf_narrator/themes.dart';
import 'package:werewolf_narrator/util/developer_settings.dart';
import 'package:werewolf_narrator/util/settings.dart';
import 'package:werewolf_narrator/views/game.dart';
import 'package:werewolf_narrator/views/roles_overview.dart';
import 'package:werewolf_narrator/views/settings.dart' show SettingsScreen;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Register roles and screens
  RoleManager.ensureRegistered();
  TeamManager.ensureRegistered();

  // Preload settings
  AppSettings.instance;
  DeveloperSettings.instance;

  runApp(const WerewolfNarratorApp());
}

class WerewolfNarratorApp extends StatelessWidget {
  const WerewolfNarratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
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
          home: const HomePage(),
        ),
      ),
    );
  }
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 50,
          children: [
            SvgPicture.asset('assets/icon/icon.svg', width: 200, height: 200),
            SizedBox(
              width: 200,
              child: Column(
                spacing: 16,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      label: Text(localizations.button_newGameLabel),
                      icon: Icon(Icons.play_arrow),
                      onPressed: () => _startNewGame(context),
                      style: ElevatedButton.styleFrom(
                        elevation: 8,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 50),
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      label: Text(localizations.screen_rolesOverview_title),
                      icon: Icon(Icons.person),
                      style: ElevatedButton.styleFrom(
                        elevation: 4,
                        padding: const EdgeInsets.symmetric(vertical: 20),
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      label: Text(localizations.screen_settings_title),
                      icon: Icon(Icons.settings),
                      style: ElevatedButton.styleFrom(
                        elevation: 4,
                        padding: const EdgeInsets.symmetric(vertical: 20),
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
            ),
          ],
        ),
      ),
    );
  }

  void _startNewGame(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const GameView()));
  }
}

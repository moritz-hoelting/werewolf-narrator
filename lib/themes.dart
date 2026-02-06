import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/util/settings.dart';

class Themes {
  static final ThemeData lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.light,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.dark,
    ),
  );

  static ThemeData lightThemeForMaterialApp(AppSettings settings) {
    switch (settings.themeMode) {
      case ThemeMode.light:
        return lightTheme;
      case ThemeMode.dark:
        return darkTheme;
      case ThemeMode.system:
        return lightTheme;
    }
  }

  static ThemeData darkThemeForMaterialApp(AppSettings settings) {
    switch (settings.themeMode) {
      case ThemeMode.light:
        return lightTheme;
      case ThemeMode.dark:
        return darkTheme;
      case ThemeMode.system:
        return darkTheme;
    }
  }

  static ThemeData systemTheme(BuildContext context) =>
      MediaQuery.of(context).platformBrightness == Brightness.dark
      ? darkTheme
      : lightTheme;

  static ThemeData lightThemeBySettings(BuildContext context) {
    switch (Provider.of<AppSettings>(context).themeMode) {
      case ThemeMode.light:
        return lightTheme;
      case ThemeMode.dark:
        return darkTheme;
      case ThemeMode.system:
        return systemTheme(context);
    }
  }

  static ThemeData darkThemeBySettings(BuildContext context) {
    switch (Provider.of<AppSettings>(context).themeMode) {
      case ThemeMode.light:
        return lightTheme;
      case ThemeMode.dark:
        return darkTheme;
      case ThemeMode.system:
        return systemTheme(context);
    }
  }

  static ThemeData daytimeTheme(BuildContext context) =>
      Provider.of<AppSettings>(context).dynamicGameTheme
      ? lightTheme
      : lightThemeBySettings(context);

  static ThemeData nighttimeTheme(BuildContext context) =>
      Provider.of<AppSettings>(context).dynamicGameTheme
      ? darkTheme
      : darkThemeBySettings(context);
}

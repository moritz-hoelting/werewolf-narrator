import 'package:flutter/material.dart';

extension LocaleExtension on Locale {
  String get displayName {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'de':
        return 'Deutsch';
      default:
        return languageCode;
    }
  }
}

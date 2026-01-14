import 'package:flutter/material.dart';

enum Winner {
  village,
  werewolves,
  lovers;

  String name(BuildContext context) {
    switch (this) {
      case Winner.village:
        return 'Village';
      case Winner.werewolves:
        return 'Werewolves';
      case Winner.lovers:
        return 'Lovers';
    }
  }
}

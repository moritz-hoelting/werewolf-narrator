import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart' show TalkerScreen;
import 'package:werewolf_narrator/util/logging.dart' show logger;

class AppTalkerScreen extends StatelessWidget {
  const AppTalkerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TalkerScreen(talker: logger);
  }
}

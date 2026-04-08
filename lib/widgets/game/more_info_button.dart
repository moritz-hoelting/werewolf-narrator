import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/game/game_state.dart';

class MoreInfoButton extends StatelessWidget {
  const MoreInfoButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) => IconButton(
        onPressed: () {
          gameState.additionalInformationVisible =
              !gameState.additionalInformationVisible;
        },
        icon: Icon(
          gameState.additionalInformationVisible
              ? Icons.visibility
              : Icons.visibility_off,
        ),
      ),
    );
  }
}

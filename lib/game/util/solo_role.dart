import 'package:werewolf_narrator/game/game_state.dart';

bool soloRoleHasWon(GameState gameState, int playerIndex) =>
    gameState.alivePlayerCount == 1 && gameState.players[playerIndex].isAlive;

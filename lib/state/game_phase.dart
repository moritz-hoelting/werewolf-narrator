enum GamePhase {
  dusk,
  checkRoles,
  nightActions,
  dawn,
  sheriffElection,
  voting,

  gameOver;

  bool get isNight =>
      index >= GamePhase.dusk.index && index < GamePhase.dawn.index;
}

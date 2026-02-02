enum GamePhase {
  dusk,
  checkRoles,
  nightActions,
  dawn,
  dayActions,

  gameOver;

  bool get isNight =>
      index >= GamePhase.dusk.index && index < GamePhase.dawn.index;
}

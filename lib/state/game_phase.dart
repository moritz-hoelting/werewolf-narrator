enum GamePhase {
  dusk,
  checkRoles,
  thief,
  cupid,
  seer,
  werewolves,
  witch,
  dawn,
  sheriffElection,
  voting,

  gameOver;

  bool get isNight =>
      index >= GamePhase.dusk.index && index < GamePhase.dawn.index;
}

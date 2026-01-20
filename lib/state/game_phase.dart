enum GamePhase {
  dusk,
  checkRoleSeer,
  checkRoleWitch,
  checkRoleHunter,
  checkRoleCupid,
  checkRoleLittleGirl,
  checkRoleWerewolves,
  checkRoleThief,
  thief,
  cupid,
  lovers,
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

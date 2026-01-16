enum GamePhase {
  dusk,
  checkRoleSeer,
  checkRoleWitch,
  checkRoleHunter,
  checkRoleCupid,
  checkRoleLittleGirl,
  checkRoleWerewolves,
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

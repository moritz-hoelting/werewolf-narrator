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
  voting,

  gameOver;

  bool get isNight => this != dawn && this != voting;
}

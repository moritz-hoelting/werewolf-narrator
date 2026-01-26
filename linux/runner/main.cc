#include "werewolf_narrator.h"

int main(int argc, char** argv) {
  g_autoptr(WerewolfNarratorApp) app = werewolf_narrator_app_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}

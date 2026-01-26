#ifndef FLUTTER_WEREWOLF_NARRATOR_H_
#define FLUTTER_WEREWOLF_NARRATOR_H_

#include <gtk/gtk.h>

G_DECLARE_FINAL_TYPE(WerewolfNarratorApp, werewolf_narrator_app, WEREWOLF_NARRATOR, APP,
                     GtkApplication)

/**
 * werewolf_narrator_app_new:
 *
 * Creates a new Flutter-based application.
 *
 * Returns: a new #WerewolfNarratorApp.
 */
WerewolfNarratorApp* werewolf_narrator_app_new();

#endif  // FLUTTER_WEREWOLF_NARRATOR_H_
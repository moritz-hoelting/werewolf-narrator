import 'package:flutter/material.dart';
import 'package:werewolf_narrator/game/model/death_information.dart';
import 'package:werewolf_narrator/game/model/win_condition.dart'
    show WinCondition;
import 'package:werewolf_narrator/game/game_state.dart';

typedef DawnHook = void Function(GameState gameState, int dayCount);

typedef DeathHook =
    bool Function(GameState gameState, int playerIndex, DeathReason reason);

typedef ReviveHook = bool Function(GameState gameState, int playerIndex);

typedef PlayerDisplayHook =
    PlayerDisplayData? Function(
      GameState gameState,
      Object? phaseIdentifier,
      int playerIndex,
    );

typedef RemainingRoleHook =
    void Function(GameState gameState, int remainingCount);

typedef PlayerWinHook =
    bool? Function(GameState gameState, WinCondition winner, int playerIndex);

class PlayerDisplayData {
  PlayerDisplayData({
    this.disabled = false,
    this.trailing,
    this.subtitle,
    this.selectedTileColor,
    this.tileColor,
  });

  final bool disabled;
  final WidgetBuilder? trailing;
  final WidgetBuilder? subtitle;

  final Color? selectedTileColor;
  final Color? tileColor;

  static PlayerDisplayData merge(Iterable<PlayerDisplayData> list) {
    bool disabled = false;
    List<WidgetBuilder> trailing = [];
    List<WidgetBuilder> subtitle = [];
    Color? selectedTileColor;
    Color? tileColor;

    for (final data in list) {
      // disabled
      disabled |= data.disabled;

      // trailing
      if (data.trailing != null) {
        trailing.add(data.trailing!);
      }

      // subtitle
      if (data.subtitle != null) {
        subtitle.add(data.subtitle!);
      }

      // selectedTileColor
      selectedTileColor ??= data.selectedTileColor;

      // tileColor
      tileColor ??= data.tileColor;
    }

    return PlayerDisplayData(
      disabled: disabled,
      trailing: trailing.isEmpty
          ? null
          : (trailing.length == 1
                ? trailing.single
                : (context) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: trailing
                          .map((builder) => builder(context))
                          .toList(),
                    );
                  }),
      subtitle: subtitle.isEmpty
          ? null
          : (subtitle.length == 1
                ? subtitle.single
                : (context) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: subtitle
                          .map((builder) => builder(context))
                          .toList(),
                    );
                  }),
      selectedTileColor: selectedTileColor,
      tileColor: tileColor,
    );
  }
}

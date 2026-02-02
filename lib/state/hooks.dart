import 'package:flutter/material.dart';
import 'package:werewolf_narrator/model/death_information.dart';
import 'package:werewolf_narrator/state/game.dart';
import 'package:werewolf_narrator/team/team.dart';

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
    bool? Function(GameState gameState, Team winningTeam, int playerIndex);

class PlayerDisplayData {
  PlayerDisplayData({this.disabled = false, this.trailing, this.subtitle});

  final bool disabled;
  final WidgetBuilder? trailing;
  final WidgetBuilder? subtitle;

  static PlayerDisplayData merge(Iterable<PlayerDisplayData> list) {
    bool disabled = false;
    List<WidgetBuilder> trailing = [];
    List<WidgetBuilder> subtitle = [];

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
    }

    return PlayerDisplayData(
      disabled: disabled,
      trailing: trailing.isEmpty
          ? null
          : (trailing.length == 1
                ? trailing.first
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
                ? subtitle.first
                : (context) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: subtitle
                          .map((builder) => builder(context))
                          .toList(),
                    );
                  }),
    );
  }
}

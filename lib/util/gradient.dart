import 'package:flutter/material.dart';

/// A gradient transform that scales the gradient by the given factors
class ScaleGradient extends GradientTransform {
  const ScaleGradient({required this.scaleX, required this.scaleY});

  final double scaleX;
  final double scaleY;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final centerX = bounds.left + bounds.width / 2;
    final bottomY = bounds.bottom;

    return Matrix4.identity()
      ..translateByDouble(centerX, bottomY, 0, 1)
      ..scaleByDouble(scaleX, scaleY, 1.0, 1.0)
      ..translateByDouble(-centerX, -bottomY, 0, 1);
  }
}

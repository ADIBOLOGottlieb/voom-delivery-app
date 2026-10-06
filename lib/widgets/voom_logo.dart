import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Logo VOOM Delivery (moto stylisée formant « VOOM », jaune / noir / blanc).
///
/// Pour utiliser le fichier officiel, remplacer `assets/images/voom_logo.svg`.
class VoomLogo extends StatelessWidget {
  final double width;

  const VoomLogo({super.key, this.width = 220});

  static const asset = 'assets/images/voom_logo.svg';

  /// Proportions du logo (viewBox 420 × 150).
  static const aspectRatio = 420 / 150;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: width,
      height: width / aspectRatio,
      semanticsLabel: 'VOOM Delivery',
    );
  }
}

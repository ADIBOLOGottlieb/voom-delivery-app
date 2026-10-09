import 'package:flutter/material.dart';

/// Logo officiel VOOM (moto stylisée en épingle de localisation).
///
/// - [VoomLogo] : version horizontale, pour fonds clairs ;
/// - [VoomLogo.stacked] : moto au-dessus du mot VOOM (écrans d'accueil) ;
/// - [VoomLogo.light] : texte blanc, pour fonds noirs.
class VoomLogo extends StatelessWidget {
  final double width;
  final String asset;

  const VoomLogo({super.key, this.width = 220}) : asset = 'assets/images/voom_logo.png';

  const VoomLogo.stacked({super.key, this.width = 220}) : asset = 'assets/images/voom_logo_stacked.png';

  const VoomLogo.light({super.key, this.width = 220}) : asset = 'assets/images/voom_logo_light.png';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'VOOM Delivery',
      image: true,
      child: Image.asset(asset, width: width, fit: BoxFit.contain, filterQuality: FilterQuality.medium),
    );
  }
}

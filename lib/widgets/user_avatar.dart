import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/user.dart';
import '../utils/colors.dart';

/// Photo de profil, ou initiale sur fond noir à défaut.
class UserAvatar extends StatelessWidget {
  final User? user;
  final double radius;

  const UserAvatar({super.key, required this.user, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    final url = user?.avatarUrl;
    final initial = Text(
      user?.initial ?? 'U',
      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: radius * 0.8),
    );

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.secondary,
      child: url == null
          ? initial
          : ClipOval(
              child: CachedNetworkImage(
                imageUrl: url,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                placeholder: (_, __) => initial,
                errorWidget: (_, __, ___) => initial,
              ),
            ),
    );
  }
}

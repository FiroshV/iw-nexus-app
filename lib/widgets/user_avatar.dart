import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String? firstName;
  final String? lastName;
  final double radius;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final VoidCallback? onTap;
  final bool showCameraIcon;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    this.firstName,
    this.lastName,
    this.radius = 20,
    this.backgroundColor,
    this.textStyle,
    this.onTap,
    this.showCameraIcon = false,
  });

  String _getUserInitials() {
    final first = firstName?.isNotEmpty == true ? firstName![0].toUpperCase() : '';
    final last = lastName?.isNotEmpty == true ? lastName![0].toUpperCase() : '';
    
    if (first.isNotEmpty && last.isNotEmpty) {
      return '$first$last';
    } else if (first.isNotEmpty) {
      return first;
    } else if (last.isNotEmpty) {
      return last;
    }
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    final Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? const Color(0xFF5cfbd8),
      backgroundImage: avatarUrl?.isNotEmpty == true
          ? CachedNetworkImageProvider(avatarUrl!)
          : null,
      child: avatarUrl?.isNotEmpty != true
          ? Text(
              _getUserInitials(),
              style: textStyle ?? TextStyle(
                color: const Color(0xFF272579),
                fontSize: radius * 0.6,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );

    if (onTap != null || showCameraIcon) {
      return Stack(
        children: [
          GestureDetector(
            onTap: onTap,
            child: avatar,
          ),
          if (showCameraIcon)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(radius * 0.1),
                decoration: const BoxDecoration(
                  color: Color(0xFF272579),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt,
                  size: radius * 0.4,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      );
    }

    return avatar;
  }
}

class UserAvatarWithUpload extends StatelessWidget {
  final String? avatarUrl;
  final String? firstName;
  final String? lastName;
  final double radius;
  final VoidCallback onTap;
  final bool isLoading;

  const UserAvatarWithUpload({
    super.key,
    required this.onTap,
    this.avatarUrl,
    this.firstName,
    this.lastName,
    this.radius = 40,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        UserAvatar(
          avatarUrl: avatarUrl,
          firstName: firstName,
          lastName: lastName,
          radius: radius,
          onTap: onTap,
          showCameraIcon: true,
        ),
        if (isLoading)
          Positioned.fill(
            child: CircleAvatar(
              radius: radius,
              backgroundColor: Colors.black54,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: radius * 0.05,
              ),
            ),
          ),
      ],
    );
  }
}
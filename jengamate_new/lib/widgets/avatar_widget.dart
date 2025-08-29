import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AvatarWidget extends StatelessWidget {
  final String? photoUrl;
  final String? displayName;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AvatarWidget({
    super.key,
    this.photoUrl,
    this.displayName,
    this.radius = 20,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // If photoUrl is available, use CachedNetworkImage for better performance and error handling
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: photoUrl!,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: radius,
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) => CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor ?? theme.primaryColor.withValues(alpha: 0.1),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              foregroundColor ?? theme.primaryColor,
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildFallbackAvatar(context),
      );
    }

    // Fallback to default avatar
    return _buildFallbackAvatar(context);
  }

  Widget _buildFallbackAvatar(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.primaryColor.withValues(alpha: 0.1);
    final fgColor = foregroundColor ?? theme.primaryColor;

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: displayName != null && displayName!.isNotEmpty
          ? Text(
              displayName![0].toUpperCase(),
              style: TextStyle(
                color: fgColor,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.8,
              ),
            )
          : Icon(
              Icons.person,
              color: fgColor,
              size: radius * 1.2,
            ),
    );
  }
}
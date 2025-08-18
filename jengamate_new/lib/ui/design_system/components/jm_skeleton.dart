import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class JMSkeleton extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius borderRadius;
  final bool isLoading;
  final Widget? child;

  const JMSkeleton({
    super.key, 
    required this.height, 
    this.width, 
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.isLoading = true,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return child ?? const SizedBox();
    }

    final baseColor = Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(102); // 40% alpha: 0.4);
    final highlightColor = Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(204); // 80% alpha: 0.8);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

class JMSkeletonList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final double spacing;

  const JMSkeletonList({
    super.key,
    this.itemCount = 3,
    this.itemHeight = 80,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (context, index) => SizedBox(height: spacing),
      itemBuilder: (context, index) => JMSkeleton(height: itemHeight),
    );
  }
}

class JMSkeletonCard extends StatelessWidget {
  final double height;
  final bool isLoading;
  final Widget? child;

  const JMSkeletonCard({
    super.key,
    this.height = 120,
    this.isLoading = true,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return JMSkeleton(
      height: height,
      borderRadius: BorderRadius.circular(12),
      isLoading: isLoading,
      child: child,
    );
  }
}

class JMSkeletonAvatar extends StatelessWidget {
  final double size;
  final bool isLoading;
  final Widget? child;

  const JMSkeletonAvatar({
    super.key,
    this.size = 48,
    this.isLoading = true,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return JMSkeleton(
      height: size,
      width: size,
      borderRadius: BorderRadius.circular(size / 2),
      isLoading: isLoading,
      child: child,
    );
  }
}

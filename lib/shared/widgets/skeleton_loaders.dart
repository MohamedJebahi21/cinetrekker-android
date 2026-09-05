import 'package:flutter/material.dart';

class AppSkeletonBox extends StatefulWidget {
  const AppSkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = BorderRadius.zero,
  });

  final double? width;
  final double height;
  final BorderRadius borderRadius;

  @override
  State<AppSkeletonBox> createState() => _AppSkeletonBoxState();
}

class _AppSkeletonBoxState extends State<AppSkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _controller.stop();
      _controller.value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.secondary; // Muted color
    final highlightColor = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.12); // Muted foreground opacity

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final shimmerOffset = _controller.value * 2 - 1;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment(shimmerOffset - 1, 0),
              end: Alignment(shimmerOffset, 0),
              colors: [
                baseColor,
                Color.lerp(baseColor, highlightColor, 0.45)!,
                baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

class PosterRailSkeleton extends StatelessWidget {
  const PosterRailSkeleton({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSkeletonBox(
          width: 180,
          height: 24,
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: itemCount,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return SizedBox(
                width: 160,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppSkeletonBox(
                      width: 160,
                      height: 240,
                      borderRadius: BorderRadius.all(Radius.circular(18)),
                    ),
                    const SizedBox(height: 8),
                    const AppSkeletonBox(
                      width: 140,
                      height: 14,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    const SizedBox(height: 6),
                    AppSkeletonBox(
                      width: index.isEven ? 110 : 90,
                      height: 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class DetailsHeaderSkeleton extends StatelessWidget {
  const DetailsHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSkeletonBox(
          width: 120,
          height: 180,
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSkeletonBox(
                height: 28,
                borderRadius: BorderRadius.all(Radius.circular(6)),
              ),
              const SizedBox(height: 8),
              const AppSkeletonBox(
                width: 180,
                height: 16,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              const SizedBox(height: 8),
              const AppSkeletonBox(
                width: 120,
                height: 16,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

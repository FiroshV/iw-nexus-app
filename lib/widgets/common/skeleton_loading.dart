import 'package:flutter/material.dart';

/// Shimmer skeleton loading widget for placeholder UI
class SkeletonLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoading({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  State<SkeletonLoading> createState() => _SkeletonLoadingState();
}

class _SkeletonLoadingState extends State<SkeletonLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: const [
                Color(0xFFEEEEEE),
                Color(0xFFF5F5F5),
                Color(0xFFEEEEEE),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton card that mimics dashboard card shape
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoading(height: 40, width: 40, borderRadius: 10),
          SizedBox(height: 12),
          SkeletonLoading(height: 14, width: 100),
          SizedBox(height: 8),
          SkeletonLoading(height: 10, width: 140),
        ],
      ),
    );
  }
}

/// Skeleton list item that mimics a service/list card
class SkeletonListItem extends StatelessWidget {
  const SkeletonListItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        children: [
          SkeletonLoading(height: 44, width: 44, borderRadius: 12),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoading(height: 14, width: 120),
                SizedBox(height: 6),
                SkeletonLoading(height: 10, width: 180),
              ],
            ),
          ),
          SkeletonLoading(height: 16, width: 16, borderRadius: 4),
        ],
      ),
    );
  }
}

/// Skeleton dashboard for the Home tab loading state
class SkeletonDashboard extends StatelessWidget {
  const SkeletonDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting skeleton
          SkeletonLoading(height: 24, width: 200),
          SizedBox(height: 4),
          SkeletonLoading(height: 14, width: 160),
          SizedBox(height: 16),
          // Attendance strip skeleton
          SkeletonLoading(height: 80, borderRadius: 16),
          SizedBox(height: 16),
          // Quick chips skeleton
          SkeletonLoading(height: 36, borderRadius: 20),
          SizedBox(height: 16),
          // Grid skeleton
          Row(
            children: [
              Expanded(child: SkeletonCard()),
              SizedBox(width: 16),
              Expanded(child: SkeletonCard()),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: SkeletonCard()),
              SizedBox(width: 16),
              Expanded(child: SkeletonCard()),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton list for screens that show list data
class SkeletonList extends StatelessWidget {
  final int itemCount;

  const SkeletonList({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: List.generate(
          itemCount,
          (index) => const SkeletonListItem(),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'user_avatar.dart';

enum CardType { idCard, visitingCard }

class IDCardWidget extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final VoidCallback? onShare;
  final VoidCallback? onShareVisitingCard;
  final bool showFullCard;
  final bool showWelcomeCard;
  final bool compact;
  final CardType cardType;

  const IDCardWidget({
    super.key,
    this.userData,
    this.onShare,
    this.onShareVisitingCard,
    this.showFullCard = false,
    this.showWelcomeCard = false,
    this.compact = false,
    this.cardType = CardType.idCard,
  });

  @override
  State<IDCardWidget> createState() => _IDCardWidgetState();
}

class _IDCardWidgetState extends State<IDCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flipAnimation;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (!_isFlipped) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      _isFlipped = !_isFlipped;
    });
    
    HapticFeedback.lightImpact();
  }


  String _getUserDisplayName() {
    if (widget.userData == null) return 'User';
    final firstName = widget.userData!['firstName']?.toString() ?? '';
    final lastName = widget.userData!['lastName']?.toString() ?? '';
    final fullName = '$firstName $lastName'.trim();
    return fullName.isNotEmpty ? fullName : 'User';
  }

  Widget _getEmploymentStatusTag() {
    debugPrint('User employmentType: ${widget.userData?['employmentType']?.toString()}');
    final employmentType = widget.userData?['employmentType']?.toString() ?? 'permanent';
    final isTemporary = employmentType.toLowerCase() == 'temporary';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isTemporary ? () {
        HapticFeedback.lightImpact();
        _showTemporaryInfoDialog();
      } : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isTemporary
            ? const Color(0xFFFF9800).withValues(alpha: 0.9)
            : const Color(0xFF5cfbd8),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isTemporary) ...[
              Icon(
                Icons.info_outline,
                size: 10,
                color: const Color(0xFF272579),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              employmentType.toUpperCase(),
              style: TextStyle(
                color: const Color(0xFF272579),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTemporaryInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: const Color(0xFF272579),
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Temporary Employment Status',
                  style: const TextStyle(
                    color: Color(0xFF272579),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          content: const Text(
            'You are currently under temporary employment status based on performance evaluation criteria. Your status may be reviewed and updated based on performance milestones and company requirements.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF272579),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text(
                'Close',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFrontCard() {
    if (widget.cardType == CardType.visitingCard) {
      return _buildVisitingCardFront();
    } else if (widget.showWelcomeCard) {
      return _buildWelcomeCard();
    }
    return _buildFullIdCard();
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF272579), Color(0xFF0071bf)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              _getEmploymentStatusTag(),
            ],
          ),
          Text(
            widget.userData != null
                ? '${widget.userData!['firstName'] ?? ''} ${widget.userData!['lastName'] ?? ''}'
                      .trim()
                : 'User',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (widget.userData != null) ...[
            Text(
              '${widget.userData!['designation'] ?? ''}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
          
          // Subtle tap hint
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Tap for ID card & visiting card actions',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullIdCard() {
    final c = widget.compact;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(c ? 16 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF272579), Color(0xFF0071bf)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(c ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company Logo and Text (hidden in compact mode)
          if (!c) ...[
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SvgPicture.asset(
                    'assets/company_logo.svg',
                    width: 24,
                    height: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Move with',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        'Strategy',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // User Photo
          Center(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.8),
                  width: c ? 2 : 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: UserAvatar(
                avatarUrl: widget.userData?['avatar'],
                firstName: widget.userData?['firstName'],
                lastName: widget.userData?['lastName'],
                radius: c ? 28 : 40,
                backgroundColor: const Color(0xFF5cfbd8),
                textStyle: TextStyle(
                  color: const Color(0xFF272579),
                  fontSize: c ? 20 : 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          SizedBox(height: c ? 8 : 16),

          // User Name
          Center(
            child: Text(
              _getUserDisplayName(),
              style: TextStyle(
                color: Colors.white,
                fontSize: c ? 16 : 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: c ? 2 : 4),

          // Designation
          if (widget.userData != null) ...[
            Center(
              child: Text(
                widget.userData!['designation']?.toString() ?? '',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: c ? 12 : 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          // Company Footer (hidden in compact mode)
          if (!c) ...[
            const SizedBox(height: 20),
            const Center(
              child: Column(
                children: [
                  Text(
                    'idalWEALTH',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    'Advisory Private Limited',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Tap hint
          SizedBox(height: c ? 8 : 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Tap to view actions',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: c ? 9 : 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackCard() {
    if (widget.cardType == CardType.visitingCard) {
      return _buildVisitingCardBack();
    } else if (widget.showWelcomeCard) {
      return _buildCompactBackCard();
    }
    return _buildFullBackCard();
  }

  Widget _buildCompactBackCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0071bf), Color(0xFF272579)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Card Sharing',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Share your employee cards',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Share ID Card Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onShare,
              icon: const Icon(Icons.credit_card, size: 18),
              label: const Text(
                'Share ID Card',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5cfbd8),
                foregroundColor: const Color(0xFF272579),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Share Visiting Card Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onShareVisitingCard,
              icon: const Icon(Icons.business_center, size: 18),
              label: const Text(
                'Share Visiting Card',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0071bf),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Back to front hint
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Tap to go back',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullBackCard() {
    final c = widget.compact;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(c ? 16 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0071bf), Color(0xFF272579)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(c ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Card Sharing',
            style: TextStyle(
              color: Colors.white,
              fontSize: c ? 16 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Share your employee cards',
            style: TextStyle(
              color: Colors.white70,
              fontSize: c ? 12 : 14,
            ),
          ),

          SizedBox(height: c ? 14 : 20),

          // Share ID Card Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onShare,
              icon: Icon(Icons.credit_card, size: c ? 16 : 18),
              label: Text(
                'Share ID Card',
                style: TextStyle(
                  fontSize: c ? 13 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5cfbd8),
                foregroundColor: const Color(0xFF272579),
                padding: EdgeInsets.symmetric(vertical: c ? 10 : 14, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),

          SizedBox(height: c ? 8 : 12),

          // Share Visiting Card Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onShareVisitingCard,
              icon: Icon(Icons.business_center, size: c ? 16 : 18),
              label: Text(
                'Share Visiting Card',
                style: TextStyle(
                  fontSize: c ? 13 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0071bf),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: c ? 10 : 14, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),

          SizedBox(height: c ? 10 : 16),

          // Back to front hint
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Tap to go back',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: c ? 9 : 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitingCardFront() {
    final userRole = widget.userData?['role']?.toString() ?? 'employee';
    final isDirector = userRole.toLowerCase() == 'director';
    final isManager = userRole.toLowerCase() == 'manager';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDirector
              ? [const Color(0xFF272579), const Color(0xFF0071bf)]
              : [const Color(0xFF0071bf), const Color(0xFF00b8d9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Role-based header
          if (isDirector) ...[
            Text(
              'EXECUTIVE',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
          ] else if (isManager) ...[
            Text(
              'MANAGEMENT',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // User Name - large and prominent
          Text(
            _getUserDisplayName(),
            style: TextStyle(
              color: Colors.white,
              fontSize: isDirector ? 28 : 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // Designation
          if (widget.userData != null) ...[
            Text(
              '${widget.userData!['designation'] ?? ''}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          const Spacer(),

          // Company branding
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SvgPicture.asset(
                  'assets/company_logo.svg',
                  width: 20,
                  height: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'idalWEALTH',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      'Advisory Private Limited',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Tap hint
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Tap for contact details',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitingCardBack() {
    final userRole = widget.userData?['role']?.toString() ?? 'employee';
    final isDirector = userRole.toLowerCase() == 'director';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDirector
              ? [const Color(0xFF0071bf), const Color(0xFF272579)]
              : [const Color(0xFF00b8d9), const Color(0xFF0071bf)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Contact Information Header
          const Text(
            'Contact Information',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 24),

          // Email
          if (widget.userData?['email'] != null) ...[
            Row(
              children: [
                const Icon(Icons.email, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.userData!['email'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Phone
          if (widget.userData?['phoneNumber'] != null) ...[
            Row(
              children: [
                const Icon(Icons.phone, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.userData!['phoneNumber'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Employee ID (for non-directors)
          if (!isDirector && widget.userData?['employeeId'] != null) ...[
            Row(
              children: [
                const Icon(Icons.badge, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ID: ${widget.userData!['employeeId']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          const Spacer(),

          // Share Visiting Card Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onShareVisitingCard,
              icon: const Icon(Icons.share, size: 18),
              label: const Text(
                'Share Visiting Card',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5cfbd8),
                foregroundColor: const Color(0xFF272579),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Back to front hint
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Tap to go back',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, child) {
          final isShowingFront = _flipAnimation.value < 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(_flipAnimation.value * 3.14159),
            child: isShowingFront
                ? _buildFrontCard()
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(3.14159),
                    child: _buildBackCard(),
                  ),
          );
        },
      ),
    );
  }
}
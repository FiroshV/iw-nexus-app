import 'package:flutter/material.dart';

class WorkPrinciplesScreen extends StatefulWidget {
  const WorkPrinciplesScreen({super.key});

  @override
  State<WorkPrinciplesScreen> createState() => _WorkPrinciplesScreenState();
}

class _WorkPrinciplesScreenState extends State<WorkPrinciplesScreen> {
  final List<Map<String, dynamic>> _principles = [
    {
      'icon': Icons.handshake_outlined,
      'title': 'Trust & Respect',
      'content': 'Trust no one but respect everyone.',
      'color': const Color(0xFF0071bf),
    },
    {
      'icon': Icons.lock_outline,
      'title': 'Confidentiality',
      'content': 'What happens in office, remain in office. Never take office gossips to home and vice versa.',
      'color': const Color(0xFF00b8d9),
    },
    {
      'icon': Icons.schedule_outlined,
      'title': 'Work-Life Balance',
      'content': 'Enter office on time, leave on time. Your desktop is not helping to improve your health.',
      'color': const Color(0xFF5cfbd8),
    },
    {
      'icon': Icons.favorite_border,
      'title': 'Professional Relationships',
      'content': 'Never make Relationships in the work place. It will always backfire.',
      'color': const Color(0xFF0071bf),
    },
    {
      'icon': Icons.support_outlined,
      'title': 'Gratitude & Independence',
      'content': 'Expect nothing. If somebody helps, feel thankful. If not, you will learn to know things on your own.',
      'color': const Color(0xFF00b8d9),
    },
    {
      'icon': Icons.trending_up_outlined,
      'title': 'Career Growth',
      'content': 'Never rush for a position. If you get promoted, congrats. If not, it doesn\'t matter. You will always be remembered for your knowledge and politeness, not for your designation.',
      'color': const Color(0xFF5cfbd8),
    },
    {
      'icon': Icons.work_outline,
      'title': 'Priorities',
      'content': 'Never run behind office stuff. You have better things to do in life.',
      'color': const Color(0xFF0071bf),
    },
    {
      'icon': Icons.account_balance_wallet_outlined,
      'title': 'Ego & Compensation',
      'content': 'Avoid taking everything on your ego. Your salary matters. You are being paid. Use your assets to get happiness.',
      'color': const Color(0xFF00b8d9),
    },
    {
      'icon': Icons.sentiment_satisfied_outlined,
      'title': 'Humility',
      'content': 'It doesn\'t matter how people treat you. Be humble. You are not everyone\'s cup of tea.',
      'color': const Color(0xFF5cfbd8),
    },
    {
      'icon': Icons.home_outlined,
      'title': 'Life Priorities',
      'content': 'In the end nothing matters except family, friends, home, and Inner peace.',
      'color': const Color(0xFF0071bf),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF272579), Color(0xFF0071bf)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Work Principles',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      backgroundColor: const Color(0xFFfbf8ff),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF272579), Color(0xFF0071bf)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.white,
                    size: 32,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Our Work Principles',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Core values that guide us in our professional journey',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Principles List
            ...(_principles.map((principle) => _buildPrincipleCard(principle)).toList()),

            const SizedBox(height: 24),

            // Footer Message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF5cfbd8).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF5cfbd8).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: const Text(
                'These principles shape our workplace culture and help us grow together as a team.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF272579),
                  height: 1.6,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPrincipleCard(Map<String, dynamic> principle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (principle['color'] as Color).withValues(alpha: 0.2),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Number Badge & Icon
                Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: (principle['color'] as Color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          principle['icon'] as IconData,
                          color: principle['color'] as Color,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        principle['title'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF272579),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        principle['content'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

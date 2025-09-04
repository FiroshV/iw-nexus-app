import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'widgets/loading_widget.dart';
import 'login_page.dart';
import 'services/api_service.dart';
import 'screens/admin/user_management_screen.dart';
import 'screens/attendance_screen.dart';
import 'config/api_config.dart';
import 'utils/timezone_util.dart';
import 'utils/timezone_test.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone for consistent IST handling
  try {
    await TimezoneUtil.initialize();
    debugPrint('🌍 Timezone (IST) initialized successfully');

    // Run timezone tests in debug mode
    await testTimezoneUtility();
  } catch (e) {
    debugPrint('❌ Timezone initialization error: $e');
  }

  // Initialize API configuration
  try {
    await ApiConfig.initialize();
    debugPrint('⚙️ API configuration initialized successfully');
  } catch (e) {
    debugPrint('❌ API configuration initialization error: $e');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('🔥 Firebase initialized successfully');
  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: MaterialApp(
        title: 'IW Nexus',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF272579)),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize authentication state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().initializeAuth();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // Check authentication status when app is resumed
      context.read<AuthProvider>().onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        switch (authProvider.status) {
          case AuthStatus.uninitialized:
            return const LoadingWidget(message: 'Initializing...');
          case AuthStatus.authenticated:
            return const DashboardPage();
          case AuthStatus.unauthenticated:
          case AuthStatus.loading:
            return const LoginPage();
        }
      },
    );
  }
}

// Dashboard page with admin features
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? currentUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // First try to get user profile from API to ensure we have latest role information
      final response = await ApiService.getUserProfile();
      if (response.success && response.data != null) {
        if (mounted) {
          setState(() {
            currentUser = response.data;
            isLoading = false;
          });
        }
      } else {
        // Try getCurrentUser endpoint as fallback
        final authResponse = await ApiService.getCurrentUser();
        if (authResponse.success && authResponse.data != null) {
          if (mounted) {
            setState(() {
              // The /auth/me endpoint returns user data under the 'user' key
              currentUser = authResponse.data!['user'] ?? authResponse.data;
              isLoading = false;
            });
          }
        } else {
          // Final fallback to local storage
          final userData = await ApiService.getUserData();
          if (mounted) {
            setState(() {
              currentUser = userData;
              isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      // Fallback to local storage on error
      try {
        final userData = await ApiService.getUserData();
        if (mounted) {
          setState(() {
            currentUser = userData;
            isLoading = false;
          });
        }
      } catch (e2) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }

  bool get isAdmin {
    print('🔍 Debug: Current user data: $currentUser');
    print('🔍 Debug: User role: ${currentUser?['role']}');
    final userRole = currentUser?['role']?.toString().toLowerCase();
    final isAdminResult =
        userRole == 'admin' ||
        userRole == 'administrator' ||
        userRole == 'director';
    print('🔍 Debug: Is admin check result: $isAdminResult');
    return isAdminResult;
  }

  Widget _buildDashboardCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 36, color: color ?? const Color(0xFF272579)),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IW Nexus Dashboard'),
        backgroundColor: const Color(0xFF272579),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
      body: isLoading
          ? const LoadingWidget(message: 'Loading dashboard...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF272579), Color(0xFF3A2F8B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          currentUser != null
                              ? '${currentUser!['firstName'] ?? ''} ${currentUser!['lastName'] ?? ''}'
                                    .trim()
                              : 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (currentUser != null) ...[
                          Text(
                            '${currentUser!['designation'] ?? ''} • ${currentUser!['department'] ?? ''}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Role: ${currentUser!['role'] ?? 'unknown'}',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                          if (isAdmin)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'ADMIN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick actions
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF272579),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Dashboard cards grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1, // Make cards slightly taller
                    children: [
                      // Attendance card
                      _buildDashboardCard(
                        title: 'Attendance',
                        subtitle: 'Check in/out',
                        icon: Icons.access_time,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AttendanceScreen(),
                            ),
                          );
                        },
                      ),

                      // Admin-only: User Management
                      if (isAdmin) ...[
                        _buildDashboardCard(
                          title: 'Employees',
                          subtitle: 'Manage employees',
                          icon: Icons.people,
                          color: Colors.orange,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const UserManagementScreen(),
                              ),
                            );
                          },
                        ),

                        _buildDashboardCard(
                          title: 'Reports',
                          subtitle: 'Analytics & data',
                          icon: Icons.analytics,
                          color: Colors.green,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Reports feature coming soon!'),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

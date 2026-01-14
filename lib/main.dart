import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/crm/customer_provider.dart';
import 'providers/crm/activity_provider.dart';
import 'providers/crm/appointment_provider.dart';
import 'providers/crm/sale_provider.dart';
import 'providers/incentive_provider.dart';
import 'models/sale.dart';
import 'widgets/loading_widget.dart';
import 'widgets/id_card_widget.dart';
import 'widgets/user_avatar.dart';
import 'login_page.dart';
import 'services/api_service.dart';
import 'services/access_control_service.dart';
import 'services/version_check_service.dart';
import 'screens/admin/user_management_screen.dart';
import 'screens/admin/branch_management_screen.dart';
import 'screens/admin/send_appointment_letter_screen.dart';
import 'screens/enhanced_attendance_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/feedback/feedback_list_screen.dart';
import 'screens/work_principles_screen.dart';
import 'widgets/approval_card.dart';
import 'screens/id_card_screen.dart';
import 'screens/admin/payroll/payroll_management_screen.dart';
import 'screens/conveyance/conveyance_screen.dart';
import 'screens/crm/crm_module_screen.dart';
import 'screens/crm/customer_list_screen.dart';
import 'screens/crm/customer_detail_screen.dart';
import 'screens/crm/appointment_details_screen.dart';
import 'screens/crm/team_schedule_screen.dart';
import 'screens/crm/sales_list_screen.dart';
import 'screens/crm/sale_details_screen.dart';
import 'screens/crm/add_edit_customer_screen.dart';
import 'screens/crm/add_edit_sale_screen.dart';
import 'screens/crm/simplified_appointment_screen.dart';
import 'screens/crm/quick_activity_log_screen.dart';
import 'screens/crm/activity_list_screen.dart';
import 'screens/crm/activity_details_screen.dart';
import 'screens/crm/unified_appointments_screen.dart';
import 'screens/crm/pipeline_dashboard_screen.dart';
import 'screens/crm/pipeline_stage_detail_screen.dart';
import 'screens/crm/overdue_followups_screen.dart';
import 'screens/crm/call_logs_screen.dart';
import 'screens/crm/call_detail_screen.dart';
import 'screens/incentive/incentive_module_screen.dart';
import 'config/api_config.dart';
import 'utils/timezone_util.dart';
import 'utils/timezone_test.dart';
import 'utils/navigation_guards.dart';
import 'services/remote_config_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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

    // Initialize Remote Config and Version Check Service based on .env setting
    if (_shouldUseRemoteConfig()) {
      debugPrint('🔧 Remote Config enabled - initializing services');

      // Initialize Firebase Remote Config
      try {
        await RemoteConfigService.initialize();
        debugPrint('🔧 Remote Config initialized successfully');
      } catch (e) {
        debugPrint('❌ Remote Config initialization error: $e');
      }

      // Initialize Version Check Service
      try {
        await VersionCheckService.initialize();
        debugPrint('📱 Version Check Service initialized successfully');
      } catch (e) {
        debugPrint('❌ Version Check Service initialization error: $e');
      }
    } else {
      debugPrint('🔧 Remote Config disabled - skipping initialization');
    }
  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
  }

  runApp(const MyApp());
}

/// Check if Remote Config should be used based on .env setting
bool _shouldUseRemoteConfig() {
  final useRemoteConfig = dotenv.maybeGet('USE_REMOTE_CONFIG')?.toLowerCase();
  return useRemoteConfig == 'true' || useRemoteConfig == '1';
}

/// Check if version checking should be enabled based on .env setting
bool _shouldEnableVersionCheck() {
  final enableVersionCheck = dotenv
      .maybeGet('ENABLE_VERSION_CHECK')
      ?.toLowerCase();
  return enableVersionCheck == 'true' || enableVersionCheck == '1';
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // CRM Providers
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => SaleProvider()),
        // Incentive Provider
        ChangeNotifierProvider(create: (_) => IncentiveProvider()),
      ],
      child: MaterialApp(
        title: 'IW Nexus',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          platform: TargetPlatform.iOS,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF272579)),
          useMaterial3: true,
          primaryColor: const Color(0xFF0071bf),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: const Color(0xFFfbf8ff),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF272579),
            foregroundColor: Colors.white,
            elevation: 0,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        home: const AuthWrapper(),
        onGenerateRoute: _generateRoute,
      ),
    );
  }

  /// Generate routes for the application
  static Route<dynamic> _generateRoute(RouteSettings settings) {
    final args = settings.arguments as Map<String, dynamic>?;

    switch (settings.name) {
      // CRM Routes
      case '/crm/customer-list':
        return MaterialPageRoute(
          builder: (_) => CustomerListScreen(
            userId: args?['userId'] ?? '',
            userRole: args?['userRole'] ?? '',
          ),
          settings: settings,
        );

      case '/crm/customer-detail':
        return MaterialPageRoute(
          builder: (_) => CustomerDetailScreen(
            customerId: args?['customerId'] ?? '',
            userId: args?['userId'] ?? '',
            userRole: args?['userRole'] ?? '',
          ),
          settings: settings,
        );

      case '/crm/appointment-details':
        return MaterialPageRoute(
          builder: (_) => AppointmentDetailsScreen(
            appointmentId: args?['appointmentId'] ?? '',
            userId: args?['userId'] ?? '',
            userRole: args?['userRole'] ?? '',
          ),
          settings: settings,
        );

      case '/crm/team-schedule':
        return MaterialPageRoute(
          builder: (_) => TeamScheduleScreen(
            branchId: args?['branchId'] ?? '',
            userRole: args?['userRole'] ?? '',
          ),
          settings: settings,
        );

      case '/crm/sales-list':
        return MaterialPageRoute(
          builder: (_) => SalesListScreen(
            userId: args?['userId'] ?? '',
            userRole: args?['userRole'] ?? '',
          ),
          settings: settings,
        );

      case '/crm/sale-details':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => SaleDetailsScreen(
            saleId: args?['saleId'] ?? '',
            userId: args?['userId'] ?? '',
            userRole: args?['userRole'] ?? '',
          ),
          settings: settings,
        );

      case '/crm/add-customer':
        return MaterialPageRoute(
          builder: (_) => const AddEditCustomerScreen(),
          settings: settings,
        );

      case '/crm/add-edit-sale':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => AddEditSaleScreen(
            sale: args?['sale'] as Sale?,
          ),
          settings: settings,
        );

      case '/crm/simplified-appointment':
        return MaterialPageRoute(
          builder: (_) => SimplifiedAppointmentScreen(
            userId: args?['userId'] ?? '',
            userRole: args?['userRole'] ?? '',
            initialCustomerId: args?['customerId'],
          ),
          settings: settings,
        );

      case '/crm/log-activity':
        return MaterialPageRoute(
          builder: (_) => QuickActivityLogScreen(
            userId: args?['userId'] ?? '',
            userRole: args?['userRole'] ?? '',
            initialCustomerId: args?['customerId'],
          ),
          settings: settings,
        );

      case '/crm/activity-list':
        return MaterialPageRoute(
          builder: (_) => ActivityListScreen(
            userId: args?['userId'] ?? '',
            userRole: args?['userRole'] ?? '',
          ),
          settings: settings,
        );

      case '/crm/activity-details':
        return MaterialPageRoute(
          builder: (_) => ActivityDetailsScreen(
            activityId: args?['activityId'] ?? '',
            userId: args?['userId'] ?? '',
            userRole: args?['userRole'] ?? '',
          ),
          settings: settings,
        );

      case '/crm/appointments':
        return MaterialPageRoute(
          builder: (_) => UnifiedAppointmentsScreen(
            userId: args?['userId'] ?? '',
            userRole: args?['userRole'] ?? '',
            initialTab: args?['initialTab'] ?? 0,
          ),
          settings: settings,
        );

      case '/crm/pipeline':
        return MaterialPageRoute(
          builder: (_) => PipelineDashboardScreen(
            userId: args?['userId'] ?? '',
            userRole: args?['userRole'] ?? '',
          ),
          settings: settings,
        );

      case '/crm/pipeline/stage':
        return MaterialPageRoute(
          builder: (_) => PipelineStageDetailScreen(
            stage: args?['stage'] ?? 'active',
            userId: args?['userId'] ?? '',
            userRole: args?['userRole'] ?? '',
            view: args?['view'] ?? 'assigned',
          ),
          settings: settings,
        );

      case '/crm/pipeline/overdue':
        return MaterialPageRoute(
          builder: (_) => OverdueFollowupsScreen(
            userId: args?['userId'] ?? '',
            userRole: args?['userRole'] ?? '',
            view: args?['view'] ?? 'assigned',
          ),
          settings: settings,
        );

      case '/crm/call-logs':
        return MaterialPageRoute(
          builder: (_) => CallLogsScreen(
            userId: args?['userId'] ?? '',
            userRole: args?['userRole'] ?? '',
          ),
          settings: settings,
        );

      case '/crm/call-detail':
        return MaterialPageRoute(
          builder: (_) => CallDetailScreen(
            callLogId: args?['callLogId'] ?? '',
            userId: args?['userId'] ?? '',
            userRole: args?['userRole'] ?? '',
          ),
          settings: settings,
        );

      default:
        // Return a 404-like screen for undefined routes
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Not Found')),
            body: Center(
              child: Text('Route ${settings.name} not found'),
            ),
          ),
          settings: settings,
        );
    }
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

      // Refresh approval data for managers/admins when app resumes
      // This ensures they see new approval requests after switching back to the app
      _refreshApprovalDataOnResume();
    }
  }

  /// Refresh approval data when app resumes from background
  Future<void> _refreshApprovalDataOnResume() async {
    try {
      // Only refresh if user is authenticated and has approval permissions
      final authProvider = context.read<AuthProvider>();
      if (authProvider.status != AuthStatus.authenticated) return;

      // Get current user data to check role
      final userData = await ApiService.getUserData();
      if (userData == null) return;

      final userRole = userData['role']?.toString() ?? '';

      // Only refresh for users who can view approvals
      if (AccessControlService.hasAccess(
        userRole,
        'attendance',
        'approve_attendance',
      )) {
        // Note: The actual refresh will be handled by the ApprovalCard widget
        // This is just to trigger a rebuild if needed
        debugPrint(
          '🔄 App resumed - approval data will be refreshed by widgets',
        );
      }
    } catch (e) {
      debugPrint('❌ Error checking approval permissions on app resume: $e');
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
  VersionCheckResult? _updateInfo;
  bool _isUpdateBannerDismissed = false;

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
          // Check for app updates after user data is loaded
          _checkForAppUpdate();
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
            // Check for app updates after user data is loaded
            _checkForAppUpdate();
          }
        } else {
          // Final fallback to local storage
          final userData = await ApiService.getUserData();
          if (mounted) {
            setState(() {
              currentUser = userData;
              isLoading = false;
            });
            // Check for app updates after user data is loaded
            _checkForAppUpdate();
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
          // Check for app updates after user data is loaded
          _checkForAppUpdate();
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
    debugPrint('🔍 Debug: Current user data: $currentUser');
    debugPrint('🔍 Debug: User role: ${currentUser?['role']}');
    final userRole = currentUser?['role']?.toString();
    final isAdminResult = AccessControlService.isAdmin(userRole);
    debugPrint('🔍 Debug: Is admin check result: $isAdminResult');
    return isAdminResult;
  }

  String get userRole => currentUser?['role']?.toString() ?? '';

  /// Check for app updates and show dialog if needed
  Future<void> _checkForAppUpdate() async {
    try {
      // Skip version check if disabled in .env
      if (!_shouldEnableVersionCheck()) {
        debugPrint('⏭️ Skipping version check - disabled in .env');
        return;
      }

      // Only check for updates if services are available
      if (!VersionCheckService.isAvailable ||
          !RemoteConfigService.isAvailable) {
        debugPrint('⏭️ Skipping version check - services not available');
        return;
      }

      debugPrint('🔍 Version check enabled - performing update check');

      // Perform version check
      final versionResult = await VersionCheckService.checkForUpdate();

      // Show update dialog if update is available
      if (versionResult.updateAvailable && mounted) {
        // Small delay to ensure UI is ready
        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          // Store update info for dashboard banner (both force and optional)
          setState(() {
            _updateInfo = versionResult;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking for app update: $e');
    }
  }

  /// Build update banner for dashboard
  Widget? _buildUpdateBanner() {
    if (_updateInfo == null ||
        !_updateInfo!.updateAvailable ||
        _isUpdateBannerDismissed) {
      return null;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0071bf), Color(0xFF00b8d9)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0071bf).withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _updateInfo!.forceUpdate
                  ? 'Update required to continue'
                  : 'New update available',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () async {
                  // Launch store directly
                  final success = await VersionCheckService.launchStore(
                    _updateInfo!.downloadUrl,
                  );

                  if (!success && mounted) {
                    // Show error message if store launch failed
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Unable to open store. Please update manually.',
                        ),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF5cfbd8),
                  foregroundColor: const Color(0xFF272579),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  _updateInfo!.forceUpdate ? 'Update Now' : 'Update',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              // Only show close button for optional updates
              if (!_updateInfo!.forceUpdate) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isUpdateBannerDismissed = true;
                    });
                  },
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 18,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _getUserDisplayName() {
    if (currentUser == null) return 'User';
    final firstName = currentUser!['firstName']?.toString() ?? '';
    final lastName = currentUser!['lastName']?.toString() ?? '';
    final fullName = '$firstName $lastName'.trim();
    return fullName.isNotEmpty ? fullName : 'User';
  }

  void _handleIdCardShare(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            IDCardScreen(userData: currentUser, action: IDCardAction.share),
      ),
    );
  }

  void _handleVisitingCardShare(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => IDCardScreen(
          userData: currentUser,
          action: IDCardAction.shareVisitingCard,
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Profile header
            Row(
              children: [
                UserAvatar(
                  avatarUrl: currentUser?['avatar'],
                  firstName: currentUser?['firstName'],
                  lastName: currentUser?['lastName'],
                  radius: 30,
                  backgroundColor: const Color(0xFF5cfbd8),
                  textStyle: const TextStyle(
                    color: Color(0xFF272579),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getUserDisplayName(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF272579),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Menu items
            _buildMenuTile(
              icon: Icons.person_outline,
              title: 'Profile',
              subtitle: 'View and edit your profile',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),

            _buildMenuTile(
              icon: Icons.feedback_outlined,
              title: 'Feedback & Support',
              subtitle: 'Share feedback or report issues',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const FeedbackListScreen(),
                  ),
                );
              },
            ),

            _buildMenuTile(
              icon: Icons.lightbulb_outline,
              title: 'Work Principles',
              subtitle: 'Our guiding values at work',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const WorkPrinciplesScreen(),
                  ),
                );
              },
            ),

            _buildMenuTile(
              icon: Icons.logout,
              title: 'Logout',
              subtitle: 'Sign out of your account',
              isDestructive: true,
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog(context);
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withValues(alpha: 0.1)
              : const Color(0xFF0071bf).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : const Color(0xFF0071bf),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red : const Color(0xFF272579),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF272579),
            ),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthProvider>().logout();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, const Color(0xFFfbf8ff)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF272579).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: const Color(0xFF272579).withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (color ?? const Color(0xFF0071bf)).withValues(
                      alpha: 0.12,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: (color ?? const Color(0xFF0071bf)).withValues(
                        alpha: 0.2,
                      ),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: color ?? const Color(0xFF0071bf),
                  ),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF272579),
                      letterSpacing: -0.2,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.fade,
                  ),
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.1,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.fade,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
        title: Row(
          children: [
            Container(
              width: 30,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                // borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: SvgPicture.asset(
                'assets/logo_1.svg',
                height: 20,
                width: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'IW Nexus',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Dashboard',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Profile info and logout
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (currentUser != null) ...[
                  // User avatar and info
                  GestureDetector(
                    onTap: () => _showProfileMenu(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          UserAvatar(
                            avatarUrl: currentUser?['avatar'],
                            firstName: currentUser?['firstName'],
                            lastName: currentUser?['lastName'],
                            radius: 14,
                            backgroundColor: const Color(0xFF5cfbd8),
                            textStyle: const TextStyle(
                              color: Color(0xFF272579),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [],
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white70,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Simple logout when user data not loaded
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.logout,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    onPressed: () => _showLogoutDialog(context),
                    tooltip: 'Logout',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFf8f9fa),
      body: isLoading
          ? const LoadingWidget(message: 'Loading dashboard...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Update banner (only shows on dashboard)
                  if (_buildUpdateBanner() != null) _buildUpdateBanner()!,

                  // Welcome section with flip functionality
                  IDCardWidget(
                    userData: currentUser,
                    onShare: () => _handleIdCardShare(context),
                    onShareVisitingCard: () =>
                        _handleVisitingCardShare(context),
                    showWelcomeCard: true,
                  ),

                  const SizedBox(height: 24),

                  // Approval cards for managers/admins
                  ApprovalCard(userRole: userRole),

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
                    childAspectRatio: 0.9,
                    children: [
                      // Attendance card - hidden for external employees
                      // Requires profile completion for non-admin/director roles
                      if (userRole != 'external')
                        _buildDashboardCard(
                          title: 'Attendance',
                          subtitle: 'Check in/out',
                          icon: Icons.schedule,
                          color: const Color(0xFF5cfbd8),
                          onTap: () {
                            final authProvider = context.read<AuthProvider>();
                            NavigationGuards.navigateWithProfileCheck(
                              context: context,
                              userData: authProvider.user,
                              destination: const EnhancedAttendanceScreen(),
                              featureName: 'Attendance',
                            );
                          },
                        ),

                      // User Management - accessible to admin, hr, manager, director
                      if (AccessControlService.hasAccess(
                        userRole,
                        'user_management',
                        'view',
                      )) ...[
                        _buildDashboardCard(
                          title: 'Employees',
                          subtitle: 'Manage team members',
                          icon: Icons.people_outline,
                          color: const Color(0xFF00b8d9),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const UserManagementScreen(),
                              ),
                            );
                          },
                        ),
                      ],

                      // Branch Management - accessible to admin, manager, director
                      if (AccessControlService.hasAccess(
                        userRole,
                        'branch_management',
                        'view',
                      )) ...[
                        _buildDashboardCard(
                          title: 'Branches',
                          subtitle: 'Manage office locations',
                          icon: Icons.business,
                          color: const Color(0xFF0071bf),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const BranchManagementScreen(),
                              ),
                            );
                          },
                        ),
                      ],

                      // Reports - accessible to admin, hr, manager, director
                      if (AccessControlService.hasAccess(
                        userRole,
                        'reports',
                        'attendance_reports',
                      )) ...[
                        _buildDashboardCard(
                          title: 'Reports',
                          subtitle: 'Analytics & insights',
                          icon: Icons.bar_chart_rounded,
                          color: const Color(0xFF5cfbd8),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Reports feature coming soon!'),
                              ),
                            );
                            // Navigator.of(context).push(
                            //   MaterialPageRoute(
                            //     builder: (context) => ReportsScreen(userRole: userRole),
                            //   ),
                            // );
                          },
                        ),
                      ],

                      // Payslip - accessible to all employees
                      if (AccessControlService.hasAccess(userRole, 'payroll', 'view_own')) ...[
                        _buildDashboardCard(
                          title: 'Payslip',
                          subtitle: 'View and manage payslips',
                          icon: Icons.receipt_long,
                          color: const Color(0xFF00b8d9),
                          onTap: () {
                            // Determine initial tab: admin/director open to Employees tab (tab 1),
                            // regular employees open to View Payslip tab (tab 0)
                            final initialTab = (userRole == 'admin' || userRole == 'director') ? 1 : 0;
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => PayrollManagementScreen(initialTab: initialTab),
                              ),
                            );
                          },
                        ),
                      ],
                      // Appointment Letters - accessible to admin, director
                      if (AccessControlService.hasAccess(
                        userRole,
                        'appointment_letter',
                        'send',
                      )) ...[
                        _buildDashboardCard(
                          title: 'Appointment Letter',
                          subtitle: 'Send to employee',
                          icon: Icons.mail_outline,
                          color: const Color(0xFF00b8d9),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SendAppointmentLetterScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                      // Conveyance - accessible to all users
                      if (AccessControlService.hasAccess(userRole, 'conveyance_management', 'view_own')) ...[
                        _buildDashboardCard(
                          title: 'Conveyance',
                          subtitle: 'Submit & track claims',
                          icon: Icons.commute,
                          color: const Color(0xFF00b8d9),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ConveyanceScreen(userRole: userRole),
                              ),
                            );
                          },
                        ),
                      ],

                      // CRM - Sales, Visits & Follow-ups - accessible to all users
                      _buildDashboardCard(
                        title: 'CRM Module',
                        subtitle: 'Manage sales, visits & follow-ups',
                        icon: Icons.trending_up,
                        color: const Color(0xFF5cfbd8),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => CrmModuleScreen(
                                userId: currentUser?['_id'] ?? '',
                                userRole: userRole,
                              ),
                            ),
                          );
                        },
                      ),

                      // Incentives - accessible to users with incentive permissions
                      if (AccessControlService.hasAccess(
                        userRole,
                        'incentive_management',
                        'view_own_incentive',
                      )) ...[
                        _buildDashboardCard(
                          title: 'Incentives',
                          subtitle: 'Commission & targets',
                          icon: Icons.workspace_premium_rounded,
                          color: const Color(0xFF00b8d9),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const IncentiveModuleScreen(),
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

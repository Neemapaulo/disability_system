import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/account_retrieval_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/ripoti/screens/camera_screen.dart';
import '../../features/ripoti/screens/report_form_screen.dart';
import '../../features/ripoti/screens/my_reports_screen.dart';
import '../../features/ripoti/screens/report_success_screen.dart';
import '../../features/ripoti/screens/report_timeline_screen.dart';
import '../../features/map/screens/gap_map_screen.dart';

abstract class Routes {
  static const splash           = '/';
  static const onboarding       = '/onboarding';
  static const login            = '/login';
  static const register         = '/register';
  static const dashboard        = '/dashboard';
  static const accountRetrieval = '/account-retrieval';

  static const camera           = '/camera';
  static const reportForm       = '/report-form';
  static const reportSuccess    = '/report-success';
  static const myReports        = '/my-reports';
  static const reportTimeline   = '/report-timeline';
  static const gapMap           = '/gap-map';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.splash,
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: Routes.accountRetrieval,
        builder: (_, __) => const AccountRetrievalScreen(),
      ),
      GoRoute(
        path: Routes.dashboard,
        builder: (_, __) => const DashboardScreen(),
      ),
      GoRoute(
        path: Routes.camera,
        builder: (_, __) => const CameraScreen(),
      ),
      GoRoute(
        path: Routes.reportForm,
        builder: (_, __) => const ReportFormScreen(),
      ),
      GoRoute(
        path: Routes.reportSuccess,
        builder: (_, __) => const ReportSuccessScreen(),
      ),
      GoRoute(
        path: Routes.myReports,
        builder: (_, __) => const MyReportsScreen(),
      ),
      GoRoute(
        path: Routes.reportTimeline,
        builder: (context, state) {
          final id = state.extra as String? ?? '';
          return ReportTimelineScreen(ripotiId: id);
        },
      ),
      GoRoute(
        path: Routes.gapMap,
        builder: (_, __) => const GapMapScreen(),
      ),
    ],
  );
});

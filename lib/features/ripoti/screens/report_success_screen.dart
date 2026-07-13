import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../providers/ripoti_provider.dart';

class ReportSuccessScreen extends ConsumerStatefulWidget {
  const ReportSuccessScreen({super.key});

  @override
  ConsumerState<ReportSuccessScreen> createState() =>
      _ReportSuccessScreenState();
}

class _ReportSuccessScreenState extends ConsumerState<ReportSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scaleAnim;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final submitted = ref.watch(captureProvider).submittedRipoti;
    final reportId  = submitted?.id.substring(0, 13).toUpperCase()
        ?? 'MK-0000-2025';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  // ── Animated Checkmark ────────────
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: Container(
                      width: 110, height: 110,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppColors.success,
                        size:  64,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Heading ───────────────────────
                  const Text(
                    'Asante! Taarifa\nImetumwa Kwenye Mfumo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize:   24,
                      fontWeight: FontWeight.w900,
                      color:      AppColors.primaryBlue,
                      height:     1.3,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Body ──────────────────────────
                  const Text(
                    'Ripoti yako imepokelewa na kuingizwa kwenye ramani '
                        'ya jiji letu kwa ajili ya mapitio ya mamlaka.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:    AppColors.textSecondary,
                      fontSize: 14,
                      height:   1.6,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Map Preview ───────────────────
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color:        const Color(0xFFCFE8F3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        // Map background pattern
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CustomPaint(
                              painter: _MapGridPainter(),
                            ),
                          ),
                        ),
                        // Pin icons
                        const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.green,
                                size:  36,
                              ),
                              SizedBox(width: 16),
                              Icon(
                                Icons.location_on,
                                color: AppColors.primaryRed,
                                size:  48,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Go Home Button ────────────────
                  Semantics(
                    label:  'Rudi Nyumbani',
                    button: true,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ref.read(captureProvider.notifier).reset();
                          context.go(Routes.dashboard);
                        },
                        icon:  const Icon(Icons.home_outlined, size: 20),
                        label: const Text(
                          'Rudi Nyumbani',
                          style: TextStyle(
                            fontSize:   16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          foregroundColor: Colors.white,
                          padding:
                          const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Report ID chip ────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:        Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.success, shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ID: $reportId',
                          style: const TextStyle(
                            fontSize:   12,
                            fontWeight: FontWeight.w600,
                            color:      AppColors.textSecondary,
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
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color     = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

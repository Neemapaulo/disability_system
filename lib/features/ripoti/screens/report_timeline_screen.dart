import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/ripoti_model.dart';
import '../../../core/router/app_router.dart';
import '../providers/ripoti_provider.dart';

class ReportTimelineScreen extends ConsumerWidget {
  final String ripotiId;
  const ReportTimelineScreen({super.key, required this.ripotiId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Real-time stream — updates when admin changes status
    final ripotiStream = ref.watch(watchRipotiProvider(ripotiId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryRed),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Fuatilia Hatua za Utatuzi',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: ripotiStream.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
        error: (e, _) => Center(
          child: Text('Hitilafu: $e'),
        ),
        data: (ripoti) => _TimelineBody(ripoti: ripoti),
      ),
      bottomNavigationBar: _TimelineBottomBar(ripotiId: ripotiId),
    );
  }
}

// ─────────────────────────────────────────────
class _TimelineBody extends StatelessWidget {
  final RipotiModel ripoti;
  const _TimelineBody({required this.ripoti});

  // Determine which steps are complete based on hali
  int get _completedSteps {
    switch (ripoti.hali) {
      case 'mpya':
        return 1;
      case 'inaangaliwa':
        return 1;
      case 'imepewa_mamlaka':
        return 2;
      case 'inashughulikiwa':
        return 3;
      case 'imekamilika':
        return 4;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      _TimelineStep(
        number: 1,
        title: 'Ripoti Imepokelewa',
        subtitle: 'Saa ${_formatTime(ripoti.createdAt)} AM - '
            'Ripoti yako imethibitishwa na mfumo wa PamojaMove.',
        isDone: _completedSteps >= 1,
        isActive: _completedSteps == 1,
      ),
      _TimelineStep(
        number: 2,
        title: 'Mamlaka ya LATRA / Halmashauri Imepewa Taarifa',
        subtitle: ripoti.hali == 'imepewa_mamlaka' ||
                ripoti.hali == 'inashughulikiwa' ||
                ripoti.hali == 'imekamilika'
            ? 'Idara ya Miundombinu imepewa taarifa rasmi kwa ajili ya ukaguzi.'
            : 'Inasubiri ukaguzi wa mfumo...',
        isDone: _completedSteps >= 2,
        isActive: _completedSteps == 2,
      ),
      _TimelineStep(
        number: 3,
        title: 'Ufumbuzi Umepangwa / Kazi Inaanza',
        subtitle: ripoti.hali == 'inashughulikiwa'
            ? ripoti.maoniYaAdmin ??
                'Mafundi wapo njiani kuelekea eneo la tukio kwa ajili ya ukarabati.'
            : 'Bado haijafikiwa hatua hii.',
        isDone: _completedSteps >= 3,
        isActive: _completedSteps == 3,
        badge: _completedSteps == 3 ? 'INASUBIRI KUANZA' : null,
        showImage: _completedSteps >= 3,
      ),
      _TimelineStep(
        number: 4,
        title: 'Imekamilika',
        subtitle: ripoti.hali == 'imekamilika'
            ? 'Tatizo limeshughulikiwa kikamilifu. Asante!'
            : 'Hatua ya mwisho: Uthibitishaji wa marekebisho kukamilika.',
        isDone: _completedSteps >= 4,
        isActive: _completedSteps == 4,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── REPORT INFO CARD ────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ID ya Ripoti: ${ripoti.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    _HaliChip(
                      hali: ripoti.hali,
                      label: ripoti.haliLabel,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  ripoti.ainaLabel,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Eneo: ${ripoti.eneo ?? ripoti.wilaya ?? 'Haijulikani'}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Imeripotiwa: Tarehe ${ripoti.dateFormatted}',
                      style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── TIMELINE ────────────────────────────
          ...List.generate(steps.length, (i) {
            final step = steps[i];
            final isLastStep = i == steps.length - 1;
            return _TimelineItem(
              step: step,
              showLine: !isLastStep,
            );
          }),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ─────────────────────────────────────────────
class _TimelineStep {
  final int number;
  final String title;
  final String subtitle;
  final bool isDone;
  final bool isActive;
  final String? badge;
  final bool showImage;

  const _TimelineStep({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.isDone,
    required this.isActive,
    this.badge,
    this.showImage = false,
  });
}

// ─────────────────────────────────────────────
class _TimelineItem extends StatelessWidget {
  final _TimelineStep step;
  final bool showLine;
  const _TimelineItem({required this.step, required this.showLine});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Hatua ${step.number}: ${step.title}. '
          '${step.isDone ? "Imekamilika" : "Bado"}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left: Icon + Line ──────────────────
          Column(
            children: [
              // Circle icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: step.isDone
                      ? AppColors.primaryBlue
                      : step.isActive
                          ? AppColors.badgeGold
                          : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: step.isDone
                      ? const Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                          size: 22,
                        )
                      : Icon(
                          _stepIcon(step.number),
                          color: step.isActive
                              ? Colors.white
                              : Colors.grey.shade500,
                          size: 22,
                        ),
                ),
              ),

              // Connector line
              if (showLine)
                Container(
                  width: 2,
                  height: step.showImage ? 220 : 70,
                  color: step.isDone
                      ? AppColors.primaryBlue
                      : Colors.grey.shade300,
                ),
            ],
          ),

          const SizedBox(width: 16),

          // ── Right: Content ─────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${step.number}. ${step.title}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: step.isDone
                                ? AppColors.primaryBlue
                                : step.isActive
                                    ? AppColors.badgeGold
                                    : Colors.grey.shade500,
                          ),
                        ),
                      ),
                      if (step.badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.badgeGold,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            step.badge!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    step.subtitle,
                    style: TextStyle(
                      color: step.isDone
                          ? AppColors.textSecondary
                          : Colors.grey.shade400,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),

                  // Image for step 3
                  if (step.showImage && step.isDone) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 140,
                        width: double.infinity,
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.construction_outlined,
                          size: 60,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _stepIcon(int n) {
    switch (n) {
      case 1:
        return Icons.check_circle_outline;
      case 2:
        return Icons.account_balance_outlined;
      case 3:
        return Icons.people_outline;
      case 4:
        return Icons.verified_outlined;
      default:
        return Icons.circle_outlined;
    }
  }
}

// ─────────────────────────────────────────────
class _TimelineBottomBar extends ConsumerWidget {
  final String ripotiId;
  const _TimelineBottomBar({required this.ripotiId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: 'Ona kwenye Ramani',
            button: true,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push(Routes.gapMap),
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text(
                  'Ona kwenye Ramani',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(
              Icons.arrow_back_outlined,
              size: 18,
              color: AppColors.primaryBlue,
            ),
            label: const Text(
              'Rudi kwenye orodha',
              style: TextStyle(color: AppColors.primaryBlue),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.primaryBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _HaliChip extends StatelessWidget {
  final String hali;
  final String label;
  const _HaliChip({required this.hali, required this.label});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (hali) {
      case 'mpya':
        bg = const Color(0xFFFEF9C3);
        fg = const Color(0xFF713F12);
        break;
      case 'imepewa_mamlaka':
      case 'inaangaliwa':
        bg = AppColors.primaryBlue.withValues(alpha: 0.15);
        fg = AppColors.primaryBlue;
        break;
      case 'inashughulikiwa':
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0369A1);
        break;
      case 'imekamilika':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF14532D);
        break;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

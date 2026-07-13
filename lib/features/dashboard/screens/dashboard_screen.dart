import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/ripoti_model.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../../auth/providers/auth_provider.dart';
import '../../ripoti/providers/ripoti_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final matangazo = ref.watch(matangazoProvider);
    final userRipoti = ref.watch(userRipotiProvider);

    final displayName = user?.fullName != null && user!.fullName != 'Mtumiaji'
        ? user.fullName.split(' ').first
        : 'Mwanachama';
    final memberId = user?.memberId ?? 'MK-0000';

    // Count new reports
    final newCount = userRipoti.when(
      data: (list) => list.where((r) => r.hali == 'mpya').length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: CustomScrollView(
        slivers: [
          // ── AppBar ──────────────────────────────
          SliverAppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.menu, color: Colors.black87),
              onPressed: () {},
            ),
            title: const Text(
              'PamojaMove',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryBlue,
              ),
            ),
            centerTitle: true,
            actions: [
              Semantics(
                label: 'Arifa',
                child: IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.black87,
                  ),
                  onPressed: () {},
                ),
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── GREETING ─────────────────────────
                Semantics(
                  label: 'Habari $displayName, Mwanachama ID $memberId',
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor:
                            AppColors.primaryBlue.withValues(alpha: 0.12),
                        child: Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : 'M',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Habari, $displayName',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'MWANACHAMA • ID: $memberId',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── ANNOUNCEMENTS ────────────────────
                matangazo.when(
                  data: (list) => list.isEmpty
                      ? const SizedBox.shrink()
                      : _AnnouncementCard(data: list.first),
                  loading: () => const _AnnouncementCard(data: {
                    'kichwa': 'Taarifa ya Mfumo',
                    'maudhui': 'Marekebisho mapya yamefanyika Ubungo Kivukoni!',
                  }),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 20),

                // ── PRIMARY CTA ──────────────────────
                Semantics(
                  label: 'Ripoti Changamoto Sasa. Bonyeza kutuma ripoti mpya.',
                  button: true,
                  child: InkWell(
                    onTap: () => context.push(Routes.camera),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 36,
                        horizontal: 24,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primaryRed, Color(0xFFE14A4A)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryRed.withValues(alpha: 0.26),
                            blurRadius: 26,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: const Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined,
                                  color: Colors.white, size: 40),
                              SizedBox(width: 16),
                              Icon(Icons.location_on_outlined,
                                  color: Colors.white, size: 40),
                            ],
                          ),
                          SizedBox(height: 14),
                          Text(
                            'Ripoti Changamoto Sasa',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── QUICK ACTION CARDS ───────────────
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        label: 'Ripoti Zangu. Fuatilia ripoti zako.',
                        button: true,
                        child: _QuickCard(
                          icon: Icons.list_alt_outlined,
                          title: 'Ripoti Zangu',
                          subtitle: 'Fuatilia hali ya ripoti zako hapa.',
                          badge: newCount > 0 ? '$newCount Mapya' : null,
                          onTap: () => context.push(Routes.myReports),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Semantics(
                        label: 'Ramani ya Mapungufu. Angalia ramani ya jiji.',
                        button: true,
                        child: _QuickCard(
                          icon: Icons.map_outlined,
                          title: 'Ramani ya\nMapungufu',
                          subtitle: 'Angalia changamoto za jiji zima.',
                          bgColor: const Color(0xFFEEEEEE),
                          onTap: () => context.push(Routes.gapMap),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── RECENT REPORTS ───────────────────
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ripoti za Karibuni',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                userRipoti.when(
                  data: (list) => list.isEmpty
                      ? _buildEmptyState()
                      : Column(
                          children: list
                              .take(3) // Only show the last 3 for dashboard
                              .map((r) => _RecentReportItem(report: r))
                              .toList(),
                        ),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (_, __) => const Text('Imeshindwa kupata ripoti.'),
                ),

                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),

      // ── Bottom Nav ────────────────────────────
      bottomNavigationBar: const BottomNav(currentIndex: 0),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(Icons.assignment_outlined, color: AppColors.textHint, size: 48),
          SizedBox(height: 12),
          Text(
            'Bado hujaandika ripoti yoyote.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _RecentReportItem extends StatelessWidget {
  final RipotiModel report;
  const _RecentReportItem({required this.report});

  @override
  Widget build(BuildContext context) {
    final isSolved = report.hali == 'imekamilika';

    return InkWell(
      onTap: () => context.push(Routes.reportTimeline, extra: report.id),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon based on type
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isSolved ? AppColors.success : AppColors.primaryBlue)
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSolved ? Icons.check_circle_outline : Icons.pending_actions,
                color: isSolved ? AppColors.success : AppColors.primaryBlue,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.ainaLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    report.eneo ?? report.wilaya ?? 'Eneo lisilojulikana',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(report.hali).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getStatusColor(report.hali).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                report.haliLabel,
                style: TextStyle(
                  color: _getStatusColor(report.hali),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String hali) {
    switch (hali) {
      case 'mpya':
        return AppColors.badgeGold;
      case 'inashughulikiwa':
        return AppColors.primaryBlue;
      case 'imekamilika':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }
}

// ─────────────────────────────────────────────
class _AnnouncementCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AnnouncementCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${data['kichwa']}: ${data['maudhui']}',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.announcementBlue, AppColors.darkBlue],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.campaign_outlined,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['kichwa'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['maudhui'] as String,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final Color bgColor;
  final VoidCallback onTap;

  const _QuickCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.bgColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.bgLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (badge != null) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.badgeGold,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

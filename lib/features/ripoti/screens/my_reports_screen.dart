import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/models/ripoti_model.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../providers/ripoti_provider.dart';

class MyReportsScreen extends ConsumerStatefulWidget {
  const MyReportsScreen({super.key});

  @override
  ConsumerState<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends ConsumerState<MyReportsScreen> {
  String _filter = 'zote';

  @override
  Widget build(BuildContext context) {
    final ripotiAsync = ref.watch(userRipotiProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation:       0.5,
            pinned:          true,
            expandedHeight:  100,
            flexibleSpace: const FlexibleSpaceBar(
              title: Text(
                'Ripoti Zangu',
                style: TextStyle(
                  color:      Colors.black87,
                  fontWeight: FontWeight.w800,
                  fontSize:   16,
                ),
              ),
              centerTitle: true,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.primaryBlue),
                onPressed: () => ref.invalidate(userRipotiProvider),
              ),
            ],
          ),

          // ── Filters ───────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('Zote',      'zote'),
                    _filterChip('Mpya',      'mpya'),
                    _filterChip('Inashughulikiwa', 'inashughulikiwa'),
                    _filterChip('Iliokamilika',    'imekamilika'),
                  ],
                ),
              ),
            ),
          ),

          // ── List ──────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: ripotiAsync.when(
              data: (list) {
                final filtered = _filter == 'zote'
                    ? list
                    : list.where((r) => r.hali == _filter).toList();

                if (filtered.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.description_outlined,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Huna ripoti yoyote hapa.'),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, i) => _UserReportCard(
                      report: filtered[i],
                    ),
                    childCount: filtered.length,
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, __) => SliverFillRemaining(
                child: Center(
                  child: Text('Hitilafu: ${err.toString()}'),
                ),
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: const BottomNav(currentIndex: 1),
    );
  }

  Widget _filterChip(String label, String key) {
    final active = _filter == key;
    return GestureDetector(
      onTap: () => setState(() => _filter = key),
      child: Container(
        margin:  const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:        active ? AppColors.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(
            color: active ? AppColors.primaryBlue : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:      active ? Colors.white : AppColors.textSecondary,
            fontSize:   12,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _UserReportCard extends StatelessWidget {
  final RipotiModel report;
  const _UserReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final isSolved = report.hali == 'imekamilika';

    return GestureDetector(
      onTap: () => context.push(Routes.reportTimeline, extra: report.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Icon based on type (Dashboard style)
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
                          fontSize:   14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        report.eneo ?? report.wilaya ?? 'Eneo lisilojulikana',
                        style: const TextStyle(
                          color:    AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:        _getStatusColor(report.hali).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border:       Border.all(
                      color: _getStatusColor(report.hali).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    report.haliLabel,
                    style: TextStyle(
                      color:      _getStatusColor(report.hali),
                      fontSize:   10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 0.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  report.dateFormatted,
                  style: const TextStyle(
                    fontSize: 11,
                    color:    AppColors.textHint,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Navigate to map and focus on this location
                    // For now, we go to gapMap. In a real app, we'd pass coordinates.
                    context.push(Routes.gapMap);
                  },
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: const Text(
                    'Angalia kwenye Ramani',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String hali) {
    switch (hali) {
      case 'mpya':            return AppColors.badgeGold;
      case 'inashughulikiwa': return AppColors.primaryBlue;
      case 'imekamilika':     return AppColors.success;
      default:                return AppColors.textSecondary;
    }
  }
}

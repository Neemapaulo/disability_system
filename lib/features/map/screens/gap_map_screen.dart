import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/ripoti_model.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../../ripoti/providers/ripoti_provider.dart';

const _darCenter = LatLng(-6.7924, 39.2083);
const _mapTilerKey = 'WJJkkUF7ZR4ONv2iXSdu';

class GapMapScreen extends ConsumerStatefulWidget {
  const GapMapScreen({super.key});

  @override
  ConsumerState<GapMapScreen> createState() => _GapMapScreenState();
}

class _GapMapScreenState extends ConsumerState<GapMapScreen> {
  final MapController _mapCtrl = MapController();
  RipotiModel?        _selectedRipoti;

  Future<void> _jumpToMe() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      _mapCtrl.move(LatLng(pos.latitude, pos.longitude), 15);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imeshindwa kupata eneo lako.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ripotiAsync = ref.watch(mapRipotiProvider);

    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapCtrl,
            options: const MapOptions(
              initialCenter: _darCenter,
              initialZoom:   12,
              maxZoom:       18,
              minZoom:       10,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://api.maptiler.com/maps/basic-v2/{z}/{x}/{y}.png?key=$_mapTilerKey',
                userAgentPackageName: 'com.mkmu.app',
              ),
              ripotiAsync.when(
                data: (list) => MarkerLayer(
                  markers: list.map((r) => _buildMarker(r)).toList(),
                ),
                loading: () => const MarkerLayer(markers: []),
                error:   (_, __) => const MarkerLayer(markers: []),
              ),
            ],
          ),

          // ── TOP OVERLAY ──────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSearchBox(),
                  const SizedBox(height: 12),
                  _buildFilterChips(),
                ],
              ),
            ),
          ),

          // ── SNIPER BUTTON (MY LOCATION) ──────────
          Positioned(
            right: 16,
            bottom: _selectedRipoti != null ? 320 : 100,
            child: FloatingActionButton(
              onPressed: _jumpToMe,
              backgroundColor: Colors.white,
              elevation: 4,
              child: const Icon(Icons.my_location, color: AppColors.primaryRed, size: 28),
            ),
          ),

          // ── BOTTOM OVERLAY (Detail Card) ─────────
          if (_selectedRipoti != null)
            Positioned(
              bottom: 20, left: 16, right: 16,
              child: _RipotiPopup(
                ripoti: _selectedRipoti!,
                onClose: () => setState(() => _selectedRipoti = null),
                onViewDetail: () {
                  context.push(Routes.reportTimeline, extra: _selectedRipoti!.id);
                },
              ),
            ),

          if (ripotiAsync.isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 2),
    );
  }

  Marker _buildMarker(RipotiModel r) {
    final isSelected = _selectedRipoti?.id == r.id;
    final isSolved   = r.hali == 'imekamilika';

    return Marker(
      point: LatLng(r.latitude, r.longitude),
      width:  isSelected ? 65 : 50,
      height: isSelected ? 65 : 50,
      child: GestureDetector(
        onTap: () => setState(() => _selectedRipoti = r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppColors.primaryRed 
                : (isSolved ? AppColors.success : _getColor(r.aina)),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            isSolved ? Icons.check_circle_outline : _getIcon(r.aina),
            color: Colors.white,
            size: isSelected ? 32 : 24,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText:  'Tafuta eneo au wilaya...',
          hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
          border:    InputBorder.none,
          icon:      Icon(Icons.search, color: AppColors.primaryBlue),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filter = ref.watch(mapFilterProvider);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip('Zote', 'zote', active: filter.aina == 'zote' || filter.aina == null,
            onTap: () => ref.read(mapFilterProvider.notifier).update((s) => s.copyWith(aina: 'zote'))),
          _filterChip('Njia', 'njia_kutopitika', active: filter.aina == 'njia_kutopitika',
            onTap: () => ref.read(mapFilterProvider.notifier).update((s) => s.copyWith(aina: 'njia_kutopitika'))),
          _filterChip('Vituo', 'kituo_hakina_rampu', active: filter.aina == 'kituo_hakina_rampu',
            onTap: () => ref.read(mapFilterProvider.notifier).update((s) => s.copyWith(aina: 'kituo_hakina_rampu'))),
          _filterChip('Makutano', 'makutano_yasio_salama', active: filter.aina == 'makutano_yasio_salama',
            onTap: () => ref.read(mapFilterProvider.notifier).update((s) => s.copyWith(aina: 'makutano_yasio_salama'))),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String key, {required bool active, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.primaryBlue : AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
        ),
        child: Text(label, style: TextStyle(color: active ? Colors.white : AppColors.textPrimary, fontSize: 12, fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
      ),
    );
  }

  Color _getColor(String aina) {
    switch (aina) {
      case 'njia_kutopitika':       return const Color(0xFFEA580C);
      case 'kituo_hakina_rampu':    return const Color(0xFF2563EB);
      case 'makutano_yasio_salama': return const Color(0xFFDC2626);
      default:                      return const Color(0xFF64748B);
    }
  }

  IconData _getIcon(String aina) {
    switch (aina) {
      case 'njia_kutopitika':       return Icons.warning_amber_rounded;
      case 'kituo_hakina_rampu':    return Icons.directions_bus_outlined;
      case 'makutano_yasio_salama': return Icons.traffic_outlined;
      default:                      return Icons.location_on_outlined;
    }
  }
}

class _RipotiPopup extends StatelessWidget {
  final RipotiModel  ripoti;
  final VoidCallback onViewDetail;
  final VoidCallback onClose;

  const _RipotiPopup({required this.ripoti, required this.onViewDetail, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8, borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ripoti.pichaUrl != null
                    ? Image.network(ripoti.pichaUrl!, width: 80, height: 70, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _ImgPlaceholder(aina: ripoti.aina))
                    : _ImgPlaceholder(aina: ripoti.aina),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(ripoti.ainaLabel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis)),
                  GestureDetector(onTap: onClose, child: const Icon(Icons.close, size: 18, color: AppColors.textSecondary)),
                ]),
                const SizedBox(height: 4),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: _haliColor(ripoti.hali), borderRadius: BorderRadius.circular(12)),
                  child: Text(ripoti.haliLabel, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600))),
                const SizedBox(height: 6),
                Text(ripoti.eneo ?? ripoti.wilaya ?? 'DSM', style: const TextStyle(color: AppColors.primaryBlue, fontSize: 12, fontWeight: FontWeight.w500)),
              ])),
            ]),
            const SizedBox(height: 12),
            Text(ripoti.maelezo, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: onViewDetail,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('Angalia Maelezo Kamili →', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
          ],
        ),
      ),
    );
  }

  Color _haliColor(String hali) {
    switch (hali) {
      case 'mpya':            return AppColors.badgeGold;
      case 'inashughulikiwa': return AppColors.primaryBlue;
      case 'imekamilika':     return AppColors.success;
      default:                return Colors.grey;
    }
  }
}

class _ImgPlaceholder extends StatelessWidget {
  final String aina;
  const _ImgPlaceholder({required this.aina});
  @override
  Widget build(BuildContext context) => Container(width: 80, height: 70, color: AppColors.bgLight, child: const Icon(Icons.broken_image_outlined, color: AppColors.textSecondary));
}

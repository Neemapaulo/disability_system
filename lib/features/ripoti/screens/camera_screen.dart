import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../providers/ripoti_provider.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  final _picker = ImagePicker();
  bool _gettingGps = false;
  bool _locationFound = false;
  bool _locationError = false;
  String? _errorMessage;

  // ── GPS fetch on init ──────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _gettingGps = true;
      _locationError = false;
      _errorMessage = null;
    });

    try {
      final loc = await ref.read(locationServiceProvider).getCurrentLocation();

      ref.read(captureProvider.notifier).setLocation(loc);

      setState(() {
        _gettingGps = false;
        _locationFound = true;
      });
    } catch (e) {
      setState(() {
        _gettingGps = false;
        _locationError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _takePhoto() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 100, // Maximum quality for web admin viewing
      preferredCameraDevice: CameraDevice.rear,
    );

    if (xFile == null) return;

    ref.read(captureProvider.notifier).setPhoto(File(xFile.path));

    if (!mounted) return;
    context.push(Routes.reportForm);
  }

  Future<void> _pickFromGallery() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100, // Maximum quality
    );

    if (xFile == null) return;

    ref.read(captureProvider.notifier).setPhoto(File(xFile.path));

    if (!mounted) return;
    context.push(Routes.reportForm);
  }

  @override
  Widget build(BuildContext context) {
    final capture = ref.watch(captureProvider);
    final location = capture.location;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'PamojaMove',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.primaryRed,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Hatua ya 1 ya 3',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── LOCATION STATUS BANNER ─────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: _locationError
                    ? AppColors.error.withValues(alpha: 0.12)
                    : _locationFound
                        ? AppColors.primaryBlue
                        : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    _locationError
                        ? Icons.location_off_outlined
                        : _locationFound
                            ? Icons.check_circle_outline
                            : Icons.gps_not_fixed,
                    color: _locationError
                        ? AppColors.error
                        : _locationFound
                            ? Colors.white
                            : Colors.grey,
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _locationError
                          ? _errorMessage ?? 'GPS imeshindwa. Gusa kurudia.'
                          : _locationFound
                              ? '✓ Eneo limegundulika kikamilifu!'
                              : _gettingGps
                                  ? 'Inapata eneo lako...'
                                  : 'Subiri GPS...',
                      style: TextStyle(
                        color: _locationError
                            ? AppColors.error
                            : _locationFound
                                ? Colors.white
                                : Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (_gettingGps)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.grey,
                      ),
                    ),
                  if (_locationError)
                    TextButton(
                      onPressed: _fetchLocation,
                      child: const Text(
                        'Rudia',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                ],
              ),
            ),

            // ── CAMERA PREVIEW BOX ─────────────────
            Semantics(
              label: 'Eneo la picha. Piga picha ya changamoto.',
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.border,
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Camera placeholder background
                        Container(
                          color: const Color(0xFF1C2833),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt_outlined,
                                  color: Colors.white.withValues(alpha: 0.3),
                                  size: 80,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Kamera iko tayari',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Crosshair overlay
                        Center(
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),

                        // Location chip overlay
                        if (location != null)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: AppColors.primaryRed,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          location.eneo,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const Text(
                                          'Inasawazisha mita 5 (GPS)',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── TITLE ─────────────────────────────
            const Text(
              'Chukua Picha na Eneo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Hakikisha picha inaonyesha wazi tatizo la miundombinu unayoripoti.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── CAPTURE BUTTONS ───────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Gallery
                Semantics(
                  label: 'Chagua picha kutoka maktaba',
                  button: true,
                  child: _CircleAction(
                    icon: Icons.photo_library_outlined,
                    label: 'Maktaba',
                    onTap: _pickFromGallery,
                    small: true,
                  ),
                ),

                const SizedBox(width: 24),

                // Camera shutter
                Semantics(
                  label: 'Piga picha',
                  button: true,
                  child: _CircleAction(
                    icon: Icons.camera_alt,
                    label: 'Piga Picha',
                    onTap: _takePhoto,
                    primary: true,
                    labelColor: AppColors.primaryRed,
                  ),
                ),

                const SizedBox(width: 24),

                // Flash toggle
                Semantics(
                  label: 'Mwanga wa tochi',
                  button: true,
                  child: _CircleAction(
                    icon: Icons.flash_auto_outlined,
                    label: 'Mwanga',
                    onTap: () {},
                    small: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── MAP PREVIEW CHIP ──────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.map_outlined,
                        color: AppColors.primaryBlue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ramani ya Eneo',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            location != null
                                ? '${location.wilaya}, Dar es Salaam'
                                : 'Inatambulika na PamojaMove Mapping',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push(Routes.gapMap),
                      child: const Text(
                        'Badili',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _CircleAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;
  final bool small;
  final Color? labelColor;

  const _CircleAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.small = false,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final size = primary ? 76.0 : 52.0;
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: primary ? AppColors.primaryRed : Colors.grey.shade200,
              shape: BoxShape.circle,
              boxShadow: primary
                  ? [
                      BoxShadow(
                        color: AppColors.primaryRed.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: primary ? Colors.white : Colors.black54,
              size: primary ? 34 : 24,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: labelColor ?? AppColors.textSecondary,
            fontWeight: primary ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

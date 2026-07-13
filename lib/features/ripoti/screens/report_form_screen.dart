import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../providers/ripoti_provider.dart';

class ReportFormScreen extends ConsumerStatefulWidget {
  const ReportFormScreen({super.key});

  @override
  ConsumerState<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends ConsumerState<ReportFormScreen> {
  final _descCtrl = TextEditingController();
  String? _selectedAina;

  static const _ainaOptions = [
    ('njia_kutopitika',       'Njia kutopitika / Miundombinu mibovu'),
    ('kituo_hakina_rampu',    'Kituo cha basi hakina ngazi/rampu'),
    ('makutano_yasio_salama', 'Makutano ya barabara yasiyo salama'),
    ('ukosefu_miongozo',      'Ukosefu wa miongozo ya sauti au alama'),
    ('nyingine',              'Nyingine'),
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedAina == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tafadhali chagua aina ya changamoto kabla ya kutuma.',
          ),
          backgroundColor: AppColors.error,
          behavior:        SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:         Text('Tafadhali andika maelezo mafupi.'),
          backgroundColor: AppColors.error,
          behavior:        SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ref.read(captureProvider.notifier).setAina(_selectedAina!);
    ref.read(captureProvider.notifier).setMaelezo(_descCtrl.text.trim());

    final success = await ref.read(captureProvider.notifier).submit();

    if (!mounted) return;

    if (success) {
      context.pushReplacement(Routes.reportSuccess);
    } else {
      final error = ref.read(captureProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:         Text(error ?? 'Imeshindwa kutuma.'),
          backgroundColor: AppColors.error,
          behavior:        SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final capture  = ref.watch(captureProvider);
    final location = capture.location;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Maelezo ya Changamoto',
          style: TextStyle(
            fontSize:   17,
            fontWeight: FontWeight.w700,
            color:      Colors.black87,
          ),
        ),
        actions: [
          Semantics(
            label:  'Msaada',
            button: true,
            child: IconButton(
              icon: const Icon(
                Icons.help_outline,
                color: Colors.black54,
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── STEP INDICATOR ─────────────────────
            const _StepIndicator(currentStep: 1),

            const SizedBox(height: 28),

            // ── PHOTO PREVIEW ──────────────────────
            const Text(
              'Picha ya Changamoto',
              style: TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),

            if (capture.pichaFile != null)
              _PhotoPreview(
                file:    capture.pichaFile!,
                onRetry: () {
                  ref.read(captureProvider.notifier).discardPhoto();
                  context.pop();
                },
              )
            else
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color:        AppColors.bgLight,
                    borderRadius: BorderRadius.circular(14),
                    border:       Border.all(
                      color: AppColors.border,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          size:  40,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Gusa kupiga picha',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // ── GPS COORDS ─────────────────────────
            Semantics(
              label: location != null
                  ? 'GPS: ${location.latitude}, ${location.longitude}, ${location.wilaya}'
                  : 'GPS haijapatikana',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mahali (GPS)',
                    style: TextStyle(
                      fontSize:   13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color:        AppColors.bgLight,
                      borderRadius: BorderRadius.circular(12),
                      border:       Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primaryBlue,
                          size:  20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            location != null
                                ? '${location.latitude.toStringAsFixed(4)}, '
                                '${location.longitude.toStringAsFixed(4)} '
                                '(${location.wilaya})'
                                : 'GPS haijapatikana...',
                            style: const TextStyle(
                              fontSize:   13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.lock_outline,
                          color: AppColors.textSecondary,
                          size:  18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── AREA HIERARCHY (Mkoa → Wilaya → Kata)
            if (location != null) ...[
              const Text(
                'Eneo la Kina',
                style: TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:        AppColors.primaryBlue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border:       Border.all(
                    color: AppColors.primaryBlue.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    _AreaChip(
                      label: 'Mkoa',
                      value: location.mkoa,
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                      size:  18,
                    ),
                    _AreaChip(
                      label: 'Wilaya',
                      value: location.wilaya,
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                      size:  18,
                    ),
                    _AreaChip(
                      label: 'Kata',
                      value: location.kata,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── CATEGORY DROPDOWN ──────────────────
            Semantics(
              label: 'Chagua aina ya changamoto',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aina ya Kikwazo',
                    style: TextStyle(
                      fontSize:   13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedAina,
                    hint: const Text('Chagua aina ya changamoto...'),
                    onChanged:   (v) => setState(() => _selectedAina = v),
                    items: _ainaOptions
                        .map(
                          (opt) => DropdownMenuItem(
                        value: opt.$1,
                        child: Text(
                          opt.$2,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                        .toList(),
                    decoration: InputDecoration(
                      filled:    true,
                      fillColor: AppColors.bgLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:   const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:   const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:   const BorderSide(
                          color: AppColors.primaryBlue, width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14,
                      ),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── DESCRIPTION ────────────────────────
            Semantics(
              label: 'Andika maelezo ya changamoto',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Eleza kwa ufupi changamoto hii',
                    style: TextStyle(
                      fontSize:   13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller:  _descCtrl,
                    maxLines:    5,
                    minLines:    4,
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Mfano: Njia ya watembea kwa miguu hapa '
                          'imebomoka kabisa, viti mwendo haviwezi kupita...',
                      hintStyle: const TextStyle(
                        color:    AppColors.textHint,
                        fontSize: 13,
                      ),
                      filled:    true,
                      fillColor: AppColors.bgLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:   const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:   const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:   const BorderSide(
                          color: AppColors.primaryBlue, width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── SUBMIT BUTTON ──────────────────────
            Semantics(
              label:  'Tuma Taarifa',
              button: true,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: capture.isSubmitting ? null : _submit,
                  icon: capture.isSubmitting
                      ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.send_outlined, size: 18),
                  label: Text(
                    capture.isSubmitting
                        ? 'Inatuma...'
                        : 'Tuma Taarifa',
                    style: const TextStyle(
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

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side:    const BorderSide(color: AppColors.primaryBlue),
                  shape:   RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Rudi nyuma',
                  style: TextStyle(
                    color:      AppColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
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
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('Mahali',  Icons.check),
      ('Maelezo', null),
      ('Hakiki',  null),
    ];

    return Row(
      children: List.generate(steps.length, (i) {
        final done    = i < currentStep;
        final active  = i == currentStep;
        final label   = steps[i].$1;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: done || active
                            ? AppColors.primaryBlue
                            : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: done
                            ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size:  18,
                        )
                            : Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: active
                                ? Colors.white
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize:   14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color:    done || active
                            ? AppColors.primaryBlue
                            : Colors.grey,
                        fontWeight: active
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 22),
                    color: i < currentStep
                        ? AppColors.primaryBlue
                        : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────
class _PhotoPreview extends StatelessWidget {
  final File         file;
  final VoidCallback onRetry;
  const _PhotoPreview({required this.file, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(
            file,
            width:  double.infinity,
            height: 200,
            fit:    BoxFit.cover,
          ),
        ),

        // X button
        Positioned(
          top: 10, right: 10,
          child: Semantics(
            label:  'Futa picha na anza upya',
            button: true,
            child: GestureDetector(
              onTap: onRetry,
              child: Container(
                width: 36, height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.primaryRed, shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close, color: Colors.white, size: 18,
                ),
              ),
            ),
          ),
        ),

        // Filename
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 8,
            ),
            decoration: const BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.only(
                bottomLeft:  Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.image_outlined,
                  color: Colors.white70,
                  size:  14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    file.path.split('/').last,
                    style: const TextStyle(
                      color:    Colors.white70,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
class _AreaChip extends StatelessWidget {
  final String label;
  final String value;
  const _AreaChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color:    AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize:   12,
              fontWeight: FontWeight.w700,
              color:      AppColors.primaryBlue,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

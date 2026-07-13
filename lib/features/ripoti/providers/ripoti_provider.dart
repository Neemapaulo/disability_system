import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/ripoti_model.dart';
import '../../../core/services/ripoti_service.dart';
import '../../../core/services/location_service.dart';
import '../../auth/providers/auth_provider.dart';


// ── Service providers ──────────────────────────
final ripotiServiceProvider = Provider<RipotiService>(
      (_) => RipotiService(),
);
final locationServiceProvider = Provider<LocationService>(
      (_) => LocationService(),
);

// ══════════════════════════════════════════════
// CAPTURE STATE
// Holds transient data during the 3-step
// report wizard (Screen 7 → 8 → 9)
// ══════════════════════════════════════════════
class CaptureState {
  final File?           pichaFile;
  final LocationResult? location;
  final String?         aina;
  final String          maelezo;
  final bool            isSubmitting;
  final String?         errorMessage;
  final RipotiModel?    submittedRipoti;

  const CaptureState({
    this.pichaFile,
    this.location,
    this.aina,
    this.maelezo        = '',
    this.isSubmitting   = false,
    this.errorMessage,
    this.submittedRipoti,
  });

  bool get hasPhoto    => pichaFile != null;
  bool get hasLocation => location  != null;
  bool get isReady     => hasPhoto && hasLocation;

  CaptureState copyWith({
    File?           pichaFile,
    LocationResult? location,
    String?         aina,
    String?         maelezo,
    bool?           isSubmitting,
    String?         errorMessage,
    RipotiModel?    submittedRipoti,
  }) =>
      CaptureState(
        pichaFile:       pichaFile       ?? this.pichaFile,
        location:        location        ?? this.location,
        aina:            aina            ?? this.aina,
        maelezo:         maelezo         ?? this.maelezo,
        isSubmitting:    isSubmitting    ?? this.isSubmitting,
        errorMessage:    errorMessage,
        submittedRipoti: submittedRipoti ?? this.submittedRipoti,
      );
}

class CaptureNotifier extends StateNotifier<CaptureState> {
  final RipotiService   _ripotiSvc;
  final String          _userId;

  CaptureNotifier(this._ripotiSvc, LocationService locationSvc, this._userId)
      : super(const CaptureState());

  // Set captured photo
  void setPhoto(File file) {
    state = state.copyWith(pichaFile: file);
  }

  // Set GPS location
  void setLocation(LocationResult loc) {
    state = state.copyWith(location: loc);
  }

  // Set category
  void setAina(String aina) {
    state = state.copyWith(aina: aina);
  }

  // Set description
  void setMaelezo(String text) {
    state = state.copyWith(maelezo: text);
  }

  // Discard photo and restart
  void discardPhoto() {
    state = state.copyWith(
      pichaFile:    null,
      errorMessage: null,
    );
  }

  // Reset entire wizard
  void reset() {
    state = const CaptureState();
  }

  // ── SUBMIT REPORT ──────────────────────────────
  Future<bool> submit() async {
    if (state.location == null) {
      state = state.copyWith(
        errorMessage: 'GPS haijapata eneo. Jaribu tena.',
      );
      return false;
    }

    if (state.aina == null || state.aina!.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Tafadhali chagua aina ya changamoto.',
      );
      return false;
    }

    if (state.maelezo.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: 'Tafadhali andika maelezo mafupi.',
      );
      return false;
    }

    state = state.copyWith(
      isSubmitting: true,
      errorMessage: null,
    );

    try {
      final loc = state.location!;
      final ripoti = await _ripotiSvc.submitRipoti(
        userId:    _userId,
        aina:      state.aina!,
        maelezo:   state.maelezo,
        latitude:  loc.latitude,
        longitude: loc.longitude,
        mkoa:      loc.mkoa,
        wilaya:    loc.wilaya,
        kata:      loc.kata,
        eneo:      loc.eneo,
        pichaFile: state.pichaFile,
      );

      state = state.copyWith(
        isSubmitting:    false,
        submittedRipoti: ripoti,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Imeshindwa kutuma: $e',
      );
      return false;
    }
  }
}

final captureProvider =
StateNotifierProvider<CaptureNotifier, CaptureState>((ref) {
  final user = ref.watch(authProvider).user;
  return CaptureNotifier(
    ref.watch(ripotiServiceProvider),
    ref.watch(locationServiceProvider),
    user?.id ?? '',
  );
});

// ══════════════════════════════════════════════
// USER REPORTS LIST PROVIDER
// ══════════════════════════════════════════════
final userRipotiProvider =
FutureProvider.autoDispose<List<RipotiModel>>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null) return [];
  return ref.watch(ripotiServiceProvider).getUserRipoti(user.id);
});

// ══════════════════════════════════════════════
// MAP REPORTS PROVIDER (filterable)
// ══════════════════════════════════════════════
class MapFilterState {
  final String? wilaya;
  final String? kata;
  final String? aina;

  const MapFilterState({this.wilaya, this.kata, this.aina});

  MapFilterState copyWith({
    String? wilaya,
    String? kata,
    String? aina,
  }) =>
      MapFilterState(
        wilaya: wilaya ?? this.wilaya,
        kata:   kata   ?? this.kata,
        aina:   aina   ?? this.aina,
      );
}

final mapFilterProvider =
StateProvider<MapFilterState>((_) => const MapFilterState());

final mapRipotiProvider =
FutureProvider.autoDispose<List<RipotiModel>>((ref) async {
  final filter = ref.watch(mapFilterProvider);
  final user   = ref.watch(authProvider).user;
  
  return ref.watch(ripotiServiceProvider).getAllRipoti(
    managedMkoa:   user?.managedMkoa,
    managedWilaya: user?.managedWilaya,
    managedKata:   user?.managedKata,
    aina:          filter.aina,
  );
});

// ── Single report watcher (for timeline screen) ─
final watchRipotiProvider =
StreamProvider.autoDispose.family<RipotiModel, String>((ref, id) {
  return ref.watch(ripotiServiceProvider).watchRipoti(id);
});

// ── Announcements ──────────────────────────────
final matangazoProvider =
FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(ripotiServiceProvider).getMatangazo();
});
import 'package:intl/intl.dart';

class RipotiModel {
  final String  id;
  final String  userId;
  final String  aina;
  final String  maelezo;
  final double  latitude;
  final double  longitude;
  final String? eneo;
  final String? mkoa;
  final String? wilaya;
  final String? kata;
  final String? pichaUrl;
  final String  hali;
  final String? maoniYaAdmin;
  
  // Infrastructure Priority Index (IPI) fields
  final int     frequencyCount;
  final double  severityWeight;
  final double  priorityScore;
  
  final DateTime createdAt;
  final DateTime? adminUpdatedAt;

  const RipotiModel({
    required this.id,
    required this.userId,
    required this.aina,
    required this.maelezo,
    required this.latitude,
    required this.longitude,
    this.eneo,
    this.mkoa,
    this.wilaya,
    this.kata,
    this.pichaUrl,
    required this.hali,
    this.maoniYaAdmin,
    this.frequencyCount = 1,
    this.severityWeight = 1.0,
    this.priorityScore  = 0.0,
    required this.createdAt,
    this.adminUpdatedAt,
  });

  factory RipotiModel.fromJson(Map<String, dynamic> j) => RipotiModel(
    id:             j['id'] as String,
    userId:         j['user_id'] as String? ?? '',
    aina:           j['aina'] as String,
    maelezo:        j['maelezo'] as String,
    latitude:       (j['latitude'] as num).toDouble(),
    longitude:      (j['longitude'] as num).toDouble(),
    eneo:           j['eneo_jina'] as String?,
    mkoa:           j['mkoa'] as String?,
    wilaya:         j['wilaya'] as String?,
    kata:           j['kata'] as String?,
    pichaUrl:       j['picha_url'] as String?,
    hali:           j['hali'] as String,
    maoniYaAdmin:   j['maoni_ya_admin'] as String?,
    frequencyCount: j['frequency_count'] as int? ?? 1,
    severityWeight: (j['severity_weight'] as num? ?? 1.0).toDouble(),
    priorityScore:  (j['priority_score'] as num? ?? 0.0).toDouble(),
    createdAt:      DateTime.parse(j['created_at'] as String),
    adminUpdatedAt: j['admin_updated_at'] != null
        ? DateTime.parse(j['admin_updated_at'] as String)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'user_id':          userId,
    'aina':             aina,
    'maelezo':          maelezo,
    'latitude':         latitude,
    'longitude':        longitude,
    'eneo_jina':        eneo,
    'mkoa':             mkoa,
    'wilaya':           wilaya,
    'kata':             kata,
    'picha_url':        pichaUrl,
    'hali':             hali,
    'severity_weight':  severityWeight,
  };

  // ── Display helpers ──────────────────────────
  String get ainaLabel {
    const map = {
      'njia_kutopitika':       'Njia kutopitika / Miundombinu mibovu',
      'kituo_hakina_rampu':    'Kituo cha basi hakina ngazi/rampu',
      'makutano_yasio_salama': 'Makutano ya barabara yasiyo salama',
      'ukosefu_miongozo':      'Ukosefu wa miongozo ya sauti au alama',
      'nyingine':              'Nyingine',
    };
    return map[aina] ?? aina;
  }

  String get haliLabel {
    const map = {
      'mpya':             'Inasubiri Mapitio',
      'inaangaliwa':      'Inaangaliwa',
      'imepewa_mamlaka':  'Mamlaka Imepewa Taarifa',
      'inashughulikiwa':  'Inashughulikiwa na Baraza',
      'imekamilika':      'Imetatuliwa',
    };
    return map[hali] ?? hali;
  }

  String get dateFormatted =>
      DateFormat('MMM dd, yyyy', 'sw').format(createdAt);

  String get coordsFormatted =>
      '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
      
  /// Returns a color based on the Priority Score (IPI)
  int get priorityColor {
    if (priorityScore >= 7.5) return 0xFFDC2626; // High Priority (Red)
    if (priorityScore >= 4.0) return 0xFFEA580C; // Medium Priority (Orange)
    return 0xFF2563EB; // Low Priority (Blue)
  }
}

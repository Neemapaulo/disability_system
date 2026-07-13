import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ripoti_model.dart';

class RipotiService {
  static final RipotiService _i = RipotiService._();
  factory RipotiService() => _i;
  RipotiService._();

  final _supabase = Supabase.instance.client;
  static const _bucket = 'mkmu-picha';

  Future<RipotiModel?> submitRipoti({
    required String userId,
    required String aina,
    required String maelezo,
    required double latitude,
    required double longitude,
    required String mkoa,
    required String wilaya,
    required String kata,
    required String eneo,
    File? pichaFile,
  }) async {
    String? pichaUrl;

    if (pichaFile != null) {
      final ext = pichaFile.path.split('.').last;
      final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';

      await _supabase.storage
          .from(_bucket)
          .upload(path, pichaFile);

      pichaUrl = _supabase.storage
          .from(_bucket)
          .getPublicUrl(path);
    }

    final data = await _supabase.from('ripoti').insert({
      'user_id':   userId,
      'aina':      aina,
      'maelezo':   maelezo,
      'latitude':  latitude,
      'longitude': longitude,
      'mkoa':      mkoa,
      'wilaya':    wilaya,
      'kata':      kata,
      'eneo':      eneo,
      'picha_url': pichaUrl,
      'hali':      'reported',
    }).select().single();

    return RipotiModel.fromJson(data);
  }

  Future<List<RipotiModel>> getUserRipoti(String userId) async {
    final data = await _supabase
        .from('ripoti')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (data as List).map((e) => RipotiModel.fromJson(e)).toList();
  }

  Future<List<RipotiModel>> getAllRipoti({
    String? managedMkoa,
    String? managedWilaya,
    String? managedKata,
    String? aina,
  }) async {
    var query = _supabase.from('ripoti').select();

    if (managedWilaya != null) {
      query = query.eq('wilaya', managedWilaya);
    } else if (managedMkoa != null) {
      query = query.eq('mkoa', managedMkoa);
    }

    if (aina != null) query = query.eq('aina', aina);

    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => RipotiModel.fromJson(e)).toList();
  }

  Stream<RipotiModel> watchRipoti(String id) {
    return _supabase
        .from('ripoti')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((data) => RipotiModel.fromJson(data.first));
  }

  Future<List<Map<String, dynamic>>> getMatangazo() async {
    final data = await _supabase
        .from('matangazo')
        .select()
        .order('created_at', ascending: false)
        .limit(5);
    return List<Map<String, dynamic>>.from(data);
  }
}
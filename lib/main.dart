import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/supabase_constants.dart';
import 'core/services/deep_link_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Report dates are formatted in Swahili. Without this the formatter throws
  // LocaleDataException while a report card is building, and in a release
  // build Flutter renders the crashed widget as a blank grey box — which is
  // what "Ripoti Zangu" showed instead of the user's reports.
  await initializeDateFormatting('sw');

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConstants.url,
    anonKey: SupabaseConstants.anonKey,
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Start listening for deep links (email verification callbacks)
  DeepLinkService().initialize();

  runApp(const ProviderScope(child: MkmuApp()));
}
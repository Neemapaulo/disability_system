// Guards the crash that made "Ripoti Zangu" render as a blank grey box:
// RipotiModel.dateFormatted formats dates in Swahili, which throws
// LocaleDataException unless main() initializes the locale data first.
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mkmu_app/core/models/ripoti_model.dart';

RipotiModel _report() => RipotiModel(
      id: 'x',
      userId: 'u',
      aina: 'nyingine',
      maelezo: 'm',
      latitude: 0,
      longitude: 0,
      hali: 'mpya',
      createdAt: DateTime(2026, 7, 14),
    );

void main() {
  test('Swahili date formatting works once main() has initialized it', () async {
    // Same call main() makes at startup.
    await initializeDateFormatting('sw');

    expect(_report().dateFormatted, isNotEmpty);
  });
}

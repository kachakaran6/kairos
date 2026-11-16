import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'time_service.dart';

/// The one clock every feature reads. Tests override this provider with a
/// fixed clock instead of sleeping.
final clockProvider = Provider<Clock>((ref) => const SystemClock());

import 'package:flutter/widgets.dart';

import '../services/ffi_api.dart';

/// Exposes [FfiApi] to the widget tree and rebuilds dependents when
/// auth state changes (login / logout / forced re-login).
class ApiScope extends InheritedNotifier<FfiApi> {
  const ApiScope({super.key, required FfiApi api, required super.child}) : super(notifier: api);

  static FfiApi of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ApiScope>();
    assert(scope != null, 'ApiScope not found in widget tree');
    return scope!.notifier!;
  }

  /// Non-subscribing lookup, safe in callbacks / async handlers.
  static FfiApi read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<ApiScope>();
    assert(scope != null, 'ApiScope not found in widget tree');
    return scope!.notifier!;
  }
}

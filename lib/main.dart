import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/home_screen.dart';
import 'services/auth_store.dart';
import 'services/ffi_api.dart';
import 'theme/app_theme.dart';
import 'widgets/api_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await AuthStore.create();
  final api = FfiApi(store);
  runApp(FfiApp(api: api));
}

class FfiApp extends StatelessWidget {
  const FfiApp({super.key, required this.api});
  final FfiApi api;

  @override
  Widget build(BuildContext context) {
    return ApiScope(
      api: api,
      // تم کل اپ از appThemeKey می‌آید و با انیمیشن نرم عوض می‌شود
      child: ValueListenableBuilder<String>(
        valueListenable: appThemeKey,
        builder: (context, key, _) => MaterialApp(
          title: 'فارکس فکتوری ایران',
          debugShowCheckedModeBanner: false,
          locale: const Locale('fa', 'IR'),
          supportedLocales: const [Locale('fa', 'IR'), Locale('en', 'US')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          ),
          theme: buildAppTheme(paletteOf(key)),
          themeAnimationDuration: const Duration(milliseconds: 300),
          themeAnimationCurve: Curves.easeInOut,
          home: const HomeScreen(),
        ),
      ),
    );
  }
}

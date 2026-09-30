import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/api_client.dart';
import 'core/auth_store.dart';
import 'core/cart_store.dart';
import 'core/locale_store.dart';
import 'core/profile_photo_store.dart';
import 'core/session.dart';
import 'screens/auth/login_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authStore = AuthStore();
  // Wire the Dio interceptor to this store (Bearer token + 401 handling).
  ApiClient.attachAuth(authStore);
  // Restore any persisted session before the first frame.
  await authStore.load();

  final localeStore = LocaleStore();
  await localeStore.load();

  runApp(WashlyApp(authStore: authStore, localeStore: localeStore));
}

class WashlyApp extends StatelessWidget {
  final AuthStore authStore;
  final LocaleStore localeStore;
  const WashlyApp({
    super.key,
    required this.authStore,
    required this.localeStore,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authStore),
        ChangeNotifierProvider.value(value: localeStore),
        ChangeNotifierProvider(create: (_) => CartStore()),
        ChangeNotifierProvider(create: (_) => ProfilePhotoStore()),
      ],
      child: Consumer<LocaleStore>(
        builder: (context, localeStore, _) => MaterialApp(
          title: 'Washly',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          navigatorKey: ApiClient.navigatorKey,
          locale: localeStore.locale,
          supportedLocales: const [Locale('en'), Locale('id')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routes: {
            '/login': (_) => const LoginScreen(),
          },
          // App-start routing: valid token -> role home; otherwise role select.
          home: Consumer<AuthStore>(
            builder: (context, auth, _) {
              if (!auth.isInitialized) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return homeForSession(auth);
            },
          ),
        ),
      ),
    );
  }
}

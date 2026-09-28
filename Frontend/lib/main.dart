import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/api_client.dart';
import 'core/auth_store.dart';
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

  runApp(WashlyApp(authStore: authStore));
}

class WashlyApp extends StatelessWidget {
  final AuthStore authStore;
  const WashlyApp({super.key, required this.authStore});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: authStore,
      child: MaterialApp(
        title: 'Washly',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        navigatorKey: ApiClient.navigatorKey,
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
    );
  }
}

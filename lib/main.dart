import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/constants/colors.dart';
import 'core/constants/config.dart';
import 'core/theme/theme.dart';
import 'core/widgets/main_layout.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'core/providers/security_provider.dart';
import 'core/services/notification_service.dart';
import 'features/auth/presentation/pin_setup_screen.dart';
import 'features/auth/presentation/pin_entry_screen.dart';
import 'core/services/error_logger_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set style status bar & navigation bar global
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0x0C000000), // Transparansi gelap tipis (5%) agar terpisah dari background putih
      statusBarIconBrightness: Brightness.dark, // Ikon/teks status bar berwarna gelap agar terbaca jelas
      statusBarBrightness: Brightness.light, // iOS (Light content background -> Dark status bar text)
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Inisialisasi Logger Global
  await ErrorLoggerService().initialize();

  // Inisialisasi lokalisasi penanggalan Indonesia (id_ID)
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi Supabase secara aman (tidak crash jika key belum diganti)
  try {
    if (AppConfig.supabaseUrl.startsWith('http')) {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );

      // Inisialisasi notifikasi lokal & FCM
      await NotificationService().initialize(Supabase.instance.client);
    }
  } catch (e) {
    debugPrint('Supabase Initialization failed: $e');
  }

  // Inisialisasi Firebase & FCM (opsional jika setup android/iOS belum dilakukan)
  try {
    // await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase Initialization failed: $e');
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'McdWallet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, // Mengaktifkan tema Off-White & Charcoal Premium
      home: authState.when(
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
        error: (err, _) => Scaffold(
          body: Center(
            child: Text(
              'Terjadi kesalahan koneksi sistem:\n$err',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ),
        data: (user) {
          if (user != null) {
            // Cek status keamanan lokal (PIN & Biometric)
            final securityState = ref.watch(securityProvider);
            
            if (!securityState.hasPin) {
              // Wajib setel PIN jika belum ada
              return const PinSetupScreen();
            } else if (securityState.isLocked) {
              // Layar Lock Screen jika terkunci
              return const PinEntryScreen();
            } else {
              // Layar Utama jika sukses terbuka
              return const MainLayout();
            }
          } else {
            // Belum login -> Tampilkan Layar Login
            return const LoginScreen();
          }
        },
      ),
    );
  }
}

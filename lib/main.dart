import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/constants/app_colors.dart';
import 'features/auth/presentation/screens/registration_screen.dart';
import 'features/auth/presentation/screens/otp_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/complete_profile_screen.dart';
import 'features/home/presentation/screens/main_navigation.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/notifications/presentation/screens/notifications_screen.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: CareerSetuApp()));
}

class CareerSetuApp extends StatelessWidget {
  const CareerSetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Career Setu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.backgroundLight,
        primaryColor: AppColors.primaryBrand,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.white,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: AppColors.primaryText),
          titleTextStyle: TextStyle(
            color: AppColors.primaryBrand,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.primaryText),
          displayMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primaryText),
          displaySmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primaryText),
          bodyLarge: TextStyle(fontSize: 16, color: AppColors.primaryText),
          bodyMedium: TextStyle(fontSize: 14, color: AppColors.secondaryText),
          bodySmall: TextStyle(fontSize: 12, color: AppColors.secondaryText),
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryBrand),
        useMaterial3: false,
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/registration': (context) => const RegistrationScreen(),
        '/otp': (context) => const OtpScreen(),
        '/complete_profile': (context) => const CompleteProfileScreen(),
        '/main': (context) => const MainNavigation(),
        '/profile': (context) => const ProfileScreen(),
        '/notifications': (context) => const NotificationsScreen(),
      },
    );
  }
}

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authProvider.notifier).initCheck());
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (!authState.isInitialCheckDone) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authState.currentUser != null) {
      if (authState.currentUser!.city.isEmpty || authState.currentUser!.goal.isEmpty) {
        return const CompleteProfileScreen();
      }
      return const MainNavigation();
    }

    return const LoginScreen();
  }
}

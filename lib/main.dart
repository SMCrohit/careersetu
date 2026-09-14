import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_colors.dart';
import 'features/auth/presentation/screens/registration_screen.dart';
import 'features/auth/presentation/screens/otp_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/home/presentation/screens/main_navigation.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/notifications/presentation/screens/notifications_screen.dart';
void main() {
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
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/registration': (context) => const RegistrationScreen(),
        '/otp': (context) => const OtpScreen(),
        '/main': (context) => const MainNavigation(),
        '/profile': (context) => const ProfileScreen(),
        '/notifications': (context) => const NotificationsScreen(),
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../appointments/presentation/screens/appointments_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: AppColors.primaryText)),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryText),
      ),
      body: user == null
          ? const Center(child: Text('No user data found.'))
            : Column(
                children: [
                  // Top Section (Default Background)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.white, width: 4),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
                            ],
                            image: const DecorationImage(
                              image: NetworkImage('https://i.pravatar.cc/300'), // Modern mock avatar
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.fullName,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryText),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              user.email,
                              style: const TextStyle(fontSize: 14, color: AppColors.secondaryText),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.edit_outlined, size: 16, color: AppColors.primaryBrand),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Bottom Section (Solid White Background)
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(0, 24, 0, 24 + MediaQuery.of(context).padding.bottom),
                          child: Column(
                            children: [
                              _buildListTile(context, 'Mobile Number', user.mobileNumber, Icons.phone),
                              _buildDivider(),
                              _buildListTile(context, 'City', user.city, Icons.location_city),
                              _buildDivider(),
                              _buildListTile(context, 'Career Goal', user.goal.toUpperCase(), Icons.flag),
                              _buildDivider(),
                              _buildListTile(context, 'My Resume', 'View or edit your resume', Icons.description_outlined, onTap: () {}),
                              _buildDivider(),
                              _buildListTile(context, 'My Appointments', 'View booked doctors', Icons.calendar_today_outlined, onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const AppointmentsScreen()));
                              }),
                              _buildDivider(),
                              _buildListTile(context, 'Saved Jobs', 'View jobs you saved', Icons.bookmark_border, onTap: () {}),
                              _buildDivider(),
                              _buildListTile(context, 'Settings', 'App preferences and account', Icons.settings_outlined, onTap: () {}),
                              _buildDivider(),
                              
                              // Log Out Option
                              InkWell(
                                onTap: () {
                                  ref.read(authProvider.notifier).logout();
                                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  child: Row(
                                    children: [
                                      Icon(Icons.logout, color: AppColors.error, size: 28),
                                      SizedBox(width: 16),
                                      Text('Log Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.error)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildListTile(BuildContext context, String title, String subtitle, IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryBrand, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.primaryText)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.secondaryText),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: AppColors.backgroundLight,
      indent: 68, // Aligns divider with text, skips icon
    );
  }
}

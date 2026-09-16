import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/navigation_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../doctors/presentation/screens/doctor_listings_screen.dart';
import '../../../doctors/presentation/screens/doctor_details_screen.dart';
import '../../../doctors/domain/doctor_model.dart';
import '../../../jobs/presentation/screens/applied_jobs_screen.dart';
import '../../../appointments/presentation/screens/appointments_screen.dart';
import '../../../tests/presentation/screens/my_tests_screen.dart';
import '../../../offers/presentation/screens/offers_hub_screen.dart';
import '../../../doctors/presentation/providers/doctors_provider.dart';
import '../providers/banners_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final Color bgColor = const Color(0xFFF0EBE1);

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.inAppBrowserView)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).currentUser;
    final name = user?.fullName.split(' ').first ?? 'Guest';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/profile'),
            child: const CircleAvatar(
              backgroundColor: AppColors.white,
              child: Icon(Icons.person, color: AppColors.primaryText),
            ),
          ),
        ),
        title: Text(
          'Hi, $name',
          style: const TextStyle(color: AppColors.primaryText, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppColors.primaryText),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Auto-scrolling Carousel Banner
            Consumer(
              builder: (context, ref, _) {
                final bannersState = ref.watch(bannersProvider);
                return bannersState.when(
                  data: (banners) {
                    if (banners.isEmpty) return const SizedBox();
                    return CarouselSlider(
                      options: CarouselOptions(
                        height: 180.0,
                        autoPlay: true,
                        autoPlayInterval: const Duration(seconds: 4),
                        enlargeCenterPage: true,
                        viewportFraction: 0.95,
                      ),
                      items: banners.map((banner) {
                        return Builder(
                          builder: (BuildContext context) {
                            return GestureDetector(
                              onTap: () => _launchUrl(banner.linkUrl),
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                margin: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 8.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey[300], // Fallback color
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    banner.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
                  error: (e, st) => const SizedBox(),
                );
              },
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome back, $name!', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                  const SizedBox(height: 8),
                  const Text('Here are your tools to advance your local career.', style: TextStyle(fontSize: 14, color: AppColors.secondaryText)),
                  const SizedBox(height: 24),
                  
                  // 2x2 Grid for Quick Actions
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.55,
                    children: [
                      _buildGridCustomCard(context, 'My Jobs', Icons.work_history_outlined, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AppliedJobsScreen()));
                      }),
                      _buildGridCustomCard(context, 'Doctor Appointments', Icons.calendar_today_outlined, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AppointmentsScreen()));
                      }),
                      _buildGridCustomCard(context, 'Local Offers', Icons.local_offer_outlined, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const OffersHubScreen()));
                      }),
                      _buildGridCustomCard(context, 'My Test', Icons.fact_check_outlined, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MyTestsScreen()));
                      }),
                    ],
                  ),
                ],
              ),
            ),
            
            // Health & Wellness Section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Health & Wellness', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const _DoctorListingsScreenWrapper()),
                              );
                            },
                            child: const Text('See All', style: TextStyle(color: AppColors.primaryBrand, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('Book certified therapists and doctors.', style: TextStyle(fontSize: 14, color: AppColors.secondaryText)),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180,
                      child: Consumer(
                        builder: (context, ref, _) {
                          final doctorsState = ref.watch(doctorsProvider);
                          
                          return doctorsState.when(
                            data: (doctors) {
                              if (doctors.isEmpty) {
                                return const Center(child: Text('No doctors available.'));
                              }
                              
                              final displayDoctors = doctors.take(4).toList();
                              
                              return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                itemCount: displayDoctors.length,
                                itemBuilder: (context, index) {
                                  final doctor = displayDoctors[index];
                                  final dummyImg = 'https://randomuser.me/api/portraits/${index % 2 == 0 ? 'women' : 'men'}/${index + 10}.jpg';
                                  final img = doctor.imageUrl != 'https://via.placeholder.com/150' ? doctor.imageUrl : dummyImg;
                                  
                                  return Container(
                                    width: 140,
                                    margin: const EdgeInsets.symmetric(horizontal: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppColors.border),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircleAvatar(radius: 28, backgroundImage: NetworkImage(img)),
                                        const SizedBox(height: 8),
                                        Text(doctor.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        Text(doctor.specialty, style: const TextStyle(color: AppColors.secondaryText, fontSize: 11), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          height: 30,
                                          width: double.infinity,
                                          child: OutlinedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (context) => DoctorDetailsScreen(doctor: doctor)),
                                              );
                                            },
                                            style: OutlinedButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              side: const BorderSide(color: AppColors.primaryBrand),
                                            ),
                                            child: const Text('View Details', style: TextStyle(fontSize: 12)),
                                          ),
                                        )
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (err, stack) => Center(child: Text('Error loading doctors')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridActionCard(BuildContext context, String title, IconData icon, int targetTab) {
    return GestureDetector(
      onTap: () {
        ref.read(navigationIndexProvider.notifier).setIndex(targetTab);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F8FF), // Light blue background for icon
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primaryBrand, size: 24),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCustomCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F8FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primaryBrand, size: 24),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryText),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorListingsScreenWrapper extends StatelessWidget {
  const _DoctorListingsScreenWrapper();

  @override
  Widget build(BuildContext context) {
    return const DoctorListingsScreen();
  }
}


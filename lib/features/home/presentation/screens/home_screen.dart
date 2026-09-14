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

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final Color bgColor = const Color(0xFFF0EBE1);

  final List<Map<String, dynamic>> banners = [
    {
      'title': 'MBA Admissions Open',
      'subtitle': 'Symbiosis University, Pune.',
      'highlight': 'Flat 20% Scholarship.',
      'url': 'https://symbiosis.edu.in',
      'imageUrl': 'https://picsum.photos/seed/mba/200/200',
      'gradient': const LinearGradient(colors: [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)]),
    },
    {
      'title': 'Learn AI Development',
      'subtitle': 'Google Cloud Certificate.',
      'highlight': 'Start your free trial today.',
      'url': 'https://cloud.google.com/training',
      'imageUrl': 'https://picsum.photos/seed/tech/200/200',
      'gradient': const LinearGradient(colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)]),
    },
    {
      'title': 'Find Your Dream Job',
      'subtitle': 'Top tech companies are hiring.',
      'highlight': 'Upload your resume now.',
      'url': 'https://linkedin.com',
      'imageUrl': 'https://picsum.photos/seed/job/200/200',
      'gradient': const LinearGradient(colors: [Color(0xFF4776E6), Color(0xFF8E54E9)]),
    },
  ];

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
            CarouselSlider(
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
                      onTap: () => _launchUrl(banner['url']!),
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          gradient: banner['gradient'],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: NetworkImage(banner['imageUrl']), 
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      banner['title']!,
                                      style: const TextStyle(
                                        color: Colors.white, // White title for all gradients
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      banner['subtitle']!,
                                      style: const TextStyle(color: AppColors.white, fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      banner['highlight']!,
                                      style: const TextStyle(
                                        color: Color(0xFFFFD54F), // Yellow highlight
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                              child: ElevatedButton(
                                onPressed: () => _launchUrl(banner['url']!),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primaryBrand,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  elevation: 0,
                                ),
                                child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
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
                          // Note: In a real app we would have a featuredDoctorsProvider. We just use doctorsProvider here.
                          // It is imported dynamically or we can just mock it for the horizontal list to avoid cyclic imports or big changes.
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            itemCount: 4,
                            itemBuilder: (context, index) {
                              final dummyNames = ['Dr. Aarti Sharma', 'Dr. Rohan Patil', 'Dr. Sneha Verma', 'Dr. Arjun Kapoor'];
                              final dummySpecs = ['Clinical Psychologist', 'Physiotherapist', 'General Physician', 'Career Counselor'];
                              final dummyImg = 'https://randomuser.me/api/portraits/${index % 2 == 0 ? 'women' : 'men'}/${index + 10}.jpg';
                              
                              final dummyDoctor = Doctor(
                                id: 'mock_home_$index',
                                name: dummyNames[index],
                                specialty: dummySpecs[index],
                                clinic: 'City Health Center',
                                experienceYears: 5 + index * 3,
                                rating: 4.5 + (index * 0.1),
                                reviews: 100 + index * 40,
                                consultationFee: 500 + index * 100,
                                imageUrl: dummyImg,
                              );

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
                                    CircleAvatar(radius: 28, backgroundImage: NetworkImage(dummyImg)),
                                    const SizedBox(height: 8),
                                    Text(dummyNames[index], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text(dummySpecs[index], style: const TextStyle(color: AppColors.secondaryText, fontSize: 11), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 30,
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => DoctorDetailsScreen(doctor: dummyDoctor)),
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


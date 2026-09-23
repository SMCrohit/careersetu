import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/navigation_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../professionals/domain/professional_model.dart';
import '../../../professionals/presentation/screens/professional_details_screen.dart';
import '../../../professionals/presentation/screens/professional_listings_screen.dart';
import '../../../professionals/presentation/widgets/reviews_bottom_sheet.dart';
import '../../../jobs/presentation/screens/applied_jobs_screen.dart';
import '../../../appointments/presentation/screens/appointments_screen.dart';
import '../../../tests/presentation/screens/my_tests_screen.dart';
import '../../../offers/presentation/screens/offers_hub_screen.dart';
import '../../../professionals/presentation/providers/professionals_provider.dart';
import '../providers/banners_provider.dart';
import 'dart:convert';

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
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white,
              ),
              child: ClipOval(
                child: _buildUserAvatar(user?.profileImageUrl),
              ),
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
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.refresh(bannersProvider.future);
          await ref.refresh(professionalsProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
                                  child: _buildBannerImage(banner.imageUrl),
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
                  
                  // 4 Quick Actions in 1 Row
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.8,
                    children: [
                      _buildGridSmallCard(context, 'My\nJobs', Icons.work_history_outlined, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AppliedJobsScreen()));
                      }),
                      _buildGridSmallCard(context, 'My\nAppts', Icons.calendar_today_outlined, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AppointmentsScreen()));
                      }),
                      _buildGridSmallCard(context, 'Local\nOffers', Icons.local_offer_outlined, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const OffersHubScreen()));
                      }),
                      _buildGridSmallCard(context, 'My\nTest', Icons.fact_check_outlined, () {
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
                                MaterialPageRoute(builder: (context) => const _ProfessionalListingsScreenWrapper(filterProfession: 'Doctor')),
                              );
                            },
                            child: const Text('See All', style: TextStyle(color: AppColors.primaryBrand, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('Book certified therapists and professionals.', style: TextStyle(fontSize: 14, color: AppColors.secondaryText)),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: Consumer(
                        builder: (context, ref, _) {
                          final professionalsState = ref.watch(professionalsProvider);
                          
                          return professionalsState.when(
                            data: (professionals) {
                              final docs = professionals.where((p) => p.profession == 'Doctor').toList();
                              if (docs.isEmpty) {
                                return const Center(child: Text('No doctors available.'));
                              }
                              
                              final displayProfessionals = docs.take(4).toList();
                              
                              return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                itemCount: displayProfessionals.length,
                                itemBuilder: (context, index) {
                                  final professional = displayProfessionals[index];
                                  final dummyImg = 'https://randomuser.me/api/portraits/${index % 2 == 0 ? 'women' : 'men'}/${index + 10}.jpg';
                                  final img = (professional.imageUrl != null && professional.imageUrl != 'https://via.placeholder.com/150') ? professional.imageUrl : dummyImg;
                                  
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
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.backgroundLight,
                                          ),
                                          child: ClipOval(
                                            child: _buildProfessionalImage(img),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(professional.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        Text(professional.specialty, style: const TextStyle(color: AppColors.secondaryText, fontSize: 11), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        GestureDetector(
                                          onTap: () {
                                            showModalBottomSheet(
                                              context: context,
                                              isScrollControlled: true,
                                              backgroundColor: Colors.transparent,
                                              builder: (ctx) => ReviewsBottomSheet(professional: professional),
                                            );
                                          },
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                              const SizedBox(width: 2),
                                              Text(
                                                professional.rating > professional.defaultRating ? professional.rating.toStringAsFixed(1) : professional.defaultRating.toStringAsFixed(1),
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryText),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        SizedBox(
                                          height: 30,
                                          width: double.infinity,
                                          child: OutlinedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (context) => ProfessionalDetailsScreen(professional: professional)),
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
                            error: (err, stack) => Center(child: Text('Error loading professionals')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Professionals Section
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
                          const Text('Professionals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const _ProfessionalListingsScreenWrapper(filterProfession: 'Professional')),
                              );
                            },
                            child: const Text('See All', style: TextStyle(color: AppColors.primaryBrand, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('Book CAs, Lawyers, Developers, etc.', style: TextStyle(fontSize: 14, color: AppColors.secondaryText)),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180,
                      child: Consumer(
                        builder: (context, ref, _) {
                          final professionalsState = ref.watch(professionalsProvider);
                          
                          return professionalsState.when(
                            data: (professionals) {
                              final pros = professionals.where((p) => p.profession != 'Doctor').toList();
                              if (pros.isEmpty) {
                                return const Center(child: Text('No professionals available.'));
                              }
                              
                              final displayProfessionals = pros.take(4).toList();
                              
                              return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                itemCount: displayProfessionals.length,
                                itemBuilder: (context, index) {
                                  final professional = displayProfessionals[index];
                                  final dummyImg = 'https://randomuser.me/api/portraits/${index % 2 == 0 ? "women" : "men"}/${index + 10}.jpg';
                                  final img = (professional.imageUrl != null && professional.imageUrl != 'https://via.placeholder.com/150') ? professional.imageUrl : dummyImg;
                                  
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
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.backgroundLight,
                                          ),
                                          child: ClipOval(
                                            child: _buildProfessionalImage(img),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(professional.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        Text(professional.specialty, style: const TextStyle(color: AppColors.secondaryText, fontSize: 11), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          height: 30,
                                          width: double.infinity,
                                          child: OutlinedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (context) => ProfessionalDetailsScreen(professional: professional)),
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
                            error: (err, stack) => Center(child: Text('Error loading professionals')),
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

  Widget _buildGridSmallCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF6366F1), size: 24),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF111827), height: 1.1),
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

  Widget _buildProfessionalImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const Icon(Icons.local_hospital, size: 28, color: AppColors.secondaryText);
    }
    if (imageUrl.startsWith('data:image')) {
      try {
        String base64Str = imageUrl.split(',').last.replaceAll(RegExp(r'\s+'), '');
        int padding = base64Str.length % 4;
        if (padding != 0) base64Str += '=' * (4 - padding);
        return Image.memory(base64Decode(base64Str), fit: BoxFit.cover, width: 56, height: 56);
      } catch (e) {
        return const Icon(Icons.local_hospital, size: 28, color: AppColors.secondaryText);
      }
    } else {
      return Image.network(imageUrl, fit: BoxFit.cover, width: 56, height: 56,
          errorBuilder: (_, __, ___) => const Icon(Icons.local_hospital, size: 28, color: AppColors.secondaryText));
    }
  }

  Widget _buildUserAvatar(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const Icon(Icons.person, color: AppColors.primaryText);
    }
    if (imageUrl.startsWith('data:image')) {
      try {
        String base64Str = imageUrl.split(',').last.replaceAll(RegExp(r'\s+'), '');
        int padding = base64Str.length % 4;
        if (padding != 0) base64Str += '=' * (4 - padding);
        return Image.memory(base64Decode(base64Str), fit: BoxFit.cover, width: 40, height: 40);
      } catch (e) {
        return const Icon(Icons.person, color: AppColors.primaryText);
      }
    } else {
      return Image.network(imageUrl, fit: BoxFit.cover, width: 40, height: 40,
          errorBuilder: (_, __, ___) => const Icon(Icons.person, color: AppColors.primaryText));
    }
  }

  Widget _buildBannerImage(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      try {
        String base64Str = imageUrl.split(',').last.replaceAll(RegExp(r'\s+'), '');
        int padding = base64Str.length % 4;
        if (padding != 0) base64Str += '=' * (4 - padding);
        return Image.memory(
          base64Decode(base64Str),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 40)),
        );
      } catch (e) {
        return const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 40));
      }
    } else {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 40)),
      );
    }
  }
}

class _ProfessionalListingsScreenWrapper extends StatelessWidget {
  final String? filterProfession;
  const _ProfessionalListingsScreenWrapper({this.filterProfession});

  @override
  Widget build(BuildContext context) {
    return ProfessionalListingsScreen(filterProfession: filterProfession);
  }
}


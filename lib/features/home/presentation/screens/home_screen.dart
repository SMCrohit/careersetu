import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_showcase.dart';
import '../../../appointments/presentation/screens/appointments_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../jobs/presentation/screens/applied_jobs_screen.dart';
import '../../../offers/presentation/screens/offers_hub_screen.dart';
import '../../../professionals/presentation/providers/professionals_provider.dart';
import '../../../professionals/presentation/screens/professional_details_screen.dart';
import '../../../professionals/presentation/screens/professional_listings_screen.dart';
import '../../../tests/presentation/screens/my_tests_screen.dart';
import '../providers/banners_provider.dart';
import '../providers/navigation_provider.dart';
import 'showcase_keys.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final Color bgColor = const Color(0xFFF0EBE1);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenShowcase = prefs.getBool('has_seen_showcase') ?? false;
      if (!hasSeenShowcase && mounted) {
        ShowCaseWidget.of(context).startShowCase([
          ShowcaseKeys.profile,
          ShowcaseKeys.notifications,
          ShowcaseKeys.jobs,
          ShowcaseKeys.appointments,
          ShowcaseKeys.tests,
          ShowcaseKeys.bookProfessional,
          ShowcaseKeys.localOffers,
          ShowcaseKeys.tabJobs,
          ShowcaseKeys.tabTests,
          ShowcaseKeys.tabResume,
          ShowcaseKeys.tabGames,
        ]);
        prefs.setBool('has_seen_showcase', true);
      }
    });
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.inAppBrowserView)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open link')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).currentUser;
    final name = user?.fullName.split(' ').first ?? 'Guest';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE3F1FF), // Slate 100 F1F5F9
            Color(0xFFFFFFFF), // White
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomShowcase(
              showcaseKey: ShowcaseKeys.profile,
              description: 'Tap here to complete\nor edit your profile.',
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile'),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: ClipOval(
                          child: _buildUserAvatar(user?.profileImageUrl),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          title: Text(
            'Hi, $name',
            style: const TextStyle(
              color: AppColors.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            CustomShowcase(
              showcaseKey: ShowcaseKeys.notifications,
              description: 'Check here for important\nalerts and updates.',
              child: IconButton(
                icon: const Icon(
                  Icons.notifications_none,
                  color: AppColors.primaryText,
                ),
                onPressed: () => Navigator.pushNamed(context, '/notifications'),
              ),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await ref.refresh(bannersProvider.future);
            await ref.refresh(professionalsProvider.future);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Completion Bar
                if (user != null && user.profileCompletionScore < 100)
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/profile'),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        color: AppColors.primaryBrand.withOpacity(0.9),
                        child: Row(
                          children: [
                            Text(
                              'Profile ${user.profileCompletionScore}% complete.',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: const [
                                Text(
                                  'Tap to finish',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

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
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 5.0,
                                      vertical: 8.0,
                                    ),
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
                      loading: () => const SizedBox(
                        height: 180,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, st) => const SizedBox(),
                    );
                  },
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 4 Quick Actions in 1 Row
                      GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.8,
                        children: [
                          CustomShowcase(
                            showcaseKey: ShowcaseKeys.jobs,
                            description:
                                'Track your applied jobs and see their status.',
                            child: _buildGridSmallCard(
                              context,
                              'My\nJobs',
                              Icons.work_history_outlined,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AppliedJobsScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          CustomShowcase(
                            showcaseKey: ShowcaseKeys.appointments,
                            description:
                                'Manage your upcoming consultations here.',
                            child: _buildGridSmallCard(
                              context,
                              'My\nAppts',
                              Icons.calendar_today_outlined,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AppointmentsScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          CustomShowcase(
                            showcaseKey: ShowcaseKeys.localOffers,
                            description:
                                'Find exclusive local offers and discounts here.',
                            child: _buildGridSmallCard(
                              context,
                              'Local\nOffers',
                              Icons.local_offer_outlined,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const OffersHubScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          CustomShowcase(
                            showcaseKey: ShowcaseKeys.tests,
                            description:
                                'Review the results of tests you have taken.',
                            child: _buildGridSmallCard(
                              context,
                              'My\nTest',
                              Icons.fact_check_outlined,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const MyTestsScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
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
                    decoration: const BoxDecoration(color: Colors.transparent),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Health & Wellness',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const _ProfessionalListingsScreenWrapper(
                                            filterProfession: 'Doctor',
                                          ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'See All',
                                  style: TextStyle(
                                    color: AppColors.primaryBrand,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Book certified therapists and professionals.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 230,
                          child: Consumer(
                            builder: (context, ref, _) {
                              final professionalsState = ref.watch(
                                professionalsProvider,
                              );

                              return professionalsState.when(
                                data: (professionals) {
                                  final docs = professionals
                                      .where((p) => p.profession == 'Doctor')
                                      .toList();
                                  if (docs.isEmpty) {
                                    return const Center(
                                      child: Text('No doctors available.'),
                                    );
                                  }

                                  final displayProfessionals = docs
                                      .take(4)
                                      .toList();

                                  return ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    itemCount: displayProfessionals.length,
                                    itemBuilder: (context, index) {
                                      final professional =
                                          displayProfessionals[index];
                                      final dummyImg =
                                          'https://randomuser.me/api/portraits/${index % 2 == 0 ? 'women' : 'men'}/${index + 10}.jpg';
                                      final img =
                                          (professional.imageUrl != null &&
                                              professional.imageUrl !=
                                                  'https://via.placeholder.com/150')
                                          ? professional.imageUrl
                                          : dummyImg;

                                      return _buildModernProfessionalCard(
                                        context,
                                        professional,
                                        index,
                                      );
                                    },
                                  );
                                },
                                loading: () => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                error: (err, stack) => Center(
                                  child: Text('Error loading professionals'),
                                ),
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
                    decoration: const BoxDecoration(color: Colors.transparent),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Professionals',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const _ProfessionalListingsScreenWrapper(
                                            filterProfession: 'Professional',
                                          ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'See All',
                                  style: TextStyle(
                                    color: AppColors.primaryBrand,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // CustomShowcase(
                        //   showcaseKey: ShowcaseKeys.bookProfessional,
                        //   description:
                        //       'Tap on a professional below to view their profile, check their reviews, and book an appointment.',
                        //   child: const Padding(
                        //     padding: EdgeInsets.symmetric(horizontal: 16.0),
                        //     child: Text(
                        //       'Book CAs, Lawyers, Developers, etc.',
                        //       style: TextStyle(
                        //         fontSize: 14,
                        //         color: AppColors.secondaryText,
                        //       ),
                        //     ),
                        //   ),
                        // ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 230,
                          child: Consumer(
                            builder: (context, ref, _) {
                              final professionalsState = ref.watch(
                                professionalsProvider,
                              );

                              return professionalsState.when(
                                data: (professionals) {
                                  final pros = professionals
                                      .where((p) => p.profession != 'Doctor')
                                      .toList();
                                  if (pros.isEmpty) {
                                    return const Center(
                                      child: Text(
                                        'No professionals available.',
                                      ),
                                    );
                                  }

                                  final displayProfessionals = pros
                                      .take(4)
                                      .toList();

                                  return ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    itemCount: displayProfessionals.length,
                                    itemBuilder: (context, index) {
                                      final professional =
                                          displayProfessionals[index];
                                      final dummyImg =
                                          'https://randomuser.me/api/portraits/${index % 2 == 0 ? "women" : "men"}/${index + 10}.jpg';
                                      final img =
                                          (professional.imageUrl != null &&
                                              professional.imageUrl !=
                                                  'https://via.placeholder.com/150')
                                          ? professional.imageUrl
                                          : dummyImg;

                                      return _buildModernProfessionalCard(
                                        context,
                                        professional,
                                        index,
                                      );
                                    },
                                  );
                                },
                                loading: () => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                error: (err, stack) => Center(
                                  child: Text('Error loading professionals'),
                                ),
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
      ),
    );
  }

  Widget _buildGridActionCard(
    BuildContext context,
    String title,
    IconData icon,
    int targetTab,
  ) {
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
                color: const Color(0xFFF3F8FF),
                // Light blue background for icon
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primaryBrand, size: 24),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridSmallCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF06b6d4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCustomCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
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
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const Icon(
        Icons.person_rounded,
        size: 32,
        color: Color(0xFF0ea5e9),
      );
    }
    if (imageUrl.startsWith('data:image')) {
      try {
        String base64Str = imageUrl
            .split(',')
            .last
            .replaceAll(RegExp(r'\s+'), '');
        int padding = base64Str.length % 4;
        if (padding != 0) base64Str += '=' * (4 - padding);
        return Image.memory(
          base64Decode(base64Str),
          fit: BoxFit.cover,
          width: 56,
          height: 56,
        );
      } catch (e) {
        return const Icon(
          Icons.person_rounded,
          size: 32,
          color: Color(0xFF0ea5e9),
        );
      }
    } else {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: 56,
        height: 56,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.person_rounded,
          size: 32,
          color: Color(0xFF0ea5e9),
        ),
      );
    }
  }

  Widget _buildUserAvatar(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const Icon(Icons.person, color: AppColors.primaryText);
    }
    if (imageUrl.startsWith('data:image')) {
      try {
        String base64Str = imageUrl
            .split(',')
            .last
            .replaceAll(RegExp(r'\s+'), '');
        int padding = base64Str.length % 4;
        if (padding != 0) base64Str += '=' * (4 - padding);
        return Image.memory(
          base64Decode(base64Str),
          fit: BoxFit.cover,
          width: 40,
          height: 40,
        );
      } catch (e) {
        return const Icon(Icons.person, color: AppColors.primaryText);
      }
    } else {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: 40,
        height: 40,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.person, color: AppColors.primaryText),
      );
    }
  }

  Widget _buildBannerImage(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      try {
        String base64Str = imageUrl
            .split(',')
            .last
            .replaceAll(RegExp(r'\s+'), '');
        int padding = base64Str.length % 4;
        if (padding != 0) base64Str += '=' * (4 - padding);
        return Image.memory(
          base64Decode(base64Str),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
          ),
        );
      } catch (e) {
        return const Center(
          child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
        );
      }
    } else {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
        ),
      );
    }
  }

  Widget _buildProfessionalCoverImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Image.asset(
        'assets/images/placeholder.png',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    if (imageUrl.startsWith('data:image')) {
      try {
        String base64Str = imageUrl
            .split(',')
            .last
            .replaceAll(RegExp(r'\s+'), '');
        int padding = base64Str.length % 4;
        if (padding != 0) base64Str += '=' * (4 - padding);
        return Image.memory(
          base64Decode(base64Str),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      } catch (e) {
        return Image.asset(
          'assets/images/placeholder.png',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      }
    } else {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/images/placeholder.png',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }
  }

  Widget _buildModernProfessionalCard(
    BuildContext context,
    dynamic professional,
    int index,
  ) {
    final dummyImg =
        'https://randomuser.me/api/portraits/${index % 2 == 0 ? 'women' : 'men'}/${index + 10}.jpg';
    final img =
        (professional.imageUrl != null &&
            professional.imageUrl != 'https://via.placeholder.com/150')
        ? professional.imageUrl
        : dummyImg;

    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ProfessionalDetailsScreen(professional: professional),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 45,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: _buildProfessionalCoverImage(img),
                ),
              ),
              Expanded(
                flex: 55,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Text(
                            professional.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Color(0xFF0F172A),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            professional.specialty,
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 14,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            professional.rating > professional.defaultRating
                                ? professional.rating.toStringAsFixed(1)
                                : professional.defaultRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0ea5e9).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'View Details',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0ea5e9),
                          ),
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
}

class _ProfessionalListingsScreenWrapper extends StatelessWidget {
  final String? filterProfession;

  const _ProfessionalListingsScreenWrapper({this.filterProfession});

  @override
  Widget build(BuildContext context) {
    return ProfessionalListingsScreen(filterProfession: filterProfession);
  }
}

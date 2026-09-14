import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ResumePreviewScreen extends ConsumerWidget {
  const ResumePreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).currentUser;
    
    // Fallbacks if user is somehow null
    final name = user?.fullName ?? 'YOUR NAME';
    final email = user?.email ?? 'your.email@example.com';
    final phone = user?.mobileNumber ?? '+91 9876543210';
    final city = user?.city ?? 'Bengaluru';
    final goal = user?.goal ?? 'Software Developer';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Resume Preview', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.primaryText),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                  borderRadius: BorderRadius.circular(8),
                ),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HEADER ---
                    Text(name.toUpperCase(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primaryText, letterSpacing: 1.5)),
                    const SizedBox(height: 6),
                    Text('$email • $phone • $city', style: const TextStyle(fontSize: 13, color: AppColors.secondaryText)),
                    
                    const SizedBox(height: 24),
                    
                    // --- PROFILE SUMMARY ---
                    _buildSectionHeader('SUMMARY'),
                    Text(
                      'Dedicated and results-driven professional seeking opportunities as a $goal. Proven track record of delivering high-quality solutions, adapting quickly to new environments, and collaborating effectively in cross-functional teams to exceed organizational objectives.',
                      style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.primaryText),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // --- EXPERIENCE ---
                    _buildSectionHeader('EXPERIENCE'),
                    _buildExperienceBlock(
                      title: goal,
                      company: 'Tech Solutions Corp',
                      date: '2021 - Present',
                      bullets: [
                        'Spearheaded the development of a flagship mobile application, resulting in a 40% increase in user retention.',
                        'Optimized database queries and backend architecture, reducing API latency by over 30%.',
                        'Mentored junior team members and established best practices for code reviews.',
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildExperienceBlock(
                      title: 'Junior $goal',
                      company: 'StartUp Innovate Inc',
                      date: '2019 - 2021',
                      bullets: [
                        'Assisted in the migration of legacy monolithic systems to a microservices architecture.',
                        'Collaborated with the QA team to increase test coverage from 45% to 85%.',
                        'Resolved critical production bugs, achieving a 99.9% uptime SLA.',
                      ],
                    ),

                    const SizedBox(height: 24),
                    
                    // --- EDUCATION ---
                    _buildSectionHeader('EDUCATION'),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('B.Tech in Computer Science', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        Text('2015 - 2019', style: TextStyle(color: AppColors.secondaryText, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('National Institute of Technology', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 14, color: AppColors.primaryText)),

                    const SizedBox(height: 24),
                    
                    // --- SKILLS ---
                    _buildSectionHeader('SKILLS'),
                    const Text(
                      'Technical: Flutter, Dart, React, Node.js, Python, Firebase, PostgreSQL, Docker, AWS\n'
                      'Soft Skills: Leadership, Agile Methodologies, Problem Solving, Public Speaking',
                      style: TextStyle(height: 1.6, color: AppColors.primaryText, fontSize: 14),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // --- PROJECTS ---
                    _buildSectionHeader('PROJECTS'),
                    const Text('CareerSetu Platform', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 4),
                    _buildBullet('Built a scalable career preparation application from scratch.'),
                    _buildBullet('Implemented complex state management and responsive UI components.'),
                  ],
                ),
              ),
            ),
          ),
          
          // --- BOTTOM ACTIONS ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    text: 'Edit Details',
                    onPressed: () {
                      CustomToast.showSuccess(context, 'Edit mode enabled.');
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PrimaryButton(
                    text: 'Download PDF',
                    onPressed: () {
                      CustomToast.showSuccess(context, 'Resume downloaded successfully!');
                    },
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryBrand, letterSpacing: 1.2)),
        const SizedBox(height: 4),
        const Divider(color: AppColors.border, thickness: 1),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildExperienceBlock({required String title, required String company, required String date, required List<String> bullets}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
            Text(date, style: const TextStyle(color: AppColors.secondaryText, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 4),
        Text(company, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 14, color: AppColors.primaryText)),
        const SizedBox(height: 8),
        ...bullets.map((b) => _buildBullet(b)),
      ],
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6.0, right: 8.0),
            child: Icon(Icons.circle, size: 6, color: AppColors.secondaryText),
          ),
          Expanded(child: Text(text, style: const TextStyle(color: AppColors.primaryText, fontSize: 14, height: 1.5))),
        ],
      ),
    );
  }
}

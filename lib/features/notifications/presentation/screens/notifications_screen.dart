import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Notifications list
    final List<Map<String, dynamic>> notifications = [
      {
        'title': 'New Job Alert',
        'subtitle': 'A new role for "Sales Manager" matches your profile.',
        'time': '2h',
        'isRead': false,
        'icon': Icons.work,
      },
      {
        'title': 'Resume Viewed',
        'subtitle': 'Your resume was viewed by 3 local recruiters today.',
        'time': '5h',
        'isRead': false,
        'icon': Icons.visibility,
      },
      {
        'title': 'Mock Test Score',
        'subtitle': 'You scored 85% in the recent Aptitude test. Great job!',
        'time': '1d',
        'isRead': true,
        'icon': Icons.assignment_turned_in,
      },
      {
        'title': 'Profile Complete',
        'subtitle': 'Thanks for adding your career goal. Your profile is now 100% complete.',
        'time': '2d',
        'isRead': true,
        'icon': Icons.person_add_alt_1,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: AppColors.primaryText)),
        backgroundColor: AppColors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.primaryText),
      ),
      body: ListView.separated(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          final bool isRead = notification['isRead'];

          return Container(
            color: isRead ? AppColors.white : const Color(0xFFE8F3FF), // LinkedIn style unread highlight
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: isRead ? AppColors.backgroundLight : AppColors.primaryBrand,
                  radius: 24,
                  child: Icon(
                    notification['icon'],
                    color: isRead ? AppColors.secondaryText : AppColors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notification['title'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                color: AppColors.primaryText,
                              ),
                            ),
                          ),
                          Text(
                            notification['time'],
                            style: TextStyle(fontSize: 12, color: isRead ? AppColors.secondaryText : AppColors.primaryBrand),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification['subtitle'],
                        style: TextStyle(
                          fontSize: 14,
                          color: isRead ? AppColors.secondaryText : AppColors.primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

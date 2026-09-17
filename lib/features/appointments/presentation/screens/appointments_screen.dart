import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/appointments_provider.dart';
import '../../domain/appointment_model.dart';
import 'package:careersetu/features/professionals/presentation/screens/professional_details_screen.dart';
import 'dart:convert';

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(appointmentsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: AppColors.primaryText),
          title: const Text('My Appointments', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            labelColor: AppColors.primaryBrand,
            unselectedLabelColor: AppColors.secondaryText,
            indicatorColor: AppColors.primaryBrand,
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
            ],
          ),
        ),
        body: appointmentsAsync.when(
          data: (appointments) {
            final upcoming = appointments.where((a) => ['upcoming', 'pending', 'sent_to_professional'].contains(a.status)).toList();
            final past = appointments.where((a) => ['completed', 'cancelled'].contains(a.status)).toList();
            return TabBarView(
              children: [
                _buildAppointmentList(context, ref, upcoming, 'No upcoming appointments.'),
                _buildAppointmentList(context, ref, past, 'No past appointments.'),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Failed to load appointments')),
        ),
      ),
    );
  }

  Widget _buildAppointmentList(BuildContext context, WidgetRef ref, List<Appointment> appointments, String emptyMessage) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.refresh(appointmentsProvider.future);
      },
      child: appointments.isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              child: Container(
                height: MediaQuery.of(context).size.height - kToolbarHeight - 100,
                alignment: Alignment.center,
                child: Text(emptyMessage, style: const TextStyle(color: AppColors.secondaryText, fontSize: 16)),
              ),
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.all(16),
              itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appt = appointments[index];
        final doc = appt.professional;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfessionalDetailsScreen(professional: doc)),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${appt.date} at ${appt.time}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBrand)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: appt.status == 'pending' ? Colors.orange.withOpacity(0.1) : (['upcoming', 'sent_to_professional'].contains(appt.status) ? AppColors.primaryBrand.withOpacity(0.1) : AppColors.success.withOpacity(0.1)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          appt.status == 'pending' ? 'PENDING APPROVAL' : (appt.status == 'sent_to_professional' ? 'CONFIRMED' : appt.status.toUpperCase()),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: appt.status == 'pending' ? Colors.orange : (['upcoming', 'sent_to_professional'].contains(appt.status) ? AppColors.primaryBrand : AppColors.success),
                          ),
                        ),
                      )
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.backgroundLight,
                        ),
                        child: ClipOval(
                          child: _buildProfessionalImage(doc.imageUrl),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(doc.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryText)),
                            const SizedBox(height: 4),
                            Text(doc.specialty, style: const TextStyle(color: AppColors.secondaryText, fontSize: 13)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.secondaryText),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

  Widget _buildProfessionalImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const Icon(Icons.local_hospital, size: 24, color: AppColors.secondaryText);
    }
    if (imageUrl.startsWith('data:image')) {
      try {
        String base64Str = imageUrl.split(',').last.replaceAll(RegExp(r'\s+'), '');
        int padding = base64Str.length % 4;
        if (padding != 0) base64Str += '=' * (4 - padding);
        return Image.memory(base64Decode(base64Str), fit: BoxFit.cover, width: 48, height: 48);
      } catch (e) {
        return const Icon(Icons.local_hospital, size: 24, color: AppColors.secondaryText);
      }
    } else {
      return Image.network(imageUrl, fit: BoxFit.cover, width: 48, height: 48,
          errorBuilder: (_, __, ___) => const Icon(Icons.local_hospital, size: 24, color: AppColors.secondaryText));
    }
  }
}

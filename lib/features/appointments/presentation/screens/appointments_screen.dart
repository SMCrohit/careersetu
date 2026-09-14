import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/appointments_provider.dart';
import '../../domain/appointment_model.dart';
import '../../../doctors/presentation/screens/doctor_details_screen.dart';

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointments = ref.watch(appointmentsProvider);

    final upcoming = appointments.where((a) => a.status == 'upcoming').toList();
    final past = appointments.where((a) => a.status == 'completed').toList();

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
        body: TabBarView(
          children: [
            _buildAppointmentList(context, upcoming, 'No upcoming appointments.'),
            _buildAppointmentList(context, past, 'No past appointments.'),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentList(BuildContext context, List<Appointment> appointments, String emptyMessage) {
    if (appointments.isEmpty) {
      return Center(
        child: Text(emptyMessage, style: const TextStyle(color: AppColors.secondaryText, fontSize: 16)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appt = appointments[index];
        final doc = appt.doctor;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DoctorDetailsScreen(doctor: doc)),
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
                          color: appt.status == 'upcoming' ? AppColors.primaryBrand.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          appt.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: appt.status == 'upcoming' ? AppColors.primaryBrand : AppColors.success,
                          ),
                        ),
                      )
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(doc.imageUrl),
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
    );
  }
}

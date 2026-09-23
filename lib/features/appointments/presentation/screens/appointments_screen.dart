import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../professionals/data/professionals_repository.dart';
import '../../../professionals/domain/professional_model.dart';
import '../../../professionals/presentation/screens/professional_details_screen.dart';
import '../providers/appointments_provider.dart';
import '../../domain/appointment_model.dart';

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
            final upcoming = appointments.where((a) {
              if (_isAppointmentInPast(a)) return false;
              return ['upcoming', 'pending', 'sent_to_doctor'].contains(a.status);
            }).toList();
            
            final past = appointments.where((a) {
              if (_isAppointmentInPast(a)) return true;
              return ['completed', 'cancelled'].contains(a.status);
            }).toList();
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
        final isPast = _isAppointmentInPast(appt) || ['completed', 'cancelled'].contains(appt.status);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfessionalDetailsScreen(
                  professional: doc,
                  bookingContext: ['upcoming', 'pending', 'sent_to_doctor'].contains(appt.status) ? 'upcoming' : 'past',
                )),
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
                          color: _getStatusColor(appt.status, isPast).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getStatusText(appt.status, isPast),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(appt.status, isPast),
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
                  ),
                  if (isPast && _getStatusText(appt.status, isPast) == 'ATTENDED') ...[
                    const Divider(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _showWriteReviewBottomSheet(context, ref, doc),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryBrand,
                          side: const BorderSide(color: AppColors.primaryBrand),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Write a Review', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

  void _showWriteReviewBottomSheet(BuildContext context, WidgetRef ref, Professional professional) {
    double rating = 5.0;
    String comment = '';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Write a Review', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('How was your appointment with ${professional.name}?', style: const TextStyle(color: AppColors.secondaryText)),
                  const SizedBox(height: 16),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: Colors.amber,
                            size: 40,
                          ),
                          onPressed: () => setState(() => rating = index + 1.0),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Add a comment (optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    maxLines: 3,
                    onChanged: (val) => comment = val,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBrand,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        try {
                          final repo = ref.read(professionalsRepositoryProvider);
                          await repo.submitReview(professional.id, rating, comment);
                          Navigator.pop(context);
                          CustomToast.showSuccess(context, 'Review submitted successfully');
                        } catch (e) {
                          CustomToast.showError(context, 'Failed to submit review');
                        }
                      },
                      child: const Text('Submit Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      },
    );
  }

  bool _isAppointmentInPast(Appointment appt) {
    try {
      DateTime apptDate;
      if (appt.date == 'Today') {
        apptDate = DateTime.now();
      } else if (appt.date == 'Tomorrow') {
        apptDate = DateTime.now().add(const Duration(days: 1));
      } else {
        apptDate = DateFormat('MMM d, yyyy').parse(appt.date);
      }

      final timeFormat = DateFormat('h:mm a');
      final parsedTime = timeFormat.parse(appt.time);
      
      final finalDateTime = DateTime(
        apptDate.year,
        apptDate.month,
        apptDate.day,
        parsedTime.hour,
        parsedTime.minute,
      );

      return finalDateTime.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  String _getStatusText(String status, bool isPast) {
    if (isPast) {
      if (status == 'completed') return 'ATTENDED';
      if (status == 'cancelled') return 'CANCELLED';
      if (status == 'sent_to_doctor' || status == 'upcoming') return 'MISSED';
      if (status == 'pending') return 'EXPIRED';
      return status.toUpperCase();
    } else {
      if (status == 'pending') return 'PENDING APPROVAL';
      if (status == 'sent_to_doctor') return 'CONFIRMED';
      return status.toUpperCase();
    }
  }

  Color _getStatusColor(String status, bool isPast) {
    if (isPast) {
      if (status == 'completed') return AppColors.success;
      if (status == 'cancelled') return AppColors.secondaryText;
      if (status == 'sent_to_doctor' || status == 'upcoming') return AppColors.error;
      if (status == 'pending') return Colors.orange;
      return AppColors.secondaryText;
    } else {
      if (status == 'pending') return Colors.orange;
      if (status == 'sent_to_doctor' || status == 'upcoming') return AppColors.primaryBrand;
      return AppColors.primaryBrand;
    }
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

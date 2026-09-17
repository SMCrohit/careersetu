import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../domain/professional_model.dart';
import '../../../appointments/presentation/providers/appointments_provider.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class ProfessionalDetailsScreen extends ConsumerStatefulWidget {
  final Professional professional;
  const ProfessionalDetailsScreen({super.key, required this.professional});

  @override
  ConsumerState<ProfessionalDetailsScreen> createState() => _ProfessionalDetailsScreenState();
}

class _ProfessionalDetailsScreenState extends ConsumerState<ProfessionalDetailsScreen> {
  String? selectedTime;
  late DateTime selectedDate;
  late List<DateTime> availableDates;
  final List<String> timeSlots = ['10:00 AM', '11:30 AM', '02:00 PM', '04:30 PM', '06:00 PM'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedDate = DateTime(now.year, now.month, now.day);
    availableDates = List.generate(30, (index) => DateTime(now.year, now.month, now.day).add(Duration(days: index)));
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.professional;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.primaryText),
        title: Text(doc.profession == 'Doctor' ? 'Doctor Profile' : '${doc.profession} Profile', style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header and Stats
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.backgroundLight,
                          ),
                          child: ClipOval(
                            child: _buildProfessionalImage(doc.imageUrl),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(doc.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                        const SizedBox(height: 4),
                        Text(doc.specialty, style: const TextStyle(fontSize: 16, color: AppColors.primaryBrand, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Text(doc.clinic, style: const TextStyle(fontSize: 14, color: AppColors.secondaryText)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn('Experience', '${doc.experienceYears} Years'),
                      _buildStatColumn('Rating', '${doc.rating} ★'),
                      _buildStatColumn('Reviews', '${doc.reviews}'),
                    ],
                  ),
                ],
              ),
            ),
            
            Container(height: 8, color: AppColors.backgroundLight),
            
            // About
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('About Professional', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                  const SizedBox(height: 12),
                  Text(
                    '${doc.name} is a highly experienced ${doc.specialty} at ${doc.clinic}. They specialize in providing holistic care and have a proven track record of successful treatments. Their approach combines modern medical practices with compassionate patient care.',
                    style: const TextStyle(fontSize: 14, color: AppColors.secondaryText, height: 1.5),
                  ),
                ],
              ),
            ),
            
            Container(height: 8, color: AppColors.backgroundLight),

            // Select Date
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Date', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 75,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: availableDates.length,
                      itemBuilder: (context, index) {
                        final date = availableDates[index];
                        final isSelected = date.isAtSameMomentAs(selectedDate);
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedDate = date;
                              selectedTime = null; // Reset time slot for new date
                            });
                          },
                          child: Container(
                            width: 65,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryBrand : AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isSelected ? AppColors.primaryBrand : Colors.transparent),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('E').format(date),
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : AppColors.secondaryText,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  date.day.toString(),
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : AppColors.primaryText,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            Container(height: 8, color: AppColors.backgroundLight),

            // Select Time Slot
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Time for ${selectedDate.isAtSameMomentAs(availableDates.first) ? 'Today' : DateFormat('MMM d').format(selectedDate)}', 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText)
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: timeSlots.map((time) {
                      final isSelected = time == selectedTime;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedTime = time;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryBrand : AppColors.white,
                            border: Border.all(color: AppColors.primaryBrand),
                            borderRadius: BorderRadius.circular(20), // Chips are usually rounded
                          ),
                          child: Text(
                            time,
                            style: TextStyle(
                              color: isSelected ? AppColors.white : AppColors.primaryBrand,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Consultation Fee', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                  Text('₹${doc.consultationFee}', style: const TextStyle(color: AppColors.primaryText, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: PrimaryButton(
                  text: 'Book Appointment',
                  onPressed: selectedTime == null
                      ? () {
                          CustomToast.showError(context, 'Please select a time slot first');
                        }
                      : () {
                          // Book appointment
                          final bookingDate = selectedDate.isAtSameMomentAs(availableDates.first) 
                              ? 'Today' 
                              : DateFormat('MMM d, yyyy').format(selectedDate);
                          ref.read(appointmentsProvider.notifier).bookAppointment(doc, bookingDate, selectedTime!);
                          CustomToast.showSuccess(context, 'Appointment booked successfully!');
                          Navigator.pop(context); // Go back to directory
                        },
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 13)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: AppColors.primaryText, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildProfessionalImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const Icon(Icons.local_hospital, size: 50, color: AppColors.secondaryText);
    }
    if (imageUrl.startsWith('data:image')) {
      final base64String = imageUrl.split(',').last;
      return Image.memory(base64Decode(base64String), fit: BoxFit.cover, width: 100, height: 100);
    } else {
      return Image.network(imageUrl, fit: BoxFit.cover, width: 100, height: 100,
          errorBuilder: (_, __, ___) => const Icon(Icons.local_hospital, size: 50, color: AppColors.secondaryText));
    }
  }
}

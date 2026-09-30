import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../domain/professional_model.dart';
import '../../data/professionals_repository.dart';
import '../../../appointments/presentation/providers/appointments_provider.dart';
import '../widgets/reviews_bottom_sheet.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class ProfessionalDetailsScreen extends ConsumerStatefulWidget {
  final Professional professional;
  final String? bookingContext;
  const ProfessionalDetailsScreen({super.key, required this.professional, this.bookingContext});

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

  bool _isTimeSlotPassed(String timeStr) {
    final now = DateTime.now();
    final isToday = selectedDate.year == now.year && selectedDate.month == now.month && selectedDate.day == now.day;
    if (!isToday) return false;

    try {
      final format = DateFormat('hh:mm a');
      final time = format.parse(timeStr);
      final slotTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, time.hour, time.minute);
      return slotTime.isBefore(now);
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.professional;

    final String? ctx = widget.bookingContext;
    final bool isUpcoming = ctx == 'CONFIRMED' || ctx == 'PENDING APPROVAL' || ctx == 'upcoming';
    final bool isPast = ctx == 'ATTENDED' || ctx == 'MISSED' || ctx == 'CANCELLED' || ctx == 'EXPIRED' || ctx == 'past';

    Widget bottomBarContent;

    if (isUpcoming) {
      bottomBarContent = Row(
        children: [
          Expanded(
            child: PrimaryButton(
              text: 'Already booked',
              backgroundColor: Colors.grey.shade400,
              onPressed: null,
            ),
          ),
        ],
      );
    } else if (isPast) {
      bottomBarContent = Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Status', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
              Text(ctx ?? 'PAST', style: const TextStyle(color: AppColors.primaryText, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
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
      );
    } else {
      bottomBarContent = Row(
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
      );
    }

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
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (ctx) => ReviewsBottomSheet(professional: doc),
                          );
                        },
                        child: _buildStatColumn(
                          'Rating', 
                          '${doc.rating > doc.defaultRating ? doc.rating.toStringAsFixed(1) : doc.defaultRating.toStringAsFixed(1)} ★'
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (ctx) => ReviewsBottomSheet(professional: doc),
                          );
                        },
                        child: _buildStatColumn('Reviews', '${doc.reviews}'),
                      ),
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
                    doc.description != null && doc.description!.isNotEmpty 
                        ? doc.description! 
                        : 'No description provided.',
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
                      final isPassed = _isTimeSlotPassed(time);
                      return GestureDetector(
                        onTap: isPassed ? null : () {
                          setState(() {
                            selectedTime = time;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isPassed ? AppColors.backgroundLight : isSelected ? AppColors.primaryBrand : AppColors.white,
                            border: Border.all(color: isPassed ? AppColors.border : isSelected ? AppColors.primaryBrand : AppColors.borderDark),
                            borderRadius: BorderRadius.circular(20), // Chips are usually rounded
                          ),
                          child: Text(
                            time,
                            style: TextStyle(
                              color: isPassed ? AppColors.secondaryText.withOpacity(0.5) : isSelected ? AppColors.white : AppColors.primaryBrand,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              decoration: isPassed ? TextDecoration.lineThrough : null,
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
            child: bottomBarContent,
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

  String _getRatingText(double r) {
    if (r == 1.0) return 'Not good';
    if (r == 2.0) return 'Fair';
    if (r == 3.0) return 'Good';
    if (r == 4.0) return 'Very good';
    if (r == 5.0) return 'Best';
    return '';
  }

  void _showWriteReviewBottomSheet(BuildContext context, WidgetRef ref, Professional professional) {
    double rating = 0.0;
    String comment = '';
    bool isLoading = true;
    bool hasFetched = false;
    bool hasExistingReview = false;
    TextEditingController commentController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            
            if (!hasFetched) {
              hasFetched = true;
              ref.read(professionalsRepositoryProvider).getMyReview(professional.id).then((review) {
                if (mounted) {
                  setState(() {
                    if (review != null) {
                      rating = review.rating;
                      comment = review.comment ?? '';
                      commentController.text = comment;
                      hasExistingReview = true;
                    }
                    isLoading = false;
                  });
                }
              }).catchError((_) {
                if (mounted) setState(() { isLoading = false; });
              });
            }

            if (isLoading) {
              return Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    SizedBox(height: 150),
                    Center(child: CircularProgressIndicator()),
                    SizedBox(height: 150),
                  ],
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(hasExistingReview ? 'Update Review' : 'Write a Review', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
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
                  if (rating > 0)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(_getRatingText(rating), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBrand, fontSize: 16)),
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment',
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
                        if (rating == 0.0) {
                          CustomToast.showError(context, 'Please provide a star rating');
                          return;
                        }
                        if (comment.trim().isEmpty) {
                          CustomToast.showError(context, 'Please write a review comment');
                          return;
                        }
                        
                        try {
                          final repo = ref.read(professionalsRepositoryProvider);
                          await repo.submitReview(professional.id, rating, comment);
                          Navigator.pop(context);
                          CustomToast.showSuccess(context, hasExistingReview ? 'Review updated successfully' : 'Review submitted successfully');
                        } catch (e) {
                          CustomToast.showError(context, 'Failed to submit review');
                        }
                      },
                      child: Text(hasExistingReview ? 'Update Review' : 'Submit Review', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
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
}

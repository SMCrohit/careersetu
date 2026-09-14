import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/doctors_provider.dart';
import 'doctor_details_screen.dart';

class DoctorListingsScreen extends ConsumerStatefulWidget {
  const DoctorListingsScreen({super.key});

  @override
  ConsumerState<DoctorListingsScreen> createState() => _DoctorListingsScreenState();
}

class _DoctorListingsScreenState extends ConsumerState<DoctorListingsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        ref.read(doctorsProvider.notifier).fetchMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctorsState = ref.watch(doctorsProvider);
    final notifier = ref.read(doctorsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.primaryText),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search doctors, specialties...',
                  border: InputBorder.none,
                ),
                onChanged: (val) => ref.read(doctorSearchQueryProvider.notifier).updateQuery(val),
              )
            : const Text('Doctor Directory', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: AppColors.primaryText),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  ref.read(doctorSearchQueryProvider.notifier).updateQuery('');
                } else {
                  _isSearching = true;
                }
              });
            },
          )
        ],
      ),
      body: doctorsState.when(
        data: (doctors) {
          if (doctors.isEmpty) {
            return const Center(child: Text('No doctors found.', style: TextStyle(color: AppColors.secondaryText)));
          }
          return RefreshIndicator(
            onRefresh: () async {
              await notifier.refresh();
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
              itemCount: doctors.length + (notifier.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == doctors.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primaryBrand)),
                  );
                }
                
                final doc = doctors[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  color: AppColors.white,
                  elevation: 2,
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundImage: NetworkImage(doc.imageUrl),
                                onBackgroundImageError: (_, __) => const Icon(Icons.person),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(doc.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryText)),
                                    const SizedBox(height: 4),
                                    Text(doc.specialty, style: const TextStyle(color: AppColors.primaryBrand, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 4),
                                    Text(doc.clinic, style: const TextStyle(color: AppColors.secondaryText, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildInfoItem(Icons.work_history, '${doc.experienceYears} Years'),
                              _buildInfoItem(Icons.star, '${doc.rating} (${doc.reviews})'),
                              _buildInfoItem(Icons.currency_rupee, '${doc.consultationFee}'),
                            ],
                          ),
                          // Removed Book button since card is clickable
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryBrand)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.error))),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.secondaryText),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: AppColors.secondaryText, fontSize: 13)),
      ],
    );
  }
}

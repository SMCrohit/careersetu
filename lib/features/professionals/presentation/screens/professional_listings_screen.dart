import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import 'dart:convert';
import '../providers/professionals_provider.dart';
import 'professional_details_screen.dart';

class ProfessionalListingsScreen extends ConsumerStatefulWidget {
  final String? filterProfession;
  const ProfessionalListingsScreen({super.key, this.filterProfession});

  @override
  ConsumerState<ProfessionalListingsScreen> createState() => _ProfessionalListingsScreenState();
}

class _ProfessionalListingsScreenState extends ConsumerState<ProfessionalListingsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        ref.read(professionalsProvider.notifier).fetchMore();
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
    final professionalsState = ref.watch(professionalsProvider);
    final notifier = ref.read(professionalsProvider.notifier);

    String title = 'Professional Directory';
    if (widget.filterProfession == 'Doctor') title = 'Doctors Directory';
    else if (widget.filterProfession == 'Professional') title = 'Professionals Directory';

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
                  hintText: 'Search professionals, specialties...',
                  border: InputBorder.none,
                ),
                onChanged: (val) => ref.read(professionalSearchQueryProvider.notifier).updateQuery(val),
              )
            : Text(title, style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: AppColors.primaryText),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  ref.read(professionalSearchQueryProvider.notifier).updateQuery('');
                } else {
                  _isSearching = true;
                }
              });
            },
          )
        ],
      ),
      body: professionalsState.when(
        data: (allProfessionals) {
          var professionals = allProfessionals;
          if (widget.filterProfession == 'Doctor') {
            professionals = professionals.where((p) => p.profession == 'Doctor').toList();
          } else if (widget.filterProfession == 'Professional') {
            professionals = professionals.where((p) => p.profession != 'Doctor').toList();
          }
          if (professionals.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                await notifier.refresh();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                child: Container(
                  height: MediaQuery.of(context).size.height - kToolbarHeight - 100,
                  alignment: Alignment.center,
                  child: const Text('No professionals found.', style: TextStyle(color: AppColors.secondaryText)),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              await notifier.refresh();
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
              itemCount: professionals.length + (notifier.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == professionals.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primaryBrand)),
                  );
                }
                
                final doc = professionals[index];
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
                        MaterialPageRoute(builder: (context) => ProfessionalDetailsScreen(professional: doc)),
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
                              Container(
                                width: 60,
                                height: 60,
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

  Widget _buildProfessionalImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const Icon(Icons.local_hospital, size: 30, color: AppColors.secondaryText);
    }
    if (imageUrl.startsWith('data:image')) {
      final base64String = imageUrl.split(',').last;
      return Image.memory(base64Decode(base64String), fit: BoxFit.cover, width: 60, height: 60);
    } else {
      return Image.network(imageUrl, fit: BoxFit.cover, width: 60, height: 60,
          errorBuilder: (_, __, ___) => const Icon(Icons.local_hospital, size: 30, color: AppColors.secondaryText));
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../../domain/test_model.dart';
import '../providers/tests_provider.dart';
import 'active_test_screen.dart';

class MockTestDetailsScreen extends ConsumerWidget {
  final int initialTabIndex;
  
  const MockTestDetailsScreen({super.key, this.initialTabIndex = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return DefaultTabController(
      length: 2,
      initialIndex: initialTabIndex,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          title: const Text('Mock Tests', style: TextStyle(color: AppColors.primaryBrand, fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: AppColors.primaryBrand),
          bottom: const TabBar(
            labelColor: AppColors.primaryBrand,
            unselectedLabelColor: AppColors.secondaryText,
            indicatorColor: AppColors.primaryBrand,
            tabs: [
              Tab(text: 'Available Tests'),
              Tab(text: 'My Attempts'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const _AvailableTestsList(),
            const _AttemptedTestsList(),
          ],
        ),
      ),
    );
  }
}

class _AvailableTestsList extends ConsumerStatefulWidget {
  const _AvailableTestsList();
  @override
  ConsumerState<_AvailableTestsList> createState() => _AvailableTestsListState();
}

class _AvailableTestsListState extends ConsumerState<_AvailableTestsList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(availableTestsProvider.notifier).fetchNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(availableTestsProvider);

    if (state.items.isEmpty && state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (state.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(availableTestsProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: const Center(child: Text("You've taken all available tests!")),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () => ref.read(availableTestsProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        itemCount: state.items.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final test = state.items[index];
          return _TestCard(test: test, isCompleted: false);
        },
      ),
    );
  }
}

class _AttemptedTestsList extends ConsumerStatefulWidget {
  const _AttemptedTestsList();
  @override
  ConsumerState<_AttemptedTestsList> createState() => _AttemptedTestsListState();
}

class _AttemptedTestsListState extends ConsumerState<_AttemptedTestsList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(attemptedTestsProvider.notifier).fetchNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(attemptedTestsProvider);
    final completedTestsAsync = ref.watch(completedTestsProvider);

    if (state.items.isEmpty && state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (state.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(attemptedTestsProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: const Center(child: Text("You haven't taken any tests yet.")),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () => ref.read(attemptedTestsProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        itemCount: state.items.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final test = state.items[index];
          final score = completedTestsAsync.value?[test.id];
          return _TestCard(test: test, isCompleted: true, score: score);
        },
      ),
    );
  }
}

class _TestCard extends ConsumerWidget {
  final TestModel test;
  final bool isCompleted;
  final int? score;

  const _TestCard({
    required this.test,
    required this.isCompleted,
    this.score,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine the discount unlocked if completed
    int discountUnlocked = 0;
    if (isCompleted && score != null) {
      double percentage = score! / test.questions.length;
      if (percentage >= 0.8) {
        discountUnlocked = test.maxDiscountPercentage;
      } else if (percentage >= 0.5) {
        discountUnlocked = (test.maxDiscountPercentage / 2).floor();
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (test.createdDatetime != null && DateTime.now().difference(test.createdDatetime!).inDays <= 7 && !isCompleted)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'New',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      test.tag.isNotEmpty ? test.tag : 'Skill Assessment', 
                      style: const TextStyle(color: AppColors.primaryBrand, fontSize: 12, fontWeight: FontWeight.bold)
                    ),
                  ),
                ],
              ),
              if (test.maxDiscountPercentage > 0 && !isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Text(
                    'Up to ${test.maxDiscountPercentage}% OFF Class Fees',
                    style: TextStyle(color: Colors.orange.shade800, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(test.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
          const SizedBox(height: 4),
          Text('Provided by: ${test.providerName}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryBrand)),
          const SizedBox(height: 8),
          Text(test.description, style: const TextStyle(color: AppColors.secondaryText, fontSize: 14)),
          
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem(Icons.timer, '${test.durationMins} Mins'),
              _buildInfoItem(Icons.list_alt, '${test.questions.length} Questions'),
              _buildInfoItem(Icons.star, test.difficulty),
            ],
          ),
          
          if (isCompleted) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your Score', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                    Text('$score / ${test.questions.length}', style: const TextStyle(color: AppColors.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                if (discountUnlocked > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Discount Unlocked!', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
                      Text('$discountUnlocked% OFF', style: const TextStyle(color: AppColors.success, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                if (discountUnlocked == 0 && test.maxDiscountPercentage > 0)
                  const Text('Keep practicing to\nunlock discounts!', style: TextStyle(color: AppColors.secondaryText, fontSize: 12), textAlign: TextAlign.right),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Retaking this test is for practice only. No additional offers or discounts will be unlocked on retest.',
                      style: TextStyle(color: Colors.amber.shade900, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          PrimaryButton(
            text: isCompleted ? 'Retest (Practice Only)' : 'Start Test',
            onPressed: () {
              ref.read(activeTestProvider.notifier).loadTest(test.id);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ActiveTestScreen()));
            },
          )
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.secondaryText),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}

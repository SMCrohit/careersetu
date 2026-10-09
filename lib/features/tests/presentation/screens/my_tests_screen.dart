import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../home/presentation/providers/navigation_provider.dart';
import '../../data/tests_repository.dart';
import '../../domain/test_model.dart';
import '../providers/tests_provider.dart';
import '../widgets/attempt_card.dart';
import '../widgets/test_card.dart';
import 'active_test_screen.dart';
import 'test_results_screen.dart';

/// Tests the user has taken, with best scores, results and retakes.
class MyTestsScreen extends ConsumerStatefulWidget {
  const MyTestsScreen({super.key});

  @override
  ConsumerState<MyTestsScreen> createState() => _MyTestsScreenState();
}

class _MyTestsScreenState extends ConsumerState<MyTestsScreen> {
  final _scrollController = ScrollController();
  String? _openingId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
        ref.read(myTestsProvider.notifier).fetchNextPage();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _viewResult(TestSummary test) async {
    final attemptId = test.bestAttempt?.id;
    if (attemptId == null) return;
    setState(() => _openingId = test.id);
    try {
      final result = await ref.read(testsRepositoryProvider).fetchAttempt(attemptId);
      if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => TestResultsScreen(result: result)));
    } catch (e) {
      if (mounted) CustomToast.showError(context, e is ApiException ? e.message : 'Could not open the result.');
    } finally {
      if (mounted) setState(() => _openingId = null);
    }
  }

  void _browseTests() {
    // Tests is the third tab in the bottom navigation.
    ref.read(navigationIndexProvider.notifier).setIndex(2);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myTestsProvider);
    final notifier = ref.read(myTestsProvider.notifier);

    return Container(
      decoration: const BoxDecoration(gradient: AppUi.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.primaryText,
          title: const Text('My Tests', style: AppText.screenTitle),
        ),
        body: RefreshIndicator(
          color: AppUi.accent,
          onRefresh: notifier.refresh,
          child: Builder(builder: (context) {
            if (state.isLoading && state.items.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: List.generate(3, (_) => const TestCardSkeleton()),
              );
            }
            if (state.error != null && state.items.isEmpty) {
              return _message(Icons.cloud_off_rounded, "Couldn't load your tests", state.error!, 'Try again', notifier.refresh);
            }
            if (state.items.isEmpty) {
              return _message(Icons.assignment_outlined, 'No tests taken yet',
                  'Tests you take will show up here with your scores and AI summary.', 'Browse tests', _browseTests);
            }
            return ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 4, 16, 16 + MediaQuery.of(context).padding.bottom),
              itemCount: state.items.length + 1 + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == 0) return _summary(state.items, state.total);
                final i = index - 1;
                if (i == state.items.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator(color: AppUi.accent, strokeWidth: 2.5)),
                  );
                }
                final test = state.items[i];
                return Stack(
                  children: [
                    AttemptCard(
                      test: test,
                      onViewResult: () => _viewResult(test),
                      onRetake: test.canRetake ? () => startTestFlow(context, ref, test, isRetake: true) : null,
                    ),
                    if (_openingId == test.id)
                      const Positioned.fill(
                        child: Center(child: CircularProgressIndicator(color: AppUi.accent)),
                      ),
                  ],
                );
              },
            );
          }),
        ),
      ),
    );
  }

  Widget _summary(List<TestSummary> tests, int total) {
    final scored = tests.where((t) => t.bestAttempt != null).toList();
    final average = scored.isEmpty ? 0 : scored.map((t) => t.bestAttempt!.percentage).reduce((a, b) => a + b) / scored.length;
    final passed = scored.where((t) => t.bestAttempt!.isPassed == true).length;
    final stats = [('Tests taken', '$total'), ('Average', '${average.round()}%'), ('Passed', '$passed')];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: AppUi.heroGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            Expanded(
              child: Column(children: [
                Text(stats[i].$2, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(stats[i].$1, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
              ]),
            ),
            if (i < stats.length - 1) Container(width: 1, height: 32, color: Colors.white24),
          ],
        ],
      ),
    );
  }

  Widget _message(IconData icon, String title, String subtitle, String action, VoidCallback onAction) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(32, 80, 32, 24),
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(gradient: AppUi.accentGradient, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 36),
          ),
        ),
        const SizedBox(height: 18),
        Text(title, textAlign: TextAlign.center, style: AppText.screenTitle),
        const SizedBox(height: 6),
        Text(subtitle, textAlign: TextAlign.center, style: AppText.subtitle.copyWith(height: 1.4)),
        const SizedBox(height: 20),
        Center(child: PrimaryButton(text: action, width: 200, onPressed: onAction)),
      ],
    );
  }
}

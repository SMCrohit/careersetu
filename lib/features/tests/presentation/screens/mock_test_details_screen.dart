import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../providers/tests_provider.dart';
import '../widgets/test_card.dart';
import 'active_test_screen.dart';
import 'my_tests_screen.dart';

/// Tests tab: active tests the user can take now.
class MockTestDetailsScreen extends ConsumerStatefulWidget {
  const MockTestDetailsScreen({super.key});

  @override
  ConsumerState<MockTestDetailsScreen> createState() => _MockTestDetailsScreenState();
}

class _MockTestDetailsScreenState extends ConsumerState<MockTestDetailsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
        ref.read(activeTestsProvider.notifier).fetchNextPage();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openMyTests() => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyTestsScreen()));

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activeTestsProvider);
    final notifier = ref.read(activeTestsProvider.notifier);

    return Container(
      decoration: const BoxDecoration(gradient: AppUi.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 16,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tests', style: AppText.screenTitle),
              const SizedBox(height: 2),
              Text(
                state.isLoading && state.items.isEmpty ? 'Loading tests…' : '${state.total} active ${state.total == 1 ? 'test' : 'tests'}',
                style: AppText.label,
              ),
            ],
          ),
          actions: [
            Center(
              child: Tooltip(
                message: 'My tests',
                child: GestureDetector(
                  onTap: _openMyTests,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: AppUi.cardShadow),
                    child: const Icon(Icons.history_edu_outlined, size: 20, color: AppColors.primaryText),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: RefreshIndicator(
          color: AppUi.accent,
          onRefresh: notifier.refresh,
          child: _buildBody(state, notifier),
        ),
      ),
    );
  }

  Widget _buildBody(TestListState state, TestListNotifier notifier) {
    if (state.isLoading && state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: List.generate(3, (_) => const TestCardSkeleton()),
      );
    }
    if (state.error != null && state.items.isEmpty) {
      return _message(Icons.cloud_off_rounded, "Couldn't load tests", state.error!, 'Try again', notifier.refresh);
    }
    if (state.items.isEmpty) {
      return _message(
        Icons.emoji_events_outlined,
        "You're all caught up",
        "You've taken every active test. New tests appear here as soon as they're published.",
        'View my tests',
        _openMyTests,
      );
    }
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: state.items.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(color: AppUi.accent, strokeWidth: 2.5)),
          );
        }
        final test = state.items[index];
        return TestCard(test: test, onStart: () => startTestFlow(context, ref, test));
      },
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
        Center(child: SecondaryButton(text: action, width: 200, onPressed: onAction)),
      ],
    );
  }
}

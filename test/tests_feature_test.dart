import 'package:careersetu/core/api/api_client.dart';
import 'package:careersetu/features/tests/data/tests_repository.dart';
import 'package:careersetu/features/tests/domain/test_model.dart';
import 'package:careersetu/features/tests/presentation/providers/tests_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _startJson = {
  'id': 't1',
  'title': 'Aptitude Basics',
  'duration_mins': 10,
  'test_mode': 'per_question',
  'question_count': 2,
  'questions': [
    {
      'id': 'q1',
      'question_type': 'single_select',
      'question_text': 'Pick one',
      'options': [
        {'id': '1', 'text': 'A'},
        {'id': '2', 'text': 'B'},
      ],
      'marks': 1,
      'time_limit_seconds': 3,
      'topic': 'Algebra',
    },
    {
      'id': 'q2',
      'question_type': 'multi_select',
      'question_text': 'Pick many',
      'options': ['Old string option', 'Another'],
      'marks': 2,
      'time_limit_seconds': 0,
    },
  ],
};

/// Records what the exam notifier sends.
class FakeRepo extends TestsRepository {
  Map<String, dynamic>? submitted;
  bool failSubmit = false;

  FakeRepo() : super(ApiClient());

  @override
  Future<ActiveTest> startTest(String testId) async => ActiveTest.fromJson(_startJson);

  @override
  Future<AttemptResult> submitAttempt({required String testId, required int timeTakenSeconds, required List<Map<String, dynamic>> answers}) async {
    if (failSubmit) throw ApiException('Server down', statusCode: 500);
    submitted = {'test_id': testId, 'answers': answers};
    return AttemptResult.fromJson({'id': 'a1', 'test_id': testId, 'test_title': 'Aptitude Basics', 'percentage': 50});
  }

  @override
  Future<TestsPage> fetchTests({String status = 'available', int page = 1}) async => const TestsPage([], 0);
}

void main() {
  // ApiClient reads the base URL from .env; the fake repository never calls it.
  setUpAll(() => dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost/api'));

  group('parsing', () {
    test('questions accept {id, text} and old string options', () {
      final t = ActiveTest.fromJson(_startJson);
      expect(t.questions[0].options.map((o) => o.id), ['1', '2']);
      expect(t.questions[1].options.first.text, 'Old string option');
      expect(t.questions[1].isMulti, isTrue);
      expect(t.questions[1].timeLimitSeconds, 60, reason: 'zero time limit falls back to 60s');
      expect(t.info.isPerQuestion, isTrue);
    });

    test('new graded result with AI summary', () {
      final r = AttemptResult.fromJson({
        'id': 'a1',
        'test_id': 't1',
        'test_title': 'Aptitude',
        'total_score': 3.5,
        'max_score': 8,
        'percentage': 43.8,
        'is_passed': false,
        'pass_percentage': 50,
        'time_taken_seconds': 125,
        'correct': 3,
        'incorrect': 2,
        'skipped': 1,
        'ai_report': {
          'overall_insight': 'You did well in Algebra.',
          'strong_areas': [{'topic': 'Algebra', 'subtopic': 'general', 'accuracy': 100}],
          'weak_areas': [{'topic': 'Logic', 'subtopic': '', 'accuracy': 0}],
          'time_management': 'Good pace.',
          'next_steps': ['Practise logic'],
        },
        'question_responses': [
          {
            'question_id': 'q1',
            'question_text': 'Pick one',
            'options': [{'id': '1', 'text': 'A'}, {'id': '2', 'text': 'B'}],
            'selected_option_ids': ['2'],
            'correct_option_ids': ['1'],
            'is_attempted': true,
            'is_correct': false,
          },
        ],
      });
      expect(r.scoreLabel, '3.5 / 8');
      expect(r.accuracy, 60);
      expect(r.timeLabel, '2m 5s');
      expect(r.aiReport!.strongAreas.single.label, 'Algebra', reason: '"general" subtopic is hidden');
      expect(r.aiReport!.nextSteps, ['Practise logic']);
      expect(r.responses.single.isCorrect, isFalse);
    });

    test('old seeded attempt with text-only answers still parses', () {
      final r = AttemptResult.fromJson({
        'id': 'a0',
        'test_id': 't0',
        'total_score': 3.0,
        'max_score': 5.0,
        'percentage': 60.0,
        'ai_report': {'overall_insight': 'Ok', 'weak_areas': [], 'strong_areas': [], 'time_management': ''},
        'question_responses': [
          {'question_text': 'Q', 'selected_option': '1', 'correct_option': '1', 'is_correct': true, 'time_spent_seconds': 77},
        ],
      });
      expect(r.responses.single.isAttempted, isTrue);
      expect(r.responses.single.hasAnswerKey, isTrue);
      expect(r.aiReport!.overallInsight, 'Ok');
    });

    test('empty AI report is treated as missing', () {
      expect(AttemptResult.fromJson({'id': 'x', 'test_id': 't', 'ai_report': {}}).aiReport, isNull);
    });
  });

  group('exam', () {
    late FakeRepo repo;
    late ProviderContainer container;

    setUp(() {
      repo = FakeRepo();
      container = ProviderContainer(overrides: [testsRepositoryProvider.overrideWithValue(repo)]);
    });
    tearDown(() => container.dispose());

    test('single select replaces, multi select toggles, and submit sends option ids', () async {
      final exam = container.read(examProvider.notifier);
      await exam.start('t1');
      exam.toggleOption('1');
      exam.toggleOption('2');
      expect(container.read(examProvider).answers['q1'], {'2'});

      exam.next();
      final second = container.read(examProvider).question!;
      exam.toggleOption(second.options[0].id);
      exam.toggleOption(second.options[1].id);
      exam.toggleOption(second.options[0].id);
      expect(container.read(examProvider).answers['q2'], {second.options[1].id});

      await exam.submit();
      final answers = repo.submitted!['answers'] as List;
      expect(answers.map((a) => a['selected_option_ids']), [['2'], [second.options[1].id]]);
      expect(container.read(examProvider).result?.percentage, 50);
    });

    test('per-question mode uses the question timer and blocks going back', () async {
      final exam = container.read(examProvider.notifier);
      await exam.start('t1');
      expect(container.read(examProvider).timeLeft, 3);
      exam.next();
      expect(container.read(examProvider).timeLeft, 60);
      exam.previous();
      expect(container.read(examProvider).index, 1);
      exam.reset();
    });

    test('a failed submit keeps answers and shows the error', () async {
      repo.failSubmit = true;
      final exam = container.read(examProvider.notifier);
      await exam.start('t1');
      exam.toggleOption('1');
      await exam.submit();
      final state = container.read(examProvider);
      expect(state.error, 'Server down');
      expect(state.result, isNull);
      expect(state.answers['q1'], {'1'});
    });
  });
}

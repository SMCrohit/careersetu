import 'package:flutter/material.dart';

String _str(dynamic v) => v == null ? '' : v.toString().trim();
int _int(dynamic v, [int fallback = 0]) => v is num ? v.toInt() : int.tryParse(_str(v)) ?? fallback;
double _double(dynamic v, [double fallback = 0]) => v is num ? v.toDouble() : double.tryParse(_str(v)) ?? fallback;
DateTime? _date(dynamic v) => DateTime.tryParse(_str(v));
List<Map<String, dynamic>> _maps(dynamic v) =>
    v is List ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
List<String> _strings(dynamic v) => v is List ? v.map(_str).where((e) => e.isNotEmpty).toList() : [];

/// Best attempt shown on cards in My Tests.
class BestAttempt {
  final String id;
  final double totalScore;
  final double? maxScore;
  final double percentage;
  final bool? isPassed;
  final DateTime? completedAt;

  const BestAttempt({required this.id, this.totalScore = 0, this.maxScore, this.percentage = 0, this.isPassed, this.completedAt});

  factory BestAttempt.fromJson(Map<String, dynamic> j) => BestAttempt(
        id: _str(j['id']),
        totalScore: _double(j['total_score']),
        maxScore: j['max_score'] == null ? null : _double(j['max_score']),
        percentage: _double(j['percentage']),
        isPassed: j['is_passed'] as bool?,
        completedAt: _date(j['completed_at']),
      );
}

/// A test in a list (no questions).
class TestSummary {
  final String id;
  final String title;
  final String description;
  final String tag;
  final String category;
  final String difficulty;
  final String providerName;
  final int durationMins;

  /// 'overall' (one timer) or 'per_question' (a timer per question).
  final String testMode;
  final int questionCount;
  final double totalMarks;
  final int passPercentage;
  final bool negativeMarking;
  final int maxDiscountPercentage;
  final String instructions;
  final DateTime? createdDatetime;
  final DateTime? scheduledEndAt;
  final int attemptsUsed;

  /// null means unlimited.
  final int? attemptsLeft;
  final BestAttempt? bestAttempt;
  final DateTime? lastAttemptedAt;

  const TestSummary({
    required this.id,
    required this.title,
    this.description = '',
    this.tag = '',
    this.category = '',
    this.difficulty = 'Medium',
    this.providerName = '',
    this.durationMins = 0,
    this.testMode = 'overall',
    this.questionCount = 0,
    this.totalMarks = 0,
    this.passPercentage = 0,
    this.negativeMarking = false,
    this.maxDiscountPercentage = 0,
    this.instructions = '',
    this.createdDatetime,
    this.scheduledEndAt,
    this.attemptsUsed = 0,
    this.attemptsLeft,
    this.bestAttempt,
    this.lastAttemptedAt,
  });

  factory TestSummary.fromJson(Map<String, dynamic> j) => TestSummary(
        id: _str(j['id']),
        title: _str(j['title']).isNotEmpty ? _str(j['title']) : 'Untitled test',
        description: _str(j['description']),
        tag: _str(j['tag']),
        category: _str(j['category']),
        difficulty: _str(j['difficulty']).isNotEmpty ? _str(j['difficulty']) : 'Medium',
        providerName: _str(j['provider_name']),
        durationMins: _int(j['duration_mins']),
        testMode: _str(j['test_mode']).isNotEmpty ? _str(j['test_mode']) : 'overall',
        questionCount: _int(j['question_count']),
        totalMarks: _double(j['total_marks']),
        passPercentage: _int(j['pass_percentage']),
        negativeMarking: j['negative_marking'] == true,
        maxDiscountPercentage: _int(j['max_discount_percentage']),
        instructions: _str(j['instructions']),
        createdDatetime: _date(j['created_datetime']),
        scheduledEndAt: _date(j['scheduled_end_at']),
        attemptsUsed: _int(j['attempts_used']),
        attemptsLeft: j['attempts_left'] == null ? null : _int(j['attempts_left']),
        bestAttempt: j['best_attempt'] is Map ? BestAttempt.fromJson(Map<String, dynamic>.from(j['best_attempt'])) : null,
        lastAttemptedAt: _date(j['last_attempted_at']),
      );

  bool get isNew => createdDatetime != null && DateTime.now().difference(createdDatetime!).inDays <= 7;
  bool get isPerQuestion => testMode == 'per_question';
  bool get canRetake => attemptsLeft == null || attemptsLeft! > 0;

  String get durationLabel => isPerQuestion ? 'Timed per question' : '$durationMins min';

  /// "Ends in 3 days" for scheduled tests closing within two weeks.
  String? get endsLabel {
    if (scheduledEndAt == null) return null;
    final left = scheduledEndAt!.difference(DateTime.now());
    if (left.isNegative || left.inDays > 14) return null;
    if (left.inDays >= 1) return 'Ends in ${left.inDays} ${left.inDays == 1 ? 'day' : 'days'}';
    if (left.inHours >= 1) return 'Ends in ${left.inHours}h';
    return 'Ends soon';
  }

  Color get difficultyColor => switch (difficulty.toLowerCase()) {
        'easy' => const Color(0xFF059669),
        'hard' => const Color(0xFFDC2626),
        _ => const Color(0xFFD97706),
      };
}

class TestOption {
  final String id;
  final String text;

  const TestOption({required this.id, required this.text});

  /// Accepts `{id, text}` or an old plain-string option.
  factory TestOption.fromJson(dynamic j, int index) {
    if (j is Map) {
      final id = _str(j['id']);
      return TestOption(id: id.isNotEmpty ? id : '${index + 1}', text: _str(j['text']));
    }
    return TestOption(id: _str(j), text: _str(j));
  }
}

/// A question while taking the test (no answer included).
class TestQuestion {
  final String id;

  /// 'single_select', 'multi_select' or 'true_false'.
  final String type;
  final String text;
  final String imageUrl;
  final String note;
  final List<TestOption> options;
  final double marks;
  final double negativeMarks;
  final int timeLimitSeconds;
  final String section;
  final String topic;

  const TestQuestion({
    required this.id,
    required this.text,
    required this.options,
    this.type = 'single_select',
    this.imageUrl = '',
    this.note = '',
    this.marks = 1,
    this.negativeMarks = 0,
    this.timeLimitSeconds = 60,
    this.section = 'General',
    this.topic = 'General',
  });

  bool get isMulti => type == 'multi_select';

  factory TestQuestion.fromJson(Map<String, dynamic> j) {
    final rawOptions = j['options'] is List ? j['options'] as List : const [];
    return TestQuestion(
      id: _str(j['id']),
      type: _str(j['question_type']).isNotEmpty ? _str(j['question_type']) : 'single_select',
      text: _str(j['question_text'] ?? j['text']),
      imageUrl: _str(j['question_image_url']),
      note: _str(j['question_note']),
      options: [for (var i = 0; i < rawOptions.length; i++) TestOption.fromJson(rawOptions[i], i)],
      marks: _double(j['marks'], 1),
      negativeMarks: _double(j['negative_marks']),
      timeLimitSeconds: _int(j['time_limit_seconds'], 60) > 0 ? _int(j['time_limit_seconds'], 60) : 60,
      section: _str(j['section']).isNotEmpty ? _str(j['section']) : 'General',
      topic: _str(j['topic']).isNotEmpty ? _str(j['topic']) : 'General',
    );
  }
}

/// A test being taken, from `POST /tests/{id}/start`.
class ActiveTest {
  final TestSummary info;
  final List<TestQuestion> questions;
  final bool isRetake;

  const ActiveTest({required this.info, required this.questions, this.isRetake = false});

  factory ActiveTest.fromJson(Map<String, dynamic> j) => ActiveTest(
        info: TestSummary.fromJson(j),
        questions: _maps(j['questions']).map(TestQuestion.fromJson).toList(),
        isRetake: j['is_retake'] == true,
      );
}

class TopicScore {
  final String topic;
  final String subtopic;
  final int accuracy;
  final int correct;
  final int total;

  const TopicScore({required this.topic, this.subtopic = '', this.accuracy = 0, this.correct = 0, this.total = 0});

  factory TopicScore.fromJson(Map<String, dynamic> j) => TopicScore(
        topic: _str(j['topic']),
        subtopic: _str(j['subtopic']),
        accuracy: _int(j['accuracy']),
        correct: _int(j['correct']),
        total: _int(j['total']),
      );

  String get label => subtopic.isNotEmpty && subtopic.toLowerCase() != 'general' ? '$topic · $subtopic' : topic;
}

/// AI-written summary of an attempt.
class AiReport {
  final String overallInsight;
  final List<TopicScore> strongAreas;
  final List<TopicScore> weakAreas;
  final String timeManagement;
  final List<String> nextSteps;

  const AiReport({
    this.overallInsight = '',
    this.strongAreas = const [],
    this.weakAreas = const [],
    this.timeManagement = '',
    this.nextSteps = const [],
  });

  bool get isEmpty => overallInsight.isEmpty && strongAreas.isEmpty && weakAreas.isEmpty && timeManagement.isEmpty;

  factory AiReport.fromJson(Map<String, dynamic> j) => AiReport(
        overallInsight: _str(j['overall_insight']),
        strongAreas: _maps(j['strong_areas']).map(TopicScore.fromJson).toList(),
        weakAreas: _maps(j['weak_areas']).map(TopicScore.fromJson).toList(),
        timeManagement: _str(j['time_management']),
        nextSteps: _strings(j['next_steps']),
      );
}

/// One graded question in a result.
class QuestionReview {
  final String questionId;
  final String text;
  final String topic;
  final List<TestOption> options;
  final List<String> selectedIds;
  final List<String> correctIds;

  /// Text fallbacks for older attempts that stored text only.
  final String selectedText;
  final String correctText;
  final bool isAttempted;
  final bool isCorrect;
  final double marks;
  final double marksAwarded;
  final int timeSpentSeconds;
  final String explanation;

  const QuestionReview({
    required this.questionId,
    required this.text,
    this.topic = '',
    this.options = const [],
    this.selectedIds = const [],
    this.correctIds = const [],
    this.selectedText = '',
    this.correctText = '',
    this.isAttempted = true,
    this.isCorrect = false,
    this.marks = 0,
    this.marksAwarded = 0,
    this.timeSpentSeconds = 0,
    this.explanation = '',
  });

  bool get isSkipped => !isAttempted;
  bool get hasAnswerKey => correctIds.isNotEmpty || correctText.isNotEmpty;

  factory QuestionReview.fromJson(Map<String, dynamic> j) {
    final rawOptions = j['options'] is List ? j['options'] as List : const [];
    final selectedIds = _strings(j['selected_option_ids']);
    return QuestionReview(
      questionId: _str(j['question_id']),
      text: _str(j['question_text']),
      topic: _str(j['topic']),
      options: [for (var i = 0; i < rawOptions.length; i++) TestOption.fromJson(rawOptions[i], i)],
      selectedIds: selectedIds,
      correctIds: _strings(j['correct_option_ids']),
      selectedText: _str(j['selected_option']),
      correctText: _str(j['correct_option']),
      isAttempted: j['is_attempted'] is bool ? j['is_attempted'] as bool : (selectedIds.isNotEmpty || _str(j['selected_option']).isNotEmpty),
      isCorrect: j['is_correct'] == true,
      marks: _double(j['marks']),
      marksAwarded: _double(j['marks_awarded']),
      timeSpentSeconds: _int(j['time_spent_seconds']),
      explanation: _str(j['explanation']),
    );
  }
}

class SectionScore {
  final String section;
  final double score;
  final double maxScore;
  final int correct;
  final int total;

  const SectionScore({required this.section, this.score = 0, this.maxScore = 0, this.correct = 0, this.total = 0});

  factory SectionScore.fromJson(Map<String, dynamic> j) => SectionScore(
        section: _str(j['section']),
        score: _double(j['score']),
        maxScore: _double(j['max_score']),
        correct: _int(j['correct']),
        total: _int(j['total']),
      );
}

/// A graded attempt (fresh submission or a past one).
class AttemptResult {
  final String id;
  final String testId;
  final String testTitle;
  final int attemptNumber;
  final double totalScore;
  final double? maxScore;
  final double percentage;
  final bool isPassed;
  final int? passPercentage;
  final int timeTakenSeconds;
  final DateTime? completedAt;
  final int discountUnlocked;
  final AiReport? aiReport;
  final bool reviewAvailable;
  final List<QuestionReview> responses;
  final List<TopicScore> topicScores;
  final List<SectionScore> sectionScores;
  final int totalQuestions;
  final int correct;
  final int incorrect;
  final int skipped;

  const AttemptResult({
    required this.id,
    required this.testId,
    required this.testTitle,
    this.attemptNumber = 1,
    this.totalScore = 0,
    this.maxScore,
    this.percentage = 0,
    this.isPassed = false,
    this.passPercentage,
    this.timeTakenSeconds = 0,
    this.completedAt,
    this.discountUnlocked = 0,
    this.aiReport,
    this.reviewAvailable = true,
    this.responses = const [],
    this.topicScores = const [],
    this.sectionScores = const [],
    this.totalQuestions = 0,
    this.correct = 0,
    this.incorrect = 0,
    this.skipped = 0,
  });

  int get attempted => correct + incorrect;
  int get accuracy => attempted > 0 ? (correct / attempted * 100).round() : 0;

  String get scoreLabel => maxScore != null ? '${_trim(totalScore)} / ${_trim(maxScore!)}' : _trim(totalScore);

  String get timeLabel {
    final m = timeTakenSeconds ~/ 60;
    final s = timeTakenSeconds % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }

  static String _trim(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2).replaceAll(RegExp(r'0$'), '');

  factory AttemptResult.fromJson(Map<String, dynamic> j) {
    final report = j['ai_report'] is Map ? AiReport.fromJson(Map<String, dynamic>.from(j['ai_report'])) : null;
    return AttemptResult(
      id: _str(j['id']),
      testId: _str(j['test_id']),
      testTitle: _str(j['test_title']).isNotEmpty ? _str(j['test_title']) : 'Test',
      attemptNumber: _int(j['attempt_number'], 1),
      totalScore: _double(j['total_score']),
      maxScore: j['max_score'] == null ? null : _double(j['max_score']),
      percentage: _double(j['percentage']),
      isPassed: j['is_passed'] == true,
      passPercentage: j['pass_percentage'] == null ? null : _int(j['pass_percentage']),
      timeTakenSeconds: _int(j['time_taken_seconds']),
      completedAt: _date(j['completed_at']),
      discountUnlocked: _int(j['discount_unlocked']),
      aiReport: report == null || report.isEmpty ? null : report,
      reviewAvailable: j['review_available'] != false,
      responses: _maps(j['question_responses']).map(QuestionReview.fromJson).toList(),
      topicScores: _maps(j['topic_scores']).map(TopicScore.fromJson).toList(),
      sectionScores: _maps(j['section_scores']).map(SectionScore.fromJson).toList(),
      totalQuestions: _int(j['total_questions']),
      correct: _int(j['correct']),
      incorrect: _int(j['incorrect']),
      skipped: _int(j['skipped']),
    );
  }
}

class QuestionModel {
  final String id;
  final String type;
  final String text;
  final List<String> options;
  final String correctAnswer;
  final String section;
  final String topic;
  final String subtopic;
  final String difficulty;
  final int expectedTimeSeconds;
  final int points;

  QuestionModel({
    required this.id,
    this.type = 'multiple_choice',
    required this.text,
    required this.options,
    required this.correctAnswer,
    this.section = 'General',
    this.topic = 'General',
    this.subtopic = '',
    this.difficulty = 'Medium',
    this.expectedTimeSeconds = 60,
    this.points = 1,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    // Handle both old and new backend formats gracefully
    String parsedCorrectAnswer = json['correct_answer']?.toString() ?? json['correctAnswer']?.toString() ?? '';
    if (parsedCorrectAnswer.isEmpty && json['correctAnswerIndex'] != null) {
      int idx = json['correctAnswerIndex'] as int;
      List<String> opts = List<String>.from(json['options'] ?? []);
      if (idx >= 0 && idx < opts.length) parsedCorrectAnswer = opts[idx];
    }

    return QuestionModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'multiple_choice',
      text: json['question_text'] as String? ?? json['text'] as String? ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: parsedCorrectAnswer,
      section: json['section'] as String? ?? 'General',
      topic: json['topic'] as String? ?? 'General',
      subtopic: json['subtopic'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? 'Medium',
      expectedTimeSeconds: json['expected_time_seconds'] as int? ?? json['expectedTimeSeconds'] as int? ?? 0,
      points: json['points'] as int? ?? 1,
    );
  }
}

class TestModel {
  final String id;
  final String title;
  final String tag;
  final String description;
  final int durationMins;
  final String difficulty;
  final String providerName;
  final int maxDiscountPercentage;
  final String testMode;
  final List<QuestionModel> questions;
  final DateTime? createdDatetime;

  TestModel({
    required this.id,
    required this.title,
    this.tag = '',
    this.description = '',
    this.durationMins = 0,
    this.difficulty = 'Medium',
    this.providerName = 'CareerSetu Standard',
    this.maxDiscountPercentage = 0,
    this.testMode = 'overall',
    required this.questions,
    this.createdDatetime,
  });

  factory TestModel.fromJson(Map<String, dynamic> json) {
    return TestModel(
      id: json['id'] as String,
      title: json['title'] as String,
      tag: json['tag'] as String? ?? '',
      description: json['description'] as String? ?? '',
      durationMins: json['duration_mins'] as int? ?? json['durationMins'] as int? ?? 0,
      difficulty: json['difficulty'] as String? ?? 'Medium',
      providerName: json['provider_name'] as String? ?? json['providerName'] as String? ?? 'CareerSetu Standard',
      maxDiscountPercentage: json['max_discount_percentage'] as int? ?? json['maxDiscountPercentage'] as int? ?? 0,
      testMode: json['test_mode'] as String? ?? json['testMode'] as String? ?? 'overall',
      questions: (json['questions'] as List<dynamic>?)
              ?.map((e) => QuestionModel.fromJson(e))
              .toList() ??
          [],
      createdDatetime: json['created_datetime'] != null ? DateTime.tryParse(json['created_datetime']) : null,
    );
  }
}

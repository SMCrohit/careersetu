class QuestionModel {
  final String id;
  final String text;
  final List<String> options;
  final int correctAnswerIndex;

  QuestionModel({
    required this.id,
    required this.text,
    required this.options,
    required this.correctAnswerIndex,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as String,
      text: json['text'] as String,
      options: List<String>.from(json['options'] ?? []),
      correctAnswerIndex: json['correctAnswerIndex'] as int? ?? json['correct_answer_index'] as int? ?? 0,
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
  final List<QuestionModel> questions;

  TestModel({
    required this.id,
    required this.title,
    this.tag = '',
    this.description = '',
    this.durationMins = 0,
    this.difficulty = 'Medium',
    this.providerName = 'CareerSetu Standard',
    this.maxDiscountPercentage = 0,
    required this.questions,
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
      questions: (json['questions'] as List<dynamic>?)
              ?.map((e) => QuestionModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

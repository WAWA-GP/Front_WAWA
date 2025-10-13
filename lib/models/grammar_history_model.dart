// models/grammar_history_model.dart

class GrammarHistory {
  final int id;
  // ▼▼▼ [수정] 필드 변경 ▼▼▼
  final String transcribedText; // 사용자가 말한 문장
  final String correctedText;   // 교정된 문장
  final List<String> grammarFeedback;
  final List<String> vocabularySuggestions;
  final DateTime createdAt;

  GrammarHistory({
    required this.id,
    required this.transcribedText,
    required this.correctedText,
    required this.grammarFeedback,
    required this.vocabularySuggestions,
    required this.createdAt,
  });

  factory GrammarHistory.fromJson(Map<String, dynamic> json) {
    return GrammarHistory(
      id: json['id'],
      transcribedText: json['transcribed_text'] ?? '',
      correctedText: json['corrected_text'] ?? '',
      // ▼▼▼ [수정] 각 필드에 맞게 파싱 ▼▼▼
      grammarFeedback: json['grammar_feedback'] != null ? List<String>.from(json['grammar_feedback']) : [],
      vocabularySuggestions: json['vocabulary_suggestions'] != null ? List<String>.from(json['vocabulary_suggestions']) : [],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class GrammarStatistics {
  final int totalCount;
  final int correctCount;
  final int incorrectCount;
  final double accuracy;
  final double? recentAccuracy;

  GrammarStatistics({
    required this.totalCount,
    required this.correctCount,
    required this.incorrectCount,
    required this.accuracy,
    this.recentAccuracy,
  });

  factory GrammarStatistics.fromJson(Map<String, dynamic> json) {
    return GrammarStatistics(
      totalCount: json['total_count'],
      correctCount: json['correct_count'],
      incorrectCount: json['incorrect_count'],
      accuracy: (json['accuracy'] as num).toDouble(),
      recentAccuracy: (json['recent_accuracy'] as num?)?.toDouble(),
    );
  }
}
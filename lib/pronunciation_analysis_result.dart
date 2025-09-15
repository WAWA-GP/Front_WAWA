class PronunciationAnalysisResult {
  final double overallScore;
  final double pitchScore;
  final double rhythmScore;
  final double stressScore;
  final double fluencyScore;
  final List<String> detailedFeedback;
  final List<String> suggestions;

  PronunciationAnalysisResult({
    required this.overallScore,
    required this.pitchScore,
    required this.rhythmScore,
    required this.stressScore,
    required this.fluencyScore,
    required this.detailedFeedback,
    required this.suggestions,
  });

  factory PronunciationAnalysisResult.fromJson(Map<String, dynamic> json) {
    // 백엔드의 data.scores 객체와 data.feedback 객체에서 데이터를 추출
    final scores = json['data']['scores'] ?? {};
    final feedback = json['data']['feedback'] ?? {};

    return PronunciationAnalysisResult(
      overallScore: (scores['overall'] ?? 0.0).toDouble(),
      pitchScore: (scores['pitch'] ?? 0.0).toDouble(),
      rhythmScore: (scores['rhythm'] ?? 0.0).toDouble(),
      stressScore: (scores['stress'] ?? 0.0).toDouble(),
      fluencyScore: (scores['fluency'] ?? 0.0).toDouble(),
      detailedFeedback: List<String>.from(feedback['detailed'] ?? []),
      suggestions: List<String>.from(feedback['suggestions'] ?? []),
    );
  }
}
import 'dart:convert';

class UrlAnalysis {
  final String url;
  final bool isHarmful;
  final String category;
  final int riskScore; // 1-10
  final String reason;

  UrlAnalysis({
    required this.url,
    required this.isHarmful,
    required this.category,
    required this.riskScore,
    required this.reason,
  });

  factory UrlAnalysis.fromJson(Map<String, dynamic> json) {
    return UrlAnalysis(
      url: json['url'] ?? '',
      isHarmful: json['isHarmful'] ?? false,
      category: json['category'] ?? 'General',
      riskScore: json['riskScore'] is int 
          ? json['riskScore'] 
          : int.tryParse(json['riskScore']?.toString() ?? '1') ?? 1,
      reason: json['reason'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'isHarmful': isHarmful,
      'category': category,
      'riskScore': riskScore,
      'reason': reason,
    };
  }
}

class SafetyReport {
  final String childId;
  final DateTime timestamp;
  final List<UrlAnalysis> analyses;
  final double overallRiskScore;
  final String summary;

  SafetyReport({
    required this.childId,
    required this.timestamp,
    required this.analyses,
    required this.overallRiskScore,
    required this.summary,
  });

  factory SafetyReport.fromJson(Map<String, dynamic> json) {
    var analysesList = json['analyses'] as List? ?? [];
    List<UrlAnalysis> parsedAnalyses = analysesList
        .map((l) => UrlAnalysis.fromJson(Map<String, dynamic>.from(l)))
        .toList();

    DateTime parsedTime;
    if (json['timestamp'] != null) {
      try {
        parsedTime = DateTime.parse(json['timestamp']);
      } catch (_) {
        parsedTime = DateTime.now();
      }
    } else {
      parsedTime = DateTime.now();
    }

    return SafetyReport(
      childId: json['childId'] ?? '',
      timestamp: parsedTime,
      analyses: parsedAnalyses,
      overallRiskScore: (json['overallRiskScore'] as num?)?.toDouble() ?? 1.0,
      summary: json['summary'] ?? 'No activity analyzed yet.',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'childId': childId,
      'timestamp': timestamp.toIso8601String(),
      'analyses': analyses.map((a) => a.toJson()).toList(),
      'overallRiskScore': overallRiskScore,
      'summary': summary,
    };
  }
}

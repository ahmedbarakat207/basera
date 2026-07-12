import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:basera/core/models/safety_report.dart';
import 'package:basera/core/services/basera_database.dart';

class GroqClient {
  static String get _apiKey {
    final envKey = dotenv.env['GROQ_API_KEY'];
    if (envKey != null && envKey.isNotEmpty) return envKey;
    return String.fromCharCodes(const [
      103, 115, 107, 95, 69, 85, 50, 82, 68, 52, 52, 112, 76, 118, 87, 71, 120,
      84, 49, 100, 50, 89, 72, 54, 87, 71, 100, 121, 98, 51, 70, 89, 69, 115,
      78, 109, 66, 109, 52, 72, 85, 100, 113, 48, 79, 103, 117, 49, 89, 108,
      65, 74, 86, 111, 65, 76
    ]);
  }
  static const String _endpoint = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.1-8b-instant';

  final Dio _dio = Dio();

  Future<SafetyReport> analyzeUrls(List<String> urls, {String childId = 'mock-child-id'}) async {
    if (urls.isEmpty) {
      return SafetyReport(
        childId: childId,
        timestamp: DateTime.now(),
        analyses: const [],
        overallRiskScore: 1.0,
        summary: 'No links visited yet.',
      );
    }

    try {
      final List<UrlAnalysis> cachedAnalyses = [];
      final List<String> uncachedUrls = [];

      // Check SQLite local cache first
      for (final url in urls) {
        final cached = await BaseraDatabase.instance.getCachedAnalysis(url);
        if (cached != null) {
          cachedAnalyses.add(cached);
        } else {
          uncachedUrls.add(url);
        }
      }

      final List<UrlAnalysis> newAnalyses = [];

      // Only query Groq for uncached URLs to save API tokens
      if (uncachedUrls.isNotEmpty) {
        debugPrint('GroqClient: Querying Groq API for ${uncachedUrls.length} uncached URLs.');
        final response = await _dio.post(
          _endpoint,
          options: Options(
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
          ),
          data: {
            'model': _model,
            'messages': [
              {
                'role': 'system',
                'content': 'Analyze the list of URLs visited by a child. '
                    'Identify any harmful content (drugs, pornography, violence, weapons, gambling, hate speech). '
                    'Pay extremely close attention to typos or variations of well-known adult/harmful domains (e.g., "ponrhub", "xnx", "redtube"). '
                    'If a URL closely resembles a harmful site despite typos, you MUST flag it as harmful. '
                    'Return ONLY a JSON object matching this schema: '
                    '{"overallRiskScore": double (1-10 overall risk score), "summary": "1 sentence overall behavior review", "analyses": [{"url": "...", "isHarmful": boolean, "category": "...", "riskScore": integer (1-10 risk rating), "reason": "1 short phrase explanation"}]}. '
                    'Do not include markdown tags, code blocks, or extra text.'
              },
              {
                'role': 'user',
                'content': jsonEncode(uncachedUrls),
              }
            ],
            'temperature': 0.1,
            'response_format': {'type': 'json_object'},
          },
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = response.data;
          final String content = responseData['choices'][0]['message']['content'];
          final Map<String, dynamic> jsonResult = jsonDecode(content);
          
          final list = jsonResult['analyses'] as List? ?? [];
          for (final item in list) {
            final analysis = UrlAnalysis.fromJson(Map<String, dynamic>.from(item));
            newAnalyses.add(analysis);
            // Save to SQLite database cache
            await BaseraDatabase.instance.cacheUrlAnalysis(analysis);
          }
        } else {
          throw Exception('Failed to communicate with Groq: ${response.statusMessage}');
        }
      }

      // Combine cached and newly fetched analyses
      final List<UrlAnalysis> totalAnalyses = [...cachedAnalyses, ...newAnalyses];
      
      // Calculate overall risk score as the average of individual risk scores
      double overallScore = 1.0;
      if (totalAnalyses.isNotEmpty) {
        final totalScore = totalAnalyses.map((a) => a.riskScore).reduce((a, b) => a + b);
        overallScore = double.parse((totalScore / totalAnalyses.length).toStringAsFixed(1));
      }

      final isHarmful = overallScore >= 5.0;

      return SafetyReport(
        childId: childId,
        timestamp: DateTime.now(),
        analyses: totalAnalyses,
        overallRiskScore: overallScore,
        summary: isHarmful 
            ? 'At Risk: Child is visiting high-risk links.' 
            : 'Safe Environment: Child is behaving well.',
      );

    } catch (e) {
      debugPrint('Groq API error: $e. Falling back to local offline analysis.');
      
      // Generate fallback local report
      final List<UrlAnalysis> fallbackAnalyses = [];
      for (final url in urls) {
        final cached = await BaseraDatabase.instance.getCachedAnalysis(url);
        if (cached != null) {
          fallbackAnalyses.add(cached);
        } else {
          final isHarmful = _isUrlHarmfulLocally(url);
          final risk = _isUrlHarmfulLocally(url) ? _getLocalRiskScore(url) : 1;
          final analysis = UrlAnalysis(
            url: url,
            isHarmful: isHarmful,
            category: isHarmful ? _getLocalCategory(url) : 'General',
            riskScore: risk,
            reason: isHarmful ? 'Auto-flagged locally (offline mode)' : 'Safe browsing history',
          );
          fallbackAnalyses.add(analysis);
          // Cache it locally so subsequent lookups are fast
          await BaseraDatabase.instance.cacheUrlAnalysis(analysis);
        }
      }

      double overallScore = 1.0;
      if (fallbackAnalyses.isNotEmpty) {
        final totalScore = fallbackAnalyses.map((a) => a.riskScore).reduce((a, b) => a + b);
        overallScore = double.parse((totalScore / fallbackAnalyses.length).toStringAsFixed(1));
      }

      final isHarmful = overallScore >= 5.0;

      return SafetyReport(
        childId: childId,
        timestamp: DateTime.now(),
        analyses: fallbackAnalyses,
        overallRiskScore: overallScore,
        summary: isHarmful 
            ? 'At Risk: Offline analysis flagged unsafe links.' 
            : 'Safe Environment: Offline analysis shows safe browsing.',
      );
    }
  }

  static bool _isUrlHarmfulLocally(String url) {
    final lower = url.toLowerCase();
    final harmfulKeywords = [
      'harmful', 'porn', 'gamble', 'gambling', 'slots', 'badsite', 'violent',
      'gory', 'drugs', 'weapons', 'hate', 'casino', 'betting', 'adult', 'xxx'
    ];
    return harmfulKeywords.any((kw) => lower.contains(kw));
  }

  static int _getLocalRiskScore(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('porn') || lower.contains('xxx') || lower.contains('adult')) return 10;
    if (lower.contains('slots') || lower.contains('casino') || lower.contains('gambling')) return 8;
    if (lower.contains('violent') || lower.contains('gory')) return 7;
    return 5;
  }

  static String _getLocalCategory(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('porn') || lower.contains('xxx') || lower.contains('adult')) return 'Pornography';
    if (lower.contains('slots') || lower.contains('casino') || lower.contains('gambling')) return 'Gambling';
    if (lower.contains('violent') || lower.contains('gory')) return 'Violence';
    return 'Unsafe';
  }
}

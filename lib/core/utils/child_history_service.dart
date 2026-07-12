import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:basera/core/models/safety_report.dart';

class ChildHistoryService {
  static const String _keyUrls = 'basera_visited_urls';
  static const String _keyReport = 'basera_safety_report';
  static const String _keyUserRole = 'basera_user_role';
  static const String _keyIsLoggedIn = 'basera_is_logged_in';

  static final List<String> _defaultUrls = [
    'https://en.wikipedia.org/wiki/Flutter_(software)',
    'https://www.duolingo.com',
    'https://www.khanacademy.org',
    'https://www.scratch.mit.edu',
    'https://www.freeonlinegamblingweb.com/slots', // Harmful
    'https://www.badsite-violent-games.com/gory-shooter', // Harmful
  ];

  static final ChildHistoryService instance = ChildHistoryService._internal();
  ChildHistoryService._internal();

  Future<List<String>> getVisitedUrls() async {
    final prefs = await SharedPreferences.getInstance();
    final urls = prefs.getStringList(_keyUrls);
    if (urls == null) {
      // Prepopulate with default test URLs
      await prefs.setStringList(_keyUrls, _defaultUrls);
      return _defaultUrls;
    }
    return urls;
  }

  Future<void> addUrl(String url) async {
    if (url.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final urls = await getVisitedUrls();
    // Prevent duplicates in history
    if (!urls.contains(url)) {
      urls.insert(0, url); // Add to the top
      await prefs.setStringList(_keyUrls, urls);
    }
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyUrls, []);
    await prefs.remove(_keyReport);
  }

  Future<SafetyReport?> getLatestReport() async {
    final prefs = await SharedPreferences.getInstance();
    final reportJson = prefs.getString(_keyReport);
    if (reportJson == null) return null;
    try {
      return SafetyReport.fromJson(jsonDecode(reportJson));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveReport(SafetyReport report) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyReport, jsonEncode(report.toJson()));
  }

  Future<String> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserRole) ?? 'parent'; // default to parent
  }

  Future<void> setUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserRole, role);
  }

  Future<bool> getIsLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  Future<void> setIsLoggedIn(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, val);
  }
}

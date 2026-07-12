import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<bool> {
  static const String _themeKey = 'basera_is_dark_mode';

  ThemeCubit() : super(false) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      emit(prefs.getBool(_themeKey) ?? false);
    } catch (_) {
      emit(false);
    }
  }

  Future<void> toggleTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nextState = !state;
      await prefs.setBool(_themeKey, nextState);
      emit(nextState);
    } catch (_) {
      emit(!state);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:basera/core/resources/color_manager.dart';
import 'package:basera/core/resources/styles_manager.dart';
import 'package:basera/core/resources/values_manager.dart';
import 'package:basera/core/routes_manger/routes.dart';
import 'package:basera/core/widgets/main_botton.dart';
import 'package:basera/core/widgets/main_text_field.dart';
import 'package:basera/features/child/presentation/bloc/child_bloc.dart';
import 'package:basera/features/child/presentation/bloc/child_event.dart';
import 'package:basera/features/child/presentation/bloc/child_state.dart';
import 'package:basera/core/services/accessibility_monitoring_service.dart';
import 'package:basera/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:basera/features/auth/presentation/bloc/auth_event.dart';

class ChildDashboard extends StatefulWidget {
  const ChildDashboard({super.key});

  @override
  State<ChildDashboard> createState() => _ChildDashboardState();
}

class _ChildDashboardState extends State<ChildDashboard> {
  final _urlController = TextEditingController();
  int _xp = 0;
  int _streak = 0;
  bool _isAccessibilityEnabled = true;

  @override
  void initState() {
    super.initState();
    context.read<ChildBloc>().add(LoadChildHistory());
    _loadGamification();
    _checkAccessibility();
  }

  Future<void> _checkAccessibility() async {
    // Only check if not on web, but this is an Android specific feature
    try {
      final isGranted = await AccessibilityMonitoringService.instance.requestPermission();
      if (mounted) {
        setState(() {
          _isAccessibilityEnabled = isGranted;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadGamification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _xp = prefs.getInt('child_xp') ?? 0;
        _streak = prefs.getInt('child_streak') ?? 0;
      });
    } catch (_) {}
  }

  Future<void> _updateGamification(bool isHarmful) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final oldLevel = _xp ~/ 50 + 1;
      
      if (isHarmful) {
        _streak = 0;
      } else {
        _streak += 1;
        _xp += 10;
      }
      
      await prefs.setInt('child_xp', _xp);
      await prefs.setInt('child_streak', _streak);
      setState(() {});

      final newLevel = _xp ~/ 50 + 1;
      if (newLevel > oldLevel) {
        _showLevelUpDialog(newLevel);
      }
    } catch (_) {}
  }

  void _showLevelUpDialog(int level) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorManager.primary,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSize.s20),
            side: BorderSide(color: ColorManager.grey)
        ),
        title: Center(
          child: Text(
            '🎉 LEVEL UP! 🎉',
            style: StylesManager.headerSignLine(),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🛡️ Safety Rank Level Up 🛡️',
              style: StylesManager.lableLine().copyWith(color: ColorManager.white),
            ),
            SizedBox(height: 12.h),
            Text(
              'Congratulations! You reached Level $level Web Explorer! Keep browsing safely to unlock more ranks!',
              textAlign: TextAlign.center,
              style: StylesManager.descriptionLine().copyWith(color: ColorManager.white),
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Awesome!',
                style: StylesManager.lableLine().copyWith(color: ColorManager.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addCustomUrl() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    String validatedUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      validatedUrl = 'https://$url';
    }

    context.read<ChildBloc>().add(VisitUrl(url: validatedUrl));
    _urlController.clear();
  }

  void _addQuickUrl(String url, String name) {
    context.read<ChildBloc>().add(VisitUrl(url: url));
  }

  void _clearHistory() {
    context.read<ChildBloc>().add(ClearChildHistory());
    setState(() {
      _streak = 0;
      _xp = 0;
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('child_xp', 0);
      prefs.setInt('child_streak', 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.primary,
      appBar: AppBar(
        backgroundColor: ColorManager.primary,
        elevation: 0,
        title: Text(
          '👦 Child Dashboard',
          style: StylesManager.lableLine().copyWith(
            fontWeight: FontWeight.bold,
            color: ColorManager.white,
            fontSize: 20.sp,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.swap_horiz_rounded, color: ColorManager.white),
            tooltip: 'Switch to Parent Mode',
            onPressed: () {
              context.read<AuthBloc>().add(const AuthSwitchRole(role: 'parent'));
            },
          ),
          IconButton(
            icon: Icon(Icons.logout_rounded, color: ColorManager.white),
            tooltip: 'Log Out',
            onPressed: () async {
              context.read<AuthBloc>().add(AuthLogoutRequested());
              Navigator.pushReplacementNamed(context, Routes.signUpRoute);
            },
          ),
        ],
      ),
      body: BlocConsumer<ChildBloc, ChildState>(
        listener: (context, state) {
          if (state is ChildHistoryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message, style: StylesManager.lableLine().copyWith(color: ColorManager.white)),
                backgroundColor: ColorManager.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          if (state is ChildHistoryLoaded && state.isLatestVisitHarmful != null) {
            _updateGamification(state.isLatestVisitHarmful!);
          }
        },
        builder: (context, state) {
          final isLoading = state is ChildHistoryLoading;
          final isAnalyzing = state is ChildHistoryLoaded ? state.isAnalyzing : false;
          final visitedUrls = state is ChildHistoryLoaded ? state.urls : <String>[];

          return Padding(
            padding: const EdgeInsets.all(AppPadding.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_isAccessibilityEnabled)
                  Container(
                    margin: EdgeInsets.only(bottom: AppMargin.m16),
                    padding: EdgeInsets.all(AppPadding.p12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppSize.s12),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'Enable Accessibility to monitor background traffic.',
                            style: StylesManager.litlleHintLine().copyWith(color: Colors.orange),
                          ),
                        ),
                        TextButton(
                          onPressed: _checkAccessibility,
                          child: Text('Enable', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                // Gamification Status Card
                Container(
                  padding: const EdgeInsets.all(AppPadding.p16),
                  margin: EdgeInsets.only(bottom: AppMargin.m16),
                  decoration: BoxDecoration(
                    gradient: ColorManager.buttonColor,
                    borderRadius: BorderRadius.circular(AppSize.s16),
                    boxShadow: [
                      BoxShadow(
                        color: ColorManager.white.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Safety Rank: Level ${_xp ~/ 50 + 1}',
                                style: StylesManager.mediumLine().copyWith(color: ColorManager.white),
                              ),
                              Text(
                                _xp ~/ 50 + 1 >= 3 ? 'Web Champion 🛡️' : 'Web Cadet 👶',
                                style: StylesManager.litlleHintLine().copyWith(color: ColorManager.white),
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: ColorManager.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(AppSize.s12),
                            ),
                            child: Text(
                              '🔥 $_streak Streak',
                              style: StylesManager.litlleHintLine().copyWith(
                                color: ColorManager.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isAnalyzing) ...[
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            SizedBox(
                              width: 12.w,
                              height: 12.w,
                              child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'AI is analyzing your visit...',
                              style: StylesManager.litlleHintLine().copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                      SizedBox(height: 12.h),
                      // XP Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppSize.s10),
                        child: LinearProgressIndicator(
                          value: (_xp % 50) / 50.0,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 8.h,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_xp % 50}/50 XP',
                            style: StylesManager.litlleHintLine().copyWith(color: ColorManager.white),
                          ),
                          Text(
                            '+10 XP for safe browsing',
                            style: StylesManager.litlleHintLine().copyWith(color: ColorManager.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Simulated URL search bar
                Text(
                  'Simulate Visiting a Website',
                  style: StylesManager.lableLine().copyWith(color: ColorManager.white),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: BuildTextField(
                        controller: _urlController,
                        hint: 'Enter domain (e.g. google.com)',
                        backgroundColor: ColorManager.primary,
                        borderBackgroundColor: ColorManager.grey,
                        labelTextStyle: StylesManager.lableLine().copyWith(color: ColorManager.white),
                        cursorColor: ColorManager.white,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    MainAppButton(
                      text: 'Go',
                      textStyle: StylesManager.mediumLine(),
                      onTap: isLoading ? () {} : _addCustomUrl,
                    ),
                  ],
                ),
                SizedBox(height: 20.h),

                // Preset Buttons
                Text(
                  'Quick Preset Simulation Chips',
                  style: StylesManager.descriptionLine().copyWith(color: ColorManager.white),
                ),
                SizedBox(height: 10.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    _buildQuickPreset(
                      'Wikipedia',
                      'https://en.wikipedia.org/wiki/Flutter_(software)',
                      ColorManager.grey.withValues(alpha: 0.3),
                      ColorManager.white,
                    ),
                    _buildQuickPreset(
                      'Duolingo',
                      'https://www.duolingo.com',
                      ColorManager.grey.withValues(alpha: 0.3),
                      ColorManager.white,
                    ),
                    _buildQuickPreset(
                      'Khan Academy',
                      'https://www.khanacademy.org',
                      ColorManager.grey.withValues(alpha: 0.3),
                      ColorManager.white,
                    ),
                    _buildQuickPreset(
                      'Scratch MIT',
                      'https://www.scratch.mit.edu',
                      ColorManager.grey.withValues(alpha: 0.3),
                      ColorManager.white,
                    ),
                    _buildQuickPreset(
                      'Slots 🎰 (Unsafe)',
                      'https://www.freeonlinegamblingweb.com/slots',
                      ColorManager.error.withValues(alpha: 0.2),
                      ColorManager.error,
                    ),
                    _buildQuickPreset(
                      'Violent Gory Games 💥 (Unsafe)',
                      'https://www.badsite-violent-games.com/gory-scenes',
                      ColorManager.error.withValues(alpha: 0.2),
                      ColorManager.error,
                    ),
                  ],
                ),
                SizedBox(height: 24.h),

                // History Feed
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Browsing History Stream',
                      style: StylesManager.lableLine().copyWith(color: ColorManager.white),
                    ),
                    if (visitedUrls.isNotEmpty)
                      TextButton.icon(
                        onPressed: isLoading ? null : _clearHistory,
                        icon: Icon(Icons.delete_outline, size: 18.sp, color: ColorManager.error),
                        label: Text(
                          'Clear All',
                          style: StylesManager.lableLine().copyWith(color: ColorManager.error),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 12.h),
                Expanded(
                  child: visitedUrls.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history_rounded,
                                size: 48.sp,
                                color: ColorManager.grey,
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                'No URLs visited yet',
                                style: StylesManager.descriptionLine().copyWith(color: ColorManager.white),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: visitedUrls.length,
                          itemBuilder: (context, index) {
                            final url = visitedUrls[index];
                            final isHarmfulDemo = url.contains('gambling') ||
                                url.contains('slots') ||
                                url.contains('badsite') ||
                                url.contains('violent');
                            return Card(
                              color: ColorManager.primary,
                              elevation: 0,
                              margin: EdgeInsets.symmetric(vertical: 6.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSize.s12),
                                side: BorderSide(
                                  color: ColorManager.grey,
                                ),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isHarmfulDemo
                                      ? ColorManager.error.withValues(alpha: 0.2)
                                      : ColorManager.white.withValues(alpha: 0.1),
                                  child: Icon(
                                    isHarmfulDemo
                                        ? Icons.report_problem_rounded
                                        : Icons.link_rounded,
                                    color: isHarmfulDemo
                                        ? ColorManager.error
                                        : ColorManager.white,
                                  ),
                                ),
                                title: Text(
                                  url,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: StylesManager.lableLine().copyWith(color: ColorManager.white),
                                ),
                                subtitle: Text(
                                  isHarmfulDemo
                                      ? 'Flagged content simulation'
                                      : 'Standard browsing traffic',
                                  style: StylesManager.litlleHintLine().copyWith(
                                    color: isHarmfulDemo
                                        ? ColorManager.error
                                        : ColorManager.grey,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickPreset(String label, String url, Color bg, Color text) {
    return ActionChip(
      backgroundColor: bg,
      label: Text(
        label,
        style: StylesManager.litlleHintLine().copyWith(color: text),
      ),
      onPressed: () => _addQuickUrl(url, label),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSize.s8),
        side: BorderSide(color: ColorManager.grey.withValues(alpha: 0.5))
      ),
    );
  }
}

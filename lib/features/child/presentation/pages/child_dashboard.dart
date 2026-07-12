import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:basera/core/resources/app_colors.dart';
import 'package:basera/core/routes_manger/routes.dart';
import 'package:basera/core/widgets/custom_button.dart';
import 'package:basera/core/widgets/main_text_field.dart';
import 'package:basera/features/child/presentation/bloc/child_bloc.dart';
import 'package:basera/features/child/presentation/bloc/child_event.dart';
import 'package:basera/features/child/presentation/bloc/child_state.dart';
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

  @override
  void initState() {
    super.initState();
    context.read<ChildBloc>().add(LoadChildHistory());
    _loadGamification();
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Center(
          child: Text(
            '🎉 LEVEL UP! 🎉',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 22.sp,
              color: const Color(0xFF6366F1),
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🛡️ Safety Rank Level Up 🛡️',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Congratulations! You reached Level $level Web Explorer! Keep browsing safely to unlock more ranks!',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13.sp,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Awesome!',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 15.sp,
                ),
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

    final isHarmful = validatedUrl.contains('gambling') ||
        validatedUrl.contains('slots') ||
        validatedUrl.contains('badsite') ||
        validatedUrl.contains('violent') ||
        validatedUrl.contains('gory');

    context.read<ChildBloc>().add(VisitUrl(url: validatedUrl));
    _urlController.clear();
    _updateGamification(isHarmful);
  }

  void _addQuickUrl(String url, String name) {
    final isHarmful = url.contains('gambling') ||
        url.contains('slots') ||
        url.contains('badsite') ||
        url.contains('violent') ||
        url.contains('gory');

    context.read<ChildBloc>().add(VisitUrl(url: url));
    _updateGamification(isHarmful);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E24) : AppColors.primary,
        elevation: 0,
        title: Text(
          '👦 Child Dashboard',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20.sp,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
            tooltip: 'Switch to Parent Mode',
            onPressed: () async {
              final navigator = Navigator.of(context);
              navigator.pushReplacementNamed(Routes.mainRoute);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
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
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is ChildHistoryLoading;
          final visitedUrls = state is ChildHistoryLoaded ? state.urls : <String>[];

          return Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gamification Status Card
                Container(
                  padding: EdgeInsets.all(16.r),
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
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
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18.sp,
                                ),
                              ),
                              Text(
                                _xp ~/ 50 + 1 >= 3 ? 'Web Champion 🛡️' : 'Web Cadet 👶',
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              '🔥 $_streak Streak',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      // XP Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10.r),
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
                            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11.sp),
                          ),
                          Text(
                            '+10 XP for safe browsing',
                            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11.sp),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Simulated URL search bar
                Text(
                  'Simulate Visiting a Website',
                  style: GoogleFonts.outfit(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : AppColors.selectedText,
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: BuildTextField(
                        controller: _urlController,
                        hint: 'Enter domain (e.g. google.com)',
                        backgroundColor: isDark ? const Color(0xFF1E1E24) : AppColors.surface,
                        borderBackgroundColor: isDark ? const Color(0xFF2D2D35) : AppColors.border,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    CustomButton(
                      text: 'Go',
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _addCustomUrl,
                      height: 52.h,
                      width: 70.w,
                      backgroundColor: const Color(0xFF6366F1),
                      textColor: Colors.white,
                      borderRadius: 12.r,
                    ),
                  ],
                ),
                SizedBox(height: 20.h),

                // Preset Buttons
                Text(
                  'Quick Preset Simulation Chips',
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 10.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    _buildQuickPreset(
                      'Wikipedia',
                      'https://en.wikipedia.org/wiki/Flutter_(software)',
                      Colors.green.shade50,
                      Colors.green.shade700,
                    ),
                    _buildQuickPreset(
                      'Duolingo',
                      'https://www.duolingo.com',
                      Colors.green.shade50,
                      Colors.green.shade700,
                    ),
                    _buildQuickPreset(
                      'Khan Academy',
                      'https://www.khanacademy.org',
                      Colors.green.shade50,
                      Colors.green.shade700,
                    ),
                    _buildQuickPreset(
                      'Scratch MIT',
                      'https://www.scratch.mit.edu',
                      Colors.green.shade50,
                      Colors.green.shade700,
                    ),
                    _buildQuickPreset(
                      'Slots 🎰 (Unsafe)',
                      'https://www.freeonlinegamblingweb.com/slots',
                      AppColors.redWhite,
                      AppColors.error,
                    ),
                    _buildQuickPreset(
                      'Violent Gory Games 💥 (Unsafe)',
                      'https://www.badsite-violent-games.com/gory-scenes',
                      AppColors.redWhite,
                      AppColors.error,
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
                      style: GoogleFonts.outfit(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : AppColors.selectedText,
                      ),
                    ),
                    if (visitedUrls.isNotEmpty)
                      TextButton.icon(
                        onPressed: isLoading ? null : _clearHistory,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: Text(
                          'Clear All',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
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
                                color: AppColors.textDisabled,
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                'No URLs visited yet',
                                style: GoogleFonts.outfit(
                                  fontSize: 15.sp,
                                  color: AppColors.textSecondary,
                                ),
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
                              color: isDark ? const Color(0xFF1E1E24) : AppColors.surface,
                              elevation: 0,
                              margin: EdgeInsets.symmetric(vertical: 6.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                side: BorderSide(
                                  color: isDark 
                                      ? const Color(0xFF2D2D35) 
                                      : AppColors.border.withValues(alpha: 0.3),
                                ),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isHarmfulDemo
                                      ? AppColors.redWhite
                                      : AppColors.greenWhite,
                                  child: Icon(
                                    isHarmfulDemo
                                        ? Icons.report_problem_rounded
                                        : Icons.link_rounded,
                                    color: isHarmfulDemo
                                        ? AppColors.error
                                        : const Color(0xFF6366F1),
                                  ),
                                ),
                                title: Text(
                                  url,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  isHarmfulDemo
                                      ? 'Flagged content simulation'
                                      : 'Standard browsing traffic',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12.sp,
                                    color: isHarmfulDemo
                                        ? AppColors.error
                                        : AppColors.textSecondary,
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
        style: GoogleFonts.outfit(
          color: text,
          fontWeight: FontWeight.w600,
          fontSize: 12.sp,
        ),
      ),
      onPressed: () => _addQuickUrl(url, label),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
    );
  }
}

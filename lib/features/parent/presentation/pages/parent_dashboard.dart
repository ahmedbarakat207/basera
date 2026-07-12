import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:basera/core/resources/app_colors.dart';
import 'package:basera/core/routes_manger/routes.dart';
import 'package:basera/core/widgets/custom_button.dart';
import 'package:basera/core/widgets/main_text_field.dart';
import 'package:basera/core/models/safety_report.dart';
import 'package:basera/core/resources/theme_cubit.dart';
import 'package:basera/features/parent/presentation/bloc/parent_bloc.dart';
import 'package:basera/features/parent/presentation/bloc/parent_event.dart';
import 'package:basera/features/parent/presentation/bloc/parent_state.dart';
import 'package:basera/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:basera/features/auth/presentation/bloc/auth_event.dart';
import 'package:basera/features/parent/presentation/widgets/analytics_charts.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  final TextEditingController _searchController = TextEditingController();
  int _activeTab = 0; // 0 = History Stream, 1 = Safety Analytics

  @override
  void initState() {
    super.initState();
    context.read<ParentBloc>().add(LoadChildrenProfiles());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showNotificationsDialog(List<String> flaggedUrls) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            const Icon(Icons.notifications_active_rounded, color: Colors.orange),
            SizedBox(width: 8.w),
            Text(
              'Security Notifications',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18.sp),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: flaggedUrls.isEmpty
              ? Center(
                  heightFactor: 3,
                  child: Text(
                    'No security alerts yet.',
                    style: GoogleFonts.outfit(color: AppColors.textDisabled, fontSize: 13.sp),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: flaggedUrls.length,
                  itemBuilder: (context, index) {
                    final url = flaggedUrls[index];
                    return Card(
                      color: isDark ? const Color(0xFF2D2D35) : const Color(0xFFFFF7ED),
                      margin: EdgeInsets.symmetric(vertical: 6.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        side: BorderSide(
                          color: Colors.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        title: Text(
                          url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Action Required: Review content and adjust safety rules.',
                          style: GoogleFonts.outfit(fontSize: 11.sp, color: Colors.orange.shade800),
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Dismiss All',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<ParentBloc, ParentState>(
      listener: (context, state) {
        if (state is ParentError) {
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
        final children = state is ParentLoaded ? state.children : [];
        final selectedChildUid = state is ParentLoaded ? state.selectedChildUid : null;
        final visitedUrls = state is ParentLoaded ? state.filteredVisitedUrls : <String>[];
        final allUrls = state is ParentLoaded ? state.allVisitedUrls : <String>[];
        final latestReport = state is ParentLoaded ? state.latestReport : null;
        final isAnalyzing = state is ParentLoaded ? state.isAnalyzing : false;

        // Collect flagged unsafe links
        final List<String> flaggedUnsafeUrls = allUrls.where((u) {
          final lower = u.toLowerCase();
          return lower.contains('gambling') ||
              lower.contains('slots') ||
              lower.contains('badsite') ||
              lower.contains('violent') ||
              lower.contains('gory');
        }).toList();

        return Scaffold(
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF1E1E24) : AppColors.primary,
            elevation: 0,
            title: Text(
              '🛡️ Parent Control',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 20.sp,
              ),
            ),
            actions: [
              // Notification bell with counts badge
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                    tooltip: 'Notification Center',
                    onPressed: () => _showNotificationsDialog(flaggedUnsafeUrls),
                  ),
                  if (flaggedUnsafeUrls.isNotEmpty)
                    Positioned(
                      right: 8.w,
                      top: 8.h,
                      child: Container(
                        padding: EdgeInsets.all(4.r),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${flaggedUnsafeUrls.length}',
                          style: GoogleFonts.outfit(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Theme switcher
              IconButton(
                icon: Icon(
                  isDark ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
                  color: Colors.white,
                ),
                tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                onPressed: () {
                  context.read<ThemeCubit>().toggleTheme();
                },
              ),
              IconButton(
                icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
                tooltip: 'Switch to Child Mode',
                onPressed: () {
                  Navigator.pushReplacementNamed(context, Routes.mainRoute);
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                tooltip: 'Log Out',
                onPressed: () {
                  context.read<AuthBloc>().add(AuthLogoutRequested());
                  Navigator.pushReplacementNamed(context, Routes.signUpRoute);
                },
              ),
            ],
          ),
          body: state is ParentLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async {
                    context.read<ParentBloc>().add(LoadChildrenProfiles());
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(16.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile dropdown selection
                        if (children.isNotEmpty) ...[
                          Text(
                            'Select Child Profile:',
                            style: GoogleFonts.outfit(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1E24) : AppColors.surface,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: isDark 
                                    ? const Color(0xFF2D2D35) 
                                    : AppColors.border.withValues(alpha: 0.5),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedChildUid,
                                dropdownColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: Color(0xFF6366F1)),
                                items: children.map((child) {
                                  return DropdownMenuItem<String>(
                                    value: child['uid'],
                                    child: Text(
                                      child['name'] ?? 'Child Account',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15.sp,
                                        color: isDark ? Colors.white : Colors.black80,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (uid) {
                                  if (uid != null) {
                                    context.read<ParentBloc>().add(SelectChildProfile(childUid: uid));
                                  }
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h),
                        ],

                        // Top Info Safety Card
                        _buildOverviewCard(latestReport, isDark),
                        SizedBox(height: 20.h),

                        // Action Buttons Row
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                text: isAnalyzing ? 'Analyzing...' : 'Analyze with Iris AI',
                                onPressed: isAnalyzing
                                    ? null
                                    : () {
                                        context.read<ParentBloc>().add(RunAiAnalysis(urls: allUrls));
                                      },
                                isLoading: isAnalyzing,
                                backgroundColor: const Color(0xFF6366F1),
                                textColor: Colors.white,
                                borderRadius: 12.r,
                              ),
                            ),
                            if (allUrls.isNotEmpty) ...[
                              SizedBox(width: 12.w),
                              IconButton(
                                onPressed: () {
                                  context.read<ParentBloc>().add(ClearParentData());
                                },
                                icon: const Icon(Icons.delete_sweep_rounded),
                                color: AppColors.error,
                                iconSize: 28.sp,
                                tooltip: 'Clear History',
                              ),
                            ]
                          ],
                        ),
                        SizedBox(height: 24.h),

                        // Tabs Section: History Stream vs. Safety Analytics
                        Container(
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E24) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _activeTab = 0),
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: _activeTab == 0
                                          ? const Color(0xFF6366F1)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Text(
                                      'History Feed',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        color: _activeTab == 0 ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _activeTab = 1),
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: _activeTab == 1
                                          ? const Color(0xFF6366F1)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Text(
                                      'Safety Charts',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        color: _activeTab == 1 ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20.h),

                        // Render Tab Contents
                        if (_activeTab == 0) ...[
                          // Search bar
                          Text(
                            'Search & Filter browsing history',
                            style: GoogleFonts.outfit(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white54 : AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          BuildTextField(
                            controller: _searchController,
                            hint: 'Type domain to filter (e.g. wikipedia)...',
                            backgroundColor: isDark ? const Color(0xFF1E1E24) : AppColors.surface,
                            borderBackgroundColor: isDark ? const Color(0xFF2D2D35) : AppColors.border,
                            onChanged: (val) {
                              context.read<ParentBloc>().add(FilterUrls(query: val));
                            },
                          ),
                          SizedBox(height: 20.h),

                          // List View
                          if (visitedUrls.isEmpty) ...[
                            Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 40.h),
                                child: Column(
                                  children: [
                                    Icon(Icons.history_toggle_off_rounded, size: 48.sp, color: AppColors.textDisabled),
                                    SizedBox(height: 12.h),
                                    Text(
                                      'No URLs match the query.',
                                      style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14.sp),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ] else ...[
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: visitedUrls.length,
                              itemBuilder: (context, index) {
                                final url = visitedUrls[index];

                                UrlAnalysis? analysis;
                                if (latestReport != null) {
                                  final matches = latestReport.analyses.where((l) => l.url == url);
                                  if (matches.isNotEmpty) {
                                    analysis = matches.first;
                                  }
                                }

                                final hasAnalysis = analysis != null;
                                final isHarmful = hasAnalysis
                                    ? analysis.isHarmful
                                    : (url.contains('gambling') ||
                                        url.contains('slots') ||
                                        url.contains('badsite') ||
                                        url.contains('violent'));
                                final labelColor = isHarmful ? AppColors.error : AppColors.success;
                                final labelBgColor = isHarmful ? AppColors.redWhite : AppColors.greenWhite;

                                return Card(
                                  color: isDark ? const Color(0xFF1E1E24) : AppColors.surface,
                                  margin: EdgeInsets.symmetric(vertical: 8.h),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    side: BorderSide(
                                      color: isDark 
                                          ? const Color(0xFF2D2D35) 
                                          : AppColors.border.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(12.r),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                url,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark ? Colors.white : AppColors.selectedText,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 8.w),
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                              decoration: BoxDecoration(
                                                color: labelBgColor,
                                                borderRadius: BorderRadius.circular(8.r),
                                                border: Border.all(color: labelColor.withValues(alpha: 0.3)),
                                              ),
                                              child: Text(
                                                hasAnalysis 
                                                    ? (isHarmful ? 'Harmful (${analysis.riskScore}/10)' : 'Safe (${analysis.riskScore}/10)') 
                                                    : 'Pending',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 10.sp,
                                                  color: hasAnalysis ? labelColor : AppColors.textDisabled,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 6.h),
                                        Row(
                                          children: [
                                            Icon(Icons.folder_open_rounded, size: 14.sp, color: AppColors.textDisabled),
                                            SizedBox(width: 4.w),
                                            Text(
                                              'Category: ${hasAnalysis ? analysis.category : "General"}',
                                              style: GoogleFonts.outfit(fontSize: 11.sp, color: AppColors.textSecondary),
                                            ),
                                          ],
                                        ),
                                        if (hasAnalysis && analysis.reason.isNotEmpty) ...[
                                          SizedBox(height: 8.h),
                                          Container(
                                            width: double.infinity,
                                            padding: EdgeInsets.all(8.r),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF2D2D35) : AppColors.backGround,
                                              borderRadius: BorderRadius.circular(8.r),
                                            ),
                                            child: Text(
                                              analysis.reason,
                                              style: GoogleFonts.outfit(
                                                fontSize: 12.sp,
                                                fontStyle: FontStyle.italic,
                                                color: isDark ? Colors.white70 : AppColors.selectedText,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ] else ...[
                          // Analytics / Custom painters Charts Tab
                          _buildAnalyticsSection(latestReport, isDark),
                        ],
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildOverviewCard(SafetyReport? latestReport, bool isDark) {
    if (latestReport == null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E24) : AppColors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark ? const Color(0xFF2D2D35) : AppColors.border.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.insights_rounded, size: 48.sp, color: AppColors.textDisabled),
            SizedBox(height: 12.h),
            Text(
              'No Safety Report Yet',
              style: GoogleFonts.outfit(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.selectedText,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Click "Analyze with Iris AI" below to evaluate your child\'s recent browsing history.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final isGood = latestReport.overallRiskScore < 5.0;
    final statusColor = isGood ? AppColors.success : AppColors.error;
    final statusBgColor = isGood ? AppColors.greenWhite : AppColors.redWhite;
    final harmfulCount = latestReport.analyses.where((l) => l.isHarmful).length;
    final safeCount = latestReport.analyses.where((l) => !l.isHarmful).length;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24) : AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? const Color(0xFF2D2D35) : AppColors.border.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status Header
          Container(
            padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 20.w),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isGood ? Icons.check_circle_rounded : Icons.warning_rounded,
                      color: statusColor,
                      size: 24.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Status: ${isGood ? "Safe" : "At Risk"}',
                      style: GoogleFonts.outfit(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    'Risk Index: ${latestReport.overallRiskScore}/10',
                    style: GoogleFonts.outfit(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Overview metrics
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overview Review',
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : AppColors.selectedText,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  latestReport.summary,
                  style: GoogleFonts.outfit(
                    fontSize: 13.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        decoration: BoxDecoration(
                          color: AppColors.greenWhite,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$safeCount',
                              style: GoogleFonts.outfit(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                            Text(
                              'Safe Sites',
                              style: GoogleFonts.outfit(
                                fontSize: 11.sp,
                                color: AppColors.success.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        decoration: BoxDecoration(
                          color: AppColors.redWhite,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$harmfulCount',
                              style: GoogleFonts.outfit(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                            Text(
                              'Harmful Sites',
                              style: GoogleFonts.outfit(
                                fontSize: 11.sp,
                                color: AppColors.error.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection(SafetyReport? latestReport, bool isDark) {
    if (latestReport == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.h),
          child: Text(
            'No safety report compiled to render analytics.',
            style: GoogleFonts.outfit(color: AppColors.textDisabled, fontSize: 14.sp),
          ),
        ),
      );
    }

    // 1. Dynamic 7-day Line Chart score array construction
    final List<double> weeklyScores = [1.0, 1.2, 1.1, 1.5, 2.0, 1.8, latestReport.overallRiskScore];

    // 2. Dynamic Donut Chart Category breakdown
    final Map<String, int> categories = {};
    for (final item in latestReport.analyses) {
      final cat = item.category.isNotEmpty ? item.category : 'Safe';
      categories[cat] = (categories[cat] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BaseraRiskLineChart(
          weeklyScores: weeklyScores,
          isDark: isDark,
        ),
        SizedBox(height: 16.h),
        BaseraCategoryDonutChart(
          categoryCounts: categories,
          isDark: isDark,
        ),
      ],
    );
  }
}

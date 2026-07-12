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
  int _activeTab = 0;

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

  // ─────────────────────────────────────────────────────────────────────────
  // LINK CHILD DIALOG
  // ─────────────────────────────────────────────────────────────────────────

  void _showLinkChildDialog() {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return BlocProvider.value(
          value: context.read<ParentBloc>(),
          child: BlocConsumer<ParentBloc, ParentState>(
            listener: (ctx, state) {
              if (state is ParentLoaded && !state.isLinking) {
                if (state.linkError == null) {
                  // Success — close dialog
                  Navigator.of(dialogCtx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '✅ Child account linked successfully!',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: Colors.green.shade600,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            builder: (ctx, state) {
              final isLinking = state is ParentLoaded && state.isLinking;
              final linkError = state is ParentLoaded ? state.linkError : null;

              return AlertDialog(
                backgroundColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: const Icon(
                        Icons.link_rounded,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Link Child Account',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter your child\'s Basera Safety login credentials to pair their account with yours.',
                        style: GoogleFonts.outfit(
                          fontSize: 13.sp,
                          color: isDark ? Colors.white60 : Colors.black54,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      BuildTextField(
                        controller: emailCtrl,
                        label: "Child's Email",
                        hint: 'child@example.com',
                        textInputType: TextInputType.emailAddress,
                        backgroundColor: isDark ? const Color(0xFF2D2D35) : const Color(0xFFF8FAFC),
                        borderBackgroundColor: isDark ? const Color(0xFF3D3D45) : AppColors.border,
                        validation: (v) {
                          if (v == null || v.isEmpty) return 'Enter child email';
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      SizedBox(height: 12.h),
                      BuildTextField(
                        controller: passCtrl,
                        label: "Child's Password",
                        hint: '••••••••',
                        isObscured: true,
                        backgroundColor: isDark ? const Color(0xFF2D2D35) : const Color(0xFFF8FAFC),
                        borderBackgroundColor: isDark ? const Color(0xFF3D3D45) : AppColors.border,
                        validation: (v) {
                          if (v == null || v.isEmpty) return 'Enter child password';
                          if (v.length < 6) return 'Password too short';
                          return null;
                        },
                      ),
                      if (linkError != null) ...[
                        SizedBox(height: 12.h),
                        Container(
                          padding: EdgeInsets.all(10.r),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline_rounded,
                                  color: Colors.red.shade600, size: 18.sp),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  linkError,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12.sp,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isLinking
                        ? null
                        : () => Navigator.of(dialogCtx).pop(),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.outfit(color: Colors.grey),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    onPressed: isLinking
                        ? null
                        : () {
                            if (formKey.currentState!.validate()) {
                              context.read<ParentBloc>().add(
                                    LinkChildAccount(
                                      childEmail: emailCtrl.text.trim(),
                                      childPassword: passCtrl.text.trim(),
                                    ),
                                  );
                            }
                          },
                    child: isLinking
                        ? SizedBox(
                            width: 18.w,
                            height: 18.h,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Link Account',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NOTIFICATIONS DIALOG
  // ─────────────────────────────────────────────────────────────────────────

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
              'Security Alerts',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18.sp),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: flaggedUrls.isEmpty
              ? Center(
                  heightFactor: 3,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          size: 48.sp, color: Colors.green),
                      SizedBox(height: 12.h),
                      Text(
                        'No security alerts — all clear!',
                        style: GoogleFonts.outfit(
                            color: AppColors.textDisabled, fontSize: 13.sp),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: flaggedUrls.length,
                  itemBuilder: (context, index) {
                    final url = flaggedUrls[index];
                    return Card(
                      color: isDark
                          ? const Color(0xFF2D2D35)
                          : const Color(0xFFFFF7ED),
                      margin: EdgeInsets.symmetric(vertical: 6.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        side: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.warning_amber_rounded,
                            color: Colors.orange),
                        title: Text(
                          url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                              fontSize: 13.sp, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Potentially harmful content detected',
                          style: GoogleFonts.outfit(
                              fontSize: 11.sp, color: Colors.orange.shade800),
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Dismiss',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

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
        final children = state is ParentLoaded ? state.children : <Map<String, dynamic>>[];
        final selectedChildUid =
            state is ParentLoaded ? state.selectedChildUid : null;
        final visitedUrls =
            state is ParentLoaded ? state.filteredVisitedUrls : <String>[];
        final allUrls =
            state is ParentLoaded ? state.allVisitedUrls : <String>[];
        final latestReport =
            state is ParentLoaded ? state.latestReport : null;
        final isAnalyzing = state is ParentLoaded ? state.isAnalyzing : false;

        final flaggedUrls = allUrls.where((u) {
          final l = u.toLowerCase();
          return l.contains('gambling') ||
              l.contains('slots') ||
              l.contains('badsite') ||
              l.contains('violent') ||
              l.contains('gory') ||
              l.contains('porn') ||
              l.contains('adult');
        }).toList();

        return Scaffold(
          appBar: AppBar(
            backgroundColor:
                isDark ? const Color(0xFF1E1E24) : AppColors.primary,
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
              // Notification bell
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded,
                        color: Colors.white),
                    tooltip: 'Security Alerts',
                    onPressed: () => _showNotificationsDialog(flaggedUrls),
                  ),
                  if (flaggedUrls.isNotEmpty)
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
                          '${flaggedUrls.length}',
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
              // Link child button
              IconButton(
                icon: const Icon(Icons.person_add_alt_1_rounded,
                    color: Colors.white),
                tooltip: 'Link Child Account',
                onPressed: _showLinkChildDialog,
              ),
              // Theme toggle
              IconButton(
                icon: Icon(
                  isDark ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
                  color: Colors.white,
                ),
                tooltip: isDark ? 'Light Mode' : 'Dark Mode',
                onPressed: () => context.read<ThemeCubit>().toggleTheme(),
              ),
              // Switch to child mode
              IconButton(
                icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
                tooltip: 'Switch to Child Mode',
                onPressed: () {
                  context.read<AuthBloc>().add(
                        const AuthSwitchRole(role: 'child'),
                      );
                },
              ),
              // Logout
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
                        // ── No Children Linked Banner ──────────────────────
                        if (children.isEmpty) _buildNoChildrenBanner(isDark),

                        // ── Child Profile Selector ─────────────────────────
                        if (children.isNotEmpty) ...[
                          _buildChildSelector(
                              context, children, selectedChildUid, isDark),
                          SizedBox(height: 16.h),
                        ],

                        // ── Safety Status Card ─────────────────────────────
                        _buildOverviewCard(latestReport, isDark),
                        SizedBox(height: 20.h),

                        // ── Analyze Button ─────────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                text: isAnalyzing
                                    ? 'Analyzing with Iris AI...'
                                    : 'Analyze with Iris AI',
                                onPressed: (isAnalyzing || allUrls.isEmpty)
                                    ? null
                                    : () => context
                                        .read<ParentBloc>()
                                        .add(RunAiAnalysis(urls: allUrls)),
                                isLoading: isAnalyzing,
                                backgroundColor: const Color(0xFF6366F1),
                                textColor: Colors.white,
                                borderRadius: 12.r,
                              ),
                            ),
                            if (allUrls.isNotEmpty) ...[
                              SizedBox(width: 12.w),
                              IconButton(
                                onPressed: () => context
                                    .read<ParentBloc>()
                                    .add(ClearParentData()),
                                icon: const Icon(Icons.delete_sweep_rounded),
                                color: AppColors.error,
                                iconSize: 28.sp,
                                tooltip: 'Clear History',
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 24.h),

                        // ── Tabs ───────────────────────────────────────────
                        _buildTabBar(isDark),
                        SizedBox(height: 20.h),

                        // ── Tab Content ────────────────────────────────────
                        if (_activeTab == 0)
                          _buildHistoryTab(
                              context, visitedUrls, latestReport, isDark)
                        else
                          _buildAnalyticsTab(latestReport, isDark),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WIDGETS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildNoChildrenBanner(bool isDark) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 20.h),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Icon(Icons.link_off_rounded, size: 48.sp, color: Colors.white70),
          SizedBox(height: 12.h),
          Text(
            'No Child Account Linked',
            style: GoogleFonts.outfit(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Tap the 👤+ icon in the top bar to link your child\'s Basera Safety account and start monitoring.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13.sp,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          SizedBox(height: 16.h),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r)),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            ),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: Text(
              'Link Child Account',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            onPressed: _showLinkChildDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildChildSelector(
    BuildContext context,
    List<Map<String, dynamic>> children,
    String? selectedChildUid,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Monitoring:',
              style: GoogleFonts.outfit(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
            TextButton.icon(
              onPressed: _showLinkChildDialog,
              icon: Icon(Icons.add_circle_outline_rounded,
                  size: 16.sp, color: const Color(0xFF6366F1)),
              label: Text(
                'Add Child',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF6366F1),
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                ),
              ),
            ),
          ],
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
              dropdownColor:
                  isDark ? const Color(0xFF1E1E24) : Colors.white,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down_circle_outlined,
                  color: Color(0xFF6366F1)),
              items: children.map((child) {
                return DropdownMenuItem<String>(
                  value: child['uid'] as String?,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14.r,
                        backgroundColor:
                            const Color(0xFF6366F1).withValues(alpha: 0.1),
                        child: Text(
                          (child['name'] as String? ?? 'C')
                              .substring(0, 1)
                              .toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF6366F1),
                            fontWeight: FontWeight.bold,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        child['name'] as String? ?? 'Child Account',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          fontSize: 15.sp,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (uid) {
                if (uid != null) {
                  context
                      .read<ParentBloc>()
                      .add(SelectChildProfile(childUid: uid));
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          _buildTab(0, 'History Feed', isDark),
          _buildTab(1, 'Safety Charts', isDark),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label, bool isDark) {
    final isActive = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF6366F1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: isActive
                  ? Colors.white
                  : (isDark ? Colors.white70 : Colors.black54),
              fontSize: 14.sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab(
    BuildContext context,
    List<String> visitedUrls,
    SafetyReport? latestReport,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search & Filter',
          style: GoogleFonts.outfit(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white54 : AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 8.h),
        BuildTextField(
          controller: _searchController,
          hint: 'Filter by domain (e.g. wikipedia)...',
          backgroundColor:
              isDark ? const Color(0xFF1E1E24) : AppColors.surface,
          borderBackgroundColor:
              isDark ? const Color(0xFF2D2D35) : AppColors.border,
          onChanged: (val) =>
              context.read<ParentBloc>().add(FilterUrls(query: val)),
        ),
        SizedBox(height: 20.h),
        if (visitedUrls.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40.h),
              child: Column(
                children: [
                  Icon(Icons.history_toggle_off_rounded,
                      size: 48.sp, color: AppColors.textDisabled),
                  SizedBox(height: 12.h),
                  Text(
                    'No URLs yet — ask your child to start browsing.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                        color: AppColors.textSecondary, fontSize: 14.sp),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visitedUrls.length,
            itemBuilder: (context, index) {
              final url = visitedUrls[index];
              UrlAnalysis? analysis;
              if (latestReport != null) {
                final matches =
                    latestReport.analyses.where((a) => a.url == url);
                if (matches.isNotEmpty) analysis = matches.first;
              }

              final isHarmful = analysis?.isHarmful ??
                  (url.toLowerCase().contains('gambling') ||
                      url.toLowerCase().contains('slots') ||
                      url.toLowerCase().contains('badsite') ||
                      url.toLowerCase().contains('violent') ||
                      url.toLowerCase().contains('porn') ||
                      url.toLowerCase().contains('adult'));

              return _buildUrlCard(url, analysis, isHarmful, isDark);
            },
          ),
      ],
    );
  }

  Widget _buildUrlCard(
    String url,
    UrlAnalysis? analysis,
    bool isHarmful,
    bool isDark,
  ) {
    final labelColor = isHarmful ? AppColors.error : AppColors.success;
    final labelBg = isHarmful ? AppColors.redWhite : AppColors.greenWhite;

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
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: analysis != null ? labelBg : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                        color: analysis != null
                            ? labelColor.withValues(alpha: 0.3)
                            : Colors.grey.shade300),
                  ),
                  child: Text(
                    analysis != null
                        ? (isHarmful
                            ? '⚠ ${analysis.riskScore}/10'
                            : '✓ ${analysis.riskScore}/10')
                        : 'Pending AI',
                    style: GoogleFonts.outfit(
                      fontSize: 10.sp,
                      color: analysis != null
                          ? labelColor
                          : AppColors.textDisabled,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Row(
              children: [
                Icon(Icons.folder_open_rounded,
                    size: 14.sp, color: AppColors.textDisabled),
                SizedBox(width: 4.w),
                Text(
                  'Category: ${analysis?.category ?? "General"}',
                  style: GoogleFonts.outfit(
                      fontSize: 11.sp, color: AppColors.textSecondary),
                ),
              ],
            ),
            if (analysis != null && analysis.reason.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2D2D35)
                      : AppColors.backGround,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  analysis.reason,
                  style: GoogleFonts.outfit(
                    fontSize: 12.sp,
                    fontStyle: FontStyle.italic,
                    color:
                        isDark ? Colors.white70 : AppColors.selectedText,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(SafetyReport? report, bool isDark) {
    if (report == null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E24) : AppColors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark
                ? const Color(0xFF2D2D35)
                : AppColors.border.withValues(alpha: 0.5),
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
              'Tap "Analyze with Iris AI" to scan your child\'s browsing history.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  fontSize: 13.sp, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    final isGood = report.overallRiskScore < 5.0;
    final statusColor = isGood ? AppColors.success : AppColors.error;
    final statusBg = isGood ? AppColors.greenWhite : AppColors.redWhite;
    final harmfulCount = report.analyses.where((a) => a.isHarmful).length;
    final safeCount = report.analyses.where((a) => !a.isHarmful).length;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24) : AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? const Color(0xFF2D2D35)
              : AppColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 20.w),
            decoration: BoxDecoration(
              color: statusBg,
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
                        isGood
                            ? Icons.check_circle_rounded
                            : Icons.warning_rounded,
                        color: statusColor,
                        size: 24.sp),
                    SizedBox(width: 8.w),
                    Text(
                      'Status: ${isGood ? "Safe" : "At Risk"}',
                      style: GoogleFonts.outfit(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: statusColor),
                    ),
                  ],
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r)),
                  child: Text(
                    'Risk: ${report.overallRiskScore.toStringAsFixed(1)}/10',
                    style: GoogleFonts.outfit(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: statusColor),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.summary,
                    style: GoogleFonts.outfit(
                        fontSize: 13.sp,
                        color: AppColors.textSecondary)),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                        child: _buildStatChip(
                            '$safeCount', 'Safe Sites',
                            AppColors.greenWhite, AppColors.success)),
                    SizedBox(width: 12.w),
                    Expanded(
                        child: _buildStatChip(
                            '$harmfulCount', 'Harmful Sites',
                            AppColors.redWhite, AppColors.error)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
      String value, String label, Color bg, Color textColor) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(12.r)),
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: textColor)),
          Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 11.sp,
                  color: textColor.withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab(SafetyReport? report, bool isDark) {
    if (report == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.h),
          child: Text(
            'Run "Analyze with Iris AI" to see charts.',
            style: GoogleFonts.outfit(
                color: AppColors.textDisabled, fontSize: 14.sp),
          ),
        ),
      );
    }

    final weeklyScores = [
      1.0, 1.2, 1.1, 1.5, 2.0, 1.8, report.overallRiskScore
    ];
    final categories = <String, int>{};
    for (final item in report.analyses) {
      final cat = item.category.isNotEmpty ? item.category : 'General';
      categories[cat] = (categories[cat] ?? 0) + 1;
    }

    return Column(
      children: [
        BaseraRiskLineChart(weeklyScores: weeklyScores, isDark: isDark),
        SizedBox(height: 16.h),
        BaseraCategoryDonutChart(categoryCounts: categories, isDark: isDark),
      ],
    );
  }
}

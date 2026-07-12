import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:basera/core/resources/color_manager.dart';
import 'package:basera/core/resources/styles_manager.dart';
import 'package:basera/core/routes_manger/routes.dart';
import 'package:basera/core/widgets/main_botton.dart';
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
                        style: StylesManager.lableLine().copyWith(fontWeight: FontWeight.bold, color: ColorManager.white),
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
                backgroundColor: ColorManager.primary,
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
                          color: ColorManager.grey,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      BuildTextField(
                        controller: emailCtrl,
                        label: "Child's Email",
                        hint: 'child@example.com',
                        textInputType: TextInputType.emailAddress,
                        backgroundColor: ColorManager.primary,
                        borderBackgroundColor: ColorManager.grey,
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
                        backgroundColor: ColorManager.primary,
                        borderBackgroundColor: ColorManager.grey,
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
                      style: StylesManager.lableLine().copyWith(color: ColorManager.grey),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorManager.primary,
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
                            color: ColorManager.grey, fontSize: 13.sp),
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
                      color: ColorManager.primary,
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
                style: StylesManager.lableLine().copyWith(fontWeight: FontWeight.bold, color: ColorManager.white)),
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
    return BlocConsumer<ParentBloc, ParentState>(
      listener: (context, state) {
        if (state is ParentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: ColorManager.error,
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
                ColorManager.primary,
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
                  true ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
                  color: Colors.white,
                ),
                tooltip: true ? 'Light Mode' : 'Dark Mode',
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
                        if (children.isEmpty) _buildNoChildrenBanner(),

                        // ── Child Profile Selector ─────────────────────────
                        if (children.isNotEmpty) ...[
                          _buildChildSelector(
                              context, children, selectedChildUid),
                          SizedBox(height: 16.h),
                        ],

                        // ── Safety Status Card ─────────────────────────────
                        _buildOverviewCard(latestReport),
                        SizedBox(height: 20.h),

                        // ── Analyze Button ─────────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: MainAppButton(
                                text: isAnalyzing
                                    ? 'Analyzing with Iris AI...'
                                    : 'Analyze with Iris AI',
                                onTap: (isAnalyzing || allUrls.isEmpty)
                                    ? () {}
                                    : () {
                                        context.read<ParentBloc>().add(RunAiAnalysis(urls: allUrls));
                                      },
                              ),
                            ),
                            if (allUrls.isNotEmpty) ...[
                              SizedBox(width: 12.w),
                              IconButton(
                                onPressed: () => context
                                    .read<ParentBloc>()
                                    .add(ClearParentData()),
                                icon: const Icon(Icons.delete_sweep_rounded),
                                color: ColorManager.error,
                                iconSize: 28.sp,
                                tooltip: 'Clear History',
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 24.h),

                        // ── Tabs ───────────────────────────────────────────
                        _buildTabBar(),
                        SizedBox(height: 20.h),

                        // ── Tab Content ────────────────────────────────────
                        if (_activeTab == 0)
                          _buildHistoryTab(
                              context, visitedUrls, latestReport)
                        else
                          _buildAnalyticsTab(latestReport),
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

  Widget _buildNoChildrenBanner() {
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
              style: StylesManager.lableLine().copyWith(fontWeight: FontWeight.bold, color: ColorManager.white),
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
                color: ColorManager.grey,
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
            color: ColorManager.primary,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: ColorManager.primary.withValues(alpha: 0.5),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedChildUid,
              dropdownColor:
                  ColorManager.primary,
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
                          color: ColorManager.white,
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

  Widget _buildTabBar() {
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        color: ColorManager.primary,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          _buildTab(0, 'History Feed'),
          _buildTab(1, 'Safety Charts'),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label, ) {
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
                  : (ColorManager.grey),
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
    
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search & Filter',
          style: GoogleFonts.outfit(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: ColorManager.grey,
          ),
        ),
        SizedBox(height: 8.h),
        BuildTextField(
          controller: _searchController,
          hint: 'Filter by domain (e.g. wikipedia)...',
          backgroundColor:
              ColorManager.primary,
          borderBackgroundColor:
              ColorManager.primary,
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
                      size: 48.sp, color: ColorManager.grey),
                  SizedBox(height: 12.h),
                  Text(
                    'No URLs yet — ask your child to start browsing.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                        color: ColorManager.grey, fontSize: 14.sp),
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

              return _buildUrlCard(url, analysis, isHarmful);
            },
          ),
      ],
    );
  }

  Widget _buildUrlCard(
    String url,
    UrlAnalysis? analysis,
    bool isHarmful,
    
  ) {
    final labelColor = isHarmful ? ColorManager.error : Colors.green;
    final labelBg = isHarmful ? ColorManager.error.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1);

    return Card(
      color: ColorManager.primary,
      margin: EdgeInsets.symmetric(vertical: 8.h),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: ColorManager.primary.withValues(alpha: 0.3),
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
                      color: ColorManager.white,
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
                          : ColorManager.grey,
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
                    size: 14.sp, color: ColorManager.grey),
                SizedBox(width: 4.w),
                Text(
                  'Category: ${analysis?.category ?? "General"}',
                  style: GoogleFonts.outfit(
                      fontSize: 11.sp, color: ColorManager.grey),
                ),
              ],
            ),
            if (analysis != null && analysis.reason.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: ColorManager.primary,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  analysis.reason,
                  style: GoogleFonts.outfit(
                    fontSize: 12.sp,
                    fontStyle: FontStyle.italic,
                    color:
                        true ? Colors.white70 : ColorManager.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(SafetyReport? report, ) {
    if (report == null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: ColorManager.primary,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: ColorManager.primary.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.insights_rounded, size: 48.sp, color: ColorManager.grey),
            SizedBox(height: 12.h),
            Text(
              'No Safety Report Yet',
              style: GoogleFonts.outfit(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: ColorManager.white,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Tap "Analyze with Iris AI" to scan your child\'s browsing history.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  fontSize: 13.sp, color: ColorManager.grey),
            ),
          ],
        ),
      );
    }

    final isGood = report.overallRiskScore < 5.0;
    final statusColor = isGood ? Colors.green : ColorManager.error;
    final statusBg = isGood ? Colors.green.withValues(alpha: 0.1) : ColorManager.error.withValues(alpha: 0.1);
    final harmfulCount = report.analyses.where((a) => a.isHarmful).length;
    final safeCount = report.analyses.where((a) => !a.isHarmful).length;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: ColorManager.primary,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: ColorManager.primary.withValues(alpha: 0.5),
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
                        color: ColorManager.grey)),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                        child: _buildStatChip(
                            '$safeCount', 'Safe Sites',
                            Colors.green.withValues(alpha: 0.1), Colors.green)),
                    SizedBox(width: 12.w),
                    Expanded(
                        child: _buildStatChip(
                            '$harmfulCount', 'Harmful Sites',
                            ColorManager.error.withValues(alpha: 0.1), ColorManager.error)),
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

  Widget _buildAnalyticsTab(SafetyReport? report, ) {
    if (report == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.h),
          child: Text(
            'Run "Analyze with Iris AI" to see charts.',
            style: GoogleFonts.outfit(
                color: ColorManager.grey, fontSize: 14.sp),
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
        BaseraRiskLineChart(weeklyScores: weeklyScores),
        SizedBox(height: 16.h),
        BaseraCategoryDonutChart(categoryCounts: categories),
      ],
    );
  }
}

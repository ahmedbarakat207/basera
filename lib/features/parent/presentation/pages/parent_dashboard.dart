import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:basera/core/resources/app_colors.dart';
import 'package:basera/core/routes_manger/routes.dart';
import 'package:basera/core/widgets/custom_button.dart';
import 'package:basera/core/widgets/main_text_field.dart';
import 'package:basera/core/utils/groq_client.dart';
import 'package:basera/features/parent/presentation/bloc/parent_bloc.dart';
import 'package:basera/features/parent/presentation/bloc/parent_event.dart';
import 'package:basera/features/parent/presentation/bloc/parent_state.dart';
import 'package:basera/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:basera/features/auth/presentation/bloc/auth_event.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  final TextEditingController _searchController = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backGround,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
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
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
            tooltip: 'Switch to Child Mode',
            onPressed: () async {
              final navigator = Navigator.of(context);
              // Switch role locally and reload
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
      body: BlocConsumer<ParentBloc, ParentState>(
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
          if (state is ParentLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ParentLoaded) {
            final children = state.children;
            final selectedChildUid = state.selectedChildUid;
            final visitedUrls = state.filteredVisitedUrls;
            final allUrls = state.allVisitedUrls;
            final latestReport = state.latestReport;
            final isAnalyzing = state.isAnalyzing;

            int harmfulCount = 0;
            int safeCount = 0;

            if (latestReport != null) {
              harmfulCount = latestReport.links.where((l) => l.isHarmful).length;
              safeCount = latestReport.links.where((l) => !l.isHarmful).length;
            }

            // Real-time alerts logic for flagged content
            final List<String> flaggedUnsafeUrls = allUrls.where((u) {
              final lower = u.toLowerCase();
              return lower.contains('gambling') ||
                  lower.contains('slots') ||
                  lower.contains('badsite') ||
                  lower.contains('violent') ||
                  lower.contains('gory');
            }).toList();

            return RefreshIndicator(
              onRefresh: () async {
                context.read<ParentBloc>().add(LoadChildrenProfiles());
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Child profile selection dropdown
                    if (children.isNotEmpty) ...[
                      Text(
                        'Select Child Profile:',
                        style: GoogleFonts.outfit(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedChildUid,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: AppColors.primary),
                            items: children.map((child) {
                              return DropdownMenuItem<String>(
                                value: child['uid'],
                                child: Text(
                                  child['name'] ?? 'Child Account',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15.sp,
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
                    _buildOverviewCard(latestReport, harmfulCount, safeCount),
                    SizedBox(height: 20.h),

                    // Flagged Content Real-time Alert Banner
                    if (flaggedUnsafeUrls.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: AppColors.redWhite,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24.sp),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'DANGER: Flagged Content Detected',
                                    style: GoogleFonts.outfit(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.sp,
                                    ),
                                  ),
                                  Text(
                                    'Child visited ${flaggedUnsafeUrls.length} potentially harmful URLs recently.',
                                    style: GoogleFonts.outfit(
                                      color: AppColors.error.withValues(alpha: 0.8),
                                      fontSize: 11.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),
                    ],

                    // Actions Row
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
                            backgroundColor: AppColors.primary,
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

                    // Search/Filter Bar
                    Text(
                      'Search & Filter browsing history',
                      style: GoogleFonts.outfit(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    BuildTextField(
                      controller: _searchController,
                      hint: 'Type domain to filter (e.g. wikipedia)...',
                      backgroundColor: AppColors.surface,
                      borderBackgroundColor: AppColors.border,
                      onChanged: (val) {
                        context.read<ParentBloc>().add(FilterUrls(query: val));
                      },
                    ),
                    SizedBox(height: 24.h),

                    // Browsing history stream list
                    Text(
                      'Monitored Browsing Activity',
                      style: GoogleFonts.outfit(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.selectedText,
                      ),
                    ),
                    SizedBox(height: 12.h),

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
                          
                          LinkAnalysis? analysis;
                          if (latestReport != null) {
                            final matches = latestReport.links.where((l) => l.url == url);
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
                            color: AppColors.surface,
                            margin: EdgeInsets.symmetric(vertical: 8.h),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              side: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
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
                                            color: AppColors.selectedText,
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
                                          hasAnalysis ? (isHarmful ? 'Harmful' : 'Safe') : 'Pending',
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
                                        color: AppColors.backGround,
                                        borderRadius: BorderRadius.circular(8.r),
                                      ),
                                      child: Text(
                                        analysis.reason,
                                        style: GoogleFonts.outfit(
                                          fontSize: 12.sp,
                                          fontStyle: FontStyle.italic,
                                          color: AppColors.selectedText,
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
                  ],
                ),
              ),
            );
          }

          return const Center(child: Text('Please select a child profile to monitor.'));
        },
      ),
    );
  }

  Widget _buildOverviewCard(SafetyReport? latestReport, int harmfulCount, int safeCount) {
    if (latestReport == null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
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
                color: AppColors.selectedText,
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

    final isGood = latestReport.status.toLowerCase().contains('good');
    final statusColor = isGood ? AppColors.success : AppColors.error;
    final statusBgColor = isGood ? AppColors.greenWhite : AppColors.redWhite;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
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
                      'Status: ${latestReport.status}',
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
                    isGood ? 'Safe Environment' : 'At Risk',
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
                    color: AppColors.selectedText,
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
}

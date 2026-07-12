import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:basera/core/resources/app_colors.dart';
import 'package:basera/core/routes_manger/routes.dart';
import 'package:basera/core/widgets/custom_button.dart';
import 'package:basera/core/utils/groq_client.dart';
import 'package:basera/core/utils/child_history_service.dart';
import 'package:basera/core/services/firebase_backend_service.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  final GroqClient _groqClient = GroqClient();
  List<String> _visitedUrls = [];
  SafetyReport? _latestReport;
  
  List<Map<String, dynamic>> _children = [];
  String? _selectedChildUid;
  StreamSubscription? _urlsSubscription;
  StreamSubscription? _reportSubscription;
  
  bool _isLoadingHistory = false;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  @override
  void dispose() {
    _urlsSubscription?.cancel();
    _reportSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadChildren() async {
    setState(() => _isLoadingHistory = true);
    try {
      final children = await FirebaseBackendService.instance.fetchChildren();
      setState(() {
        _children = children;
      });

      if (children.isNotEmpty) {
        _selectChild(children.first['uid'] ?? 'mock-child-id', children.first['name'] ?? 'Demo Child Account');
      } else {
        await _loadLocalData();
      }
    } catch (_) {
      await _loadLocalData();
    }
  }

  void _selectChild(String childUid, String childName) {
    _urlsSubscription?.cancel();
    _reportSubscription?.cancel();

    setState(() {
      _selectedChildUid = childUid;
      _isLoadingHistory = true;
    });

    _urlsSubscription = FirebaseBackendService.instance.streamChildUrls(childUid).listen((urls) {
      setState(() {
        _visitedUrls = urls;
        _isLoadingHistory = false;
      });
    }, onError: (e) {
      setState(() => _isLoadingHistory = false);
    });

    _reportSubscription = FirebaseBackendService.instance.streamChildReport(childUid).listen((report) {
      setState(() {
        _latestReport = report;
      });
    });
  }

  Future<void> _loadLocalData() async {
    final urls = await ChildHistoryService.instance.getVisitedUrls();
    final report = await ChildHistoryService.instance.getLatestReport();
    setState(() {
      _visitedUrls = urls;
      _latestReport = report;
      _isLoadingHistory = false;
    });
  }

  Future<void> _runAiAnalysis() async {
    if (_visitedUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No browsing history to analyze. Please log in as Child and visit some links.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final report = await _groqClient.analyzeUrls(_visitedUrls);
      
      final targetUid = _selectedChildUid ?? 'mock-child-id';
      await FirebaseBackendService.instance.syncSafetyReport(targetUid, report);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('AI Analysis completed successfully!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to analyze: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  Future<void> _clearHistory() async {
    await ChildHistoryService.instance.clearHistory();
    await _loadChildren();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('History and reports cleared.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int harmfulCount = 0;
    int safeCount = 0;

    if (_latestReport != null) {
      harmfulCount = _latestReport!.links.where((l) => l.isHarmful).length;
      safeCount = _latestReport!.links.where((l) => !l.isHarmful).length;
    }

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
              await ChildHistoryService.instance.setUserRole('child');
              navigator.pushReplacementNamed(Routes.mainRoute);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Log Out',
            onPressed: () async {
              final navigator = Navigator.of(context);
              await FirebaseBackendService.instance.signOut();
              navigator.pushReplacementNamed(Routes.signUpRoute);
            },
          ),
        ],
      ),
      body: _isLoadingHistory
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadChildren,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Child Selector Dropdown
                    if (_children.isNotEmpty) ...[
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
                            value: _selectedChildUid,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: AppColors.primary),
                            items: _children.map((child) {
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
                                final child = _children.firstWhere((c) => c['uid'] == uid);
                                _selectChild(uid, child['name'] ?? 'Child Account');
                              }
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                    ],
                    // Top Info Card
                    _buildOverviewCard(harmfulCount, safeCount),
                    SizedBox(height: 20.h),

                    // Actions Row
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: _isAnalyzing ? 'Analyzing...' : 'Analyze with Groq AI',
                            onPressed: _isAnalyzing ? null : _runAiAnalysis,
                            isLoading: _isAnalyzing,
                            backgroundColor: AppColors.primary,
                            textColor: Colors.white,
                            borderRadius: 12.r,
                          ),
                        ),
                        if (_visitedUrls.isNotEmpty) ...[
                          SizedBox(width: 12.w),
                          IconButton(
                            onPressed: _clearHistory,
                            icon: const Icon(Icons.delete_sweep_rounded),
                            color: AppColors.error,
                            iconSize: 28.sp,
                            tooltip: 'Clear History',
                          ),
                        ]
                      ],
                    ),
                    SizedBox(height: 24.h),

                    // Links Header
                    Text(
                      'Monitored Browsing Activity',
                      style: GoogleFonts.outfit(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.selectedText,
                      ),
                    ),
                    SizedBox(height: 10.h),

                    // Link feed list
                    _buildLinksFeed(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewCard(int harmfulCount, int safeCount) {
    if (_latestReport == null) {
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
              'Click "Analyze with Groq AI" below to evaluate your child\'s recent browsing history.',
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

    final isGood = _latestReport!.status.toLowerCase().contains('good');
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
                topLeft: Radius.circular(15.r),
                topRight: Radius.circular(15.r),
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
                      isGood ? 'Good Behavior Status' : 'Attention Required',
                      style: GoogleFonts.outfit(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    _latestReport!.status.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details Body
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Behavioral Summary:',
                  style: GoogleFonts.outfit(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  _latestReport!.summary,
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.selectedText,
                    height: 1.4.h,
                  ),
                ),
                SizedBox(height: 16.h),
                const Divider(),
                SizedBox(height: 10.h),
                // Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol('Total Links', _latestReport!.links.length.toString(), AppColors.primary),
                    _buildStatCol('Safe Links', safeCount.toString(), AppColors.success),
                    _buildStatCol('Harmful Links', harmfulCount.toString(), AppColors.error),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCol(String title, String val, Color color) {
    return Column(
      children: [
        Text(
          val,
          style: GoogleFonts.outfit(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 12.sp,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLinksFeed() {
    if (_visitedUrls.isEmpty) {
      return Container(
        height: 180.h,
        alignment: Alignment.center,
        child: Text(
          'No activity recorded for this child.',
          style: GoogleFonts.outfit(
            color: AppColors.textDisabled,
            fontSize: 14.sp,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _visitedUrls.length,
      itemBuilder: (context, index) {
        final url = _visitedUrls[index];
        LinkAnalysis? analysis;

        // Try to match the url with one of the analysed links in the report
        if (_latestReport != null) {
          final matches = _latestReport!.links.where((l) => l.url == url);
          if (matches.isNotEmpty) {
            analysis = matches.first;
          }
        }

        final hasAnalysis = analysis != null;
        final isHarmful = hasAnalysis ? analysis.isHarmful : (url.contains('gambling') || url.contains('violent') || url.contains('badsite'));
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
                      'Category: ${hasAnalysis ? analysis.category : "Unclassified"}',
                      style: GoogleFonts.outfit(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (hasAnalysis) ...[
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
                        color: AppColors.selectedText,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

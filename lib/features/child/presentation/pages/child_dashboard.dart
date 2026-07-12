import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:basera/core/resources/app_colors.dart';
import 'package:basera/core/routes_manger/routes.dart';
import 'package:basera/core/widgets/custom_button.dart';
import 'package:basera/core/widgets/main_text_field.dart';
import 'package:basera/core/utils/child_history_service.dart';
import 'package:basera/core/services/firebase_backend_service.dart';

class ChildDashboard extends StatefulWidget {
  const ChildDashboard({super.key});

  @override
  State<ChildDashboard> createState() => _ChildDashboardState();
}

class _ChildDashboardState extends State<ChildDashboard> {
  final _urlController = TextEditingController();
  List<String> _visitedUrls = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final urls = await ChildHistoryService.instance.getVisitedUrls();
    setState(() {
      _visitedUrls = urls;
      _isLoading = false;
    });
  }

  Future<void> _addCustomUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    // Basic URL validation helper
    String validatedUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      validatedUrl = 'https://$url';
    }

    await FirebaseBackendService.instance.syncUrlVisit(validatedUrl);
    _urlController.clear();
    _loadHistory();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Simulated visit to $validatedUrl'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _addQuickUrl(String url, String name) async {
    await FirebaseBackendService.instance.syncUrlVisit(url);
    _loadHistory();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Simulated visit to $name'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _clearHistory() async {
    await ChildHistoryService.instance.clearHistory();
    _loadHistory();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cleared history'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backGround,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
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
              await ChildHistoryService.instance.setUserRole('parent');
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
      body: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28.r,
                    backgroundColor: AppColors.lightBlue,
                    child: Text(
                      '👦',
                      style: TextStyle(fontSize: 28.sp),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hey there, Kiddo!',
                          style: GoogleFonts.outfit(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.selectedText,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Your browsing is monitored to keep you safe online.',
                          style: GoogleFonts.outfit(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // URL Input Section
            Text(
              'Visit a Website',
              style: GoogleFonts.outfit(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.selectedText,
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: BuildTextField(
                    controller: _urlController,
                    hint: 'google.com or https://example.com',
                    backgroundColor: AppColors.surface,
                    borderBackgroundColor: AppColors.border,
                  ),
                ),
                SizedBox(width: 12.w),
                CustomButton(
                  text: 'Visit',
                  onPressed: _addCustomUrl,
                  width: 80.w,
                  height: 48.h,
                  backgroundColor: AppColors.primary,
                  textColor: Colors.white,
                  borderRadius: 10.r,
                  elevation: 2,
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // Quick simulation presets
            Text(
              'Test Links (Quick Preset Simulations)',
              style: GoogleFonts.outfit(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                _buildQuickPreset(
                  'Wikipedia',
                  'https://en.wikipedia.org/wiki/Dinosaur',
                  Colors.blue.shade100,
                  Colors.blue.shade900,
                ),
                _buildQuickPreset(
                  'Duolingo',
                  'https://www.duolingo.com',
                  Colors.green.shade100,
                  Colors.green.shade900,
                ),
                _buildQuickPreset(
                  'Scratch',
                  'https://scratch.mit.edu',
                  Colors.orange.shade100,
                  Colors.orange.shade900,
                ),
                _buildQuickPreset(
                  'Casino / Slots ⚠️',
                  'https://www.freeonlinegamblingweb.com/slots',
                  Colors.red.shade100,
                  Colors.red.shade900,
                ),
                _buildQuickPreset(
                  'Adult Games ⚠️',
                  'https://www.badsite-violent-games.com/gory-shooter',
                  Colors.red.shade100,
                  Colors.red.shade900,
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Visited links history
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recently Visited Links (${_visitedUrls.length})',
                  style: GoogleFonts.outfit(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.selectedText,
                  ),
                ),
                if (_visitedUrls.isNotEmpty)
                  TextButton(
                    onPressed: _clearHistory,
                    child: Text(
                      'Clear History',
                      style: GoogleFonts.outfit(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _visitedUrls.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history_rounded,
                                size: 48.sp,
                                color: AppColors.textDisabled,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'No links visited yet.',
                                style: GoogleFonts.outfit(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: _visitedUrls.length,
                          itemBuilder: (context, index) {
                            final url = _visitedUrls[index];
                            final isHarmfulDemo = url.contains('gambling') || url.contains('violent') || url.contains('badsite');
                            return Card(
                              color: AppColors.surface,
                              elevation: 0,
                              margin: EdgeInsets.symmetric(vertical: 6.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                side: BorderSide(
                                  color: AppColors.border.withValues(alpha: 0.3),
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
                                        : AppColors.primary,
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

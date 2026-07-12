import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  void initState() {
    super.initState();
    context.read<ChildBloc>().add(LoadChildHistory());
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _addCustomUrl() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    // Basic URL validation helper
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
                              'Child Simulator Mode',
                              style: GoogleFonts.outfit(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.selectedText,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Visit simulated links to generate safe/unsafe activity streams.',
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
                SizedBox(height: 24.h),

                // Simulated URL search bar
                Text(
                  'Simulate Visiting a Website',
                  style: GoogleFonts.outfit(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.selectedText,
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: BuildTextField(
                        controller: _urlController,
                        hint: 'Enter domain (e.g. google.com)',
                        backgroundColor: AppColors.surface,
                        borderBackgroundColor: AppColors.border,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    CustomButton(
                      text: 'Go',
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _addCustomUrl,
                      height: 52.h,
                      width: 70.w,
                      backgroundColor: AppColors.primary,
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
                    color: AppColors.textSecondary,
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
                      AppColors.greenWhite,
                      Colors.green.shade700,
                    ),
                    _buildQuickPreset(
                      'Duolingo',
                      'https://www.duolingo.com',
                      AppColors.greenWhite,
                      Colors.green.shade700,
                    ),
                    _buildQuickPreset(
                      'Khan Academy',
                      'https://www.khanacademy.org',
                      AppColors.greenWhite,
                      Colors.green.shade700,
                    ),
                    _buildQuickPreset(
                      'Scratch MIT',
                      'https://www.scratch.mit.edu',
                      AppColors.greenWhite,
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
                        color: AppColors.selectedText,
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
                                url.contains('violent') ||
                                url.contains('badsite') ||
                                url.contains('slots');
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

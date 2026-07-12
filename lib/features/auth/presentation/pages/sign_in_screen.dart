import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:basera/core/resources/app_colors.dart';
import 'package:basera/core/routes_manger/routes.dart';
import 'package:basera/core/widgets/custom_button.dart';
import 'package:basera/core/widgets/main_text_field.dart';
import 'package:basera/core/services/firebase_backend_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await FirebaseBackendService.instance.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (mounted) {
          Navigator.pushReplacementNamed(context, Routes.mainRoute);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login failed: ${e.toString()}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backGround,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 50.h),
                Center(
                  child: Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_open_rounded,
                      size: 48.sp,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Center(
                  child: Text(
                    'Basera Safety',
                    style: GoogleFonts.outfit(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryVariant,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    'Sign in to access your parent or child dashboard',
                    style: GoogleFonts.outfit(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                SizedBox(height: 50.h),
                Text(
                  'Sign In',
                  style: GoogleFonts.outfit(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.selectedText,
                  ),
                ),
                SizedBox(height: 16.h),
                BuildTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hint: 'parent@demo.com or child@demo.com',
                  backgroundColor: AppColors.surface,
                  borderBackgroundColor: AppColors.border,
                  textInputType: TextInputType.emailAddress,
                  validation: (val) {
                    if (val == null || val.isEmpty) return 'Please enter your email';
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
                BuildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: '••••••••',
                  isObscured: true,
                  backgroundColor: AppColors.surface,
                  borderBackgroundColor: AppColors.border,
                  validation: (val) => val == null || val.isEmpty ? 'Please enter your password' : null,
                ),
                SizedBox(height: 10.h),
                SizedBox(height: 16.h),
                Text(
                  'Demo Quick Access (Tap to Auto-Login)',
                  style: GoogleFonts.outfit(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Expanded(
                      child: ActionChip(
                        backgroundColor: AppColors.lightBlue,
                        avatar: const Icon(Icons.supervisor_account_rounded, color: AppColors.primary, size: 18),
                        label: Text(
                          'Parent Demo',
                          style: GoogleFonts.outfit(
                            color: AppColors.primaryVariant,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                        onPressed: () {
                          _emailController.text = 'parent@basera.com';
                          _passwordController.text = 'parentpassword123';
                          _submit();
                        },
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ActionChip(
                        backgroundColor: Colors.green.shade50,
                        avatar: Icon(Icons.child_care_rounded, color: Colors.green.shade800, size: 18),
                        label: Text(
                          'Child Demo',
                          style: GoogleFonts.outfit(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                        onPressed: () {
                          _emailController.text = 'child@basera.com';
                          _passwordController.text = 'childpassword123';
                          _submit();
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30.h),
                Center(
                  child: CustomButton(
                    text: 'Sign In',
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _submit,
                    width: double.infinity,
                    height: 52.h,
                    backgroundColor: AppColors.primary,
                    textColor: Colors.white,
                    borderRadius: 12.r,
                  ),
                ),
                SizedBox(height: 24.h),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, Routes.signUpRoute);
                    },
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have an account? ",
                        style: GoogleFonts.outfit(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                        children: [
                          TextSpan(
                            text: 'Sign Up',
                            style: GoogleFonts.outfit(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

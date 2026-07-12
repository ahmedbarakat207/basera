import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:basera/core/resources/assets_manager.dart';
import 'package:basera/core/resources/color_manager.dart';
import 'package:basera/core/resources/styles_manager.dart';
import 'package:basera/core/resources/values_manager.dart';
import 'package:basera/core/routes_manger/routes.dart';
import 'package:basera/core/widgets/main_botton.dart';
import 'package:basera/core/widgets/main_text_field.dart';
import 'package:basera/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:basera/features/auth/presentation/bloc/auth_event.dart';
import 'package:basera/features/auth/presentation/bloc/auth_state.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedRole = 'parent'; // default role

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthSignUpRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
          role: _selectedRole,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.primary,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            Navigator.pushReplacementNamed(context, Routes.mainRoute);
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message, style: StylesManager.lableLine().copyWith(color: ColorManager.white)),
                behavior: SnackBarBehavior.floating,
                backgroundColor: ColorManager.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppPadding.p24, vertical: AppPadding.p20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20.h),
                    Center(
                      child: Image.asset(
                        ImageAssets.logo,
                        height: 80.h,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.security, size: 60.sp, color: ColorManager.white),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Create Account',
                            style: StylesManager.headerSignLine(),
                          ),
                        ),
                        TextButton(
                          onPressed: isLoading ? null : () {
                            Navigator.pushReplacementNamed(context, Routes.signInRoute);
                          },
                          child: Text(
                            'Sign In',
                            style: StylesManager.descriptionLine().copyWith(
                              color: ColorManager.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    BuildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'Enter your name',
                      backgroundColor: ColorManager.primary,
                      borderBackgroundColor: ColorManager.grey,
                      labelTextStyle: StylesManager.lableLine().copyWith(color: ColorManager.white),
                      cursorColor: ColorManager.white,
                      validation: (val) => val == null || val.isEmpty ? 'Please enter your name' : null,
                    ),
                    SizedBox(height: 16.h),
                    BuildTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      hint: 'Enter your email',
                      backgroundColor: ColorManager.primary,
                      borderBackgroundColor: ColorManager.grey,
                      labelTextStyle: StylesManager.lableLine().copyWith(color: ColorManager.white),
                      textInputType: TextInputType.emailAddress,
                      cursorColor: ColorManager.white,
                      validation: (val) {
                        if (val == null || val.isEmpty) return 'Please enter your email';
                        if (!val.contains('@')) return 'Enter a valid email address';
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),
                    BuildTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: '••••••••',
                      isObscured: true,
                      backgroundColor: ColorManager.primary,
                      borderBackgroundColor: ColorManager.grey,
                      labelTextStyle: StylesManager.lableLine().copyWith(color: ColorManager.white),
                      cursorColor: ColorManager.white,
                      validation: (val) => val != null && val.length < 6 ? 'Password must be at least 6 characters' : null,
                    ),
                    SizedBox(height: 24.h),
                    
                    Text(
                      'Choose Your Role',
                      style: StylesManager.lableLine().copyWith(color: ColorManager.white),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildRoleCard(
                            role: 'parent',
                            title: 'Parent',
                            description: 'Monitor safety',
                            icon: Icons.supervisor_account_rounded,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: _buildRoleCard(
                            role: 'child',
                            title: 'Child',
                            description: 'Simulate browsing',
                            icon: Icons.child_care_rounded,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 40.h),
                    Center(
                      child: isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : MainAppButton(
                            text: 'Sign Up',
                            textStyle: StylesManager.mediumLine(),
                            onTap: _submit,
                          ),
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: isSelected ? ColorManager.grey.withOpacity(0.3) : ColorManager.primary,
          borderRadius: BorderRadius.circular(AppSize.s16),
          border: Border.all(
            color: isSelected ? ColorManager.white : ColorManager.grey,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32.sp,
              color: isSelected ? ColorManager.white : ColorManager.grey,
            ),
            SizedBox(height: 8.h),
            Text(
              title,
              style: StylesManager.lableLine().copyWith(
                color: isSelected ? ColorManager.white : ColorManager.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              description,
              textAlign: TextAlign.center,
              style: StylesManager.litlleHintLine(),
            ),
          ],
        ),
      ),
    );
  }
}

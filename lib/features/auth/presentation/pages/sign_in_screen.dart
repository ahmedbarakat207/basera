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

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthLoginRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
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
              padding: const EdgeInsets.symmetric(horizontal: AppSize.s24, vertical: AppPadding.p20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 50.h),
                    Center(
                      child: Image.asset(
                        ImageAssets.basseraLogo, // "assets/images/bassera_logo.png" defined in assets_manager
                        height: 120.h,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.security, size: 80.sp, color: ColorManager.white),
                      ),
                    ),
                    SizedBox(height: 40.h),
                    Text(
                      'Sign In',
                      style: StylesManager.headerSignLine(),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Welcome back to Basera Safety',
                      style: StylesManager.descriptionLine(),
                    ),
                    SizedBox(height: 30.h),
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
                      validation: (val) => val == null || val.isEmpty ? 'Please enter your password' : null,
                    ),
                    SizedBox(height: 24.h),
                    
                    // Demo Chips using new styling
                    Text(
                      'Demo Quick Access (Local & Cloud)',
                      style: StylesManager.descriptionLine().copyWith(color: ColorManager.white),
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: isLoading ? null : () {
                              _emailController.text = 'parent@basera.com';
                              _passwordController.text = 'parentpassword123';
                              _submit();
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              decoration: BoxDecoration(
                                color: ColorManager.grey.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(AppSize.s12),
                                border: Border.all(color: ColorManager.grey),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.supervisor_account, color: ColorManager.white, size: 18.sp),
                                  SizedBox(width: 8.w),
                                  Text('Parent Demo', style: StylesManager.litlleHintLine().copyWith(color: ColorManager.white)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: InkWell(
                            onTap: isLoading ? null : () {
                              _emailController.text = 'child@basera.com';
                              _passwordController.text = 'childpassword123';
                              _submit();
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              decoration: BoxDecoration(
                                color: ColorManager.grey.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(AppSize.s12),
                                border: Border.all(color: ColorManager.grey),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.child_care, color: ColorManager.white, size: 18.sp),
                                  SizedBox(width: 8.w),
                                  Text('Child Demo', style: StylesManager.litlleHintLine().copyWith(color: ColorManager.white)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 40.h),
                    Center(
                      child: isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : MainAppButton(
                            text: 'Sign In',
                            textStyle: StylesManager.mediumLine(),
                            onTap: _submit,
                          ),
                    ),
                    SizedBox(height: 24.h),
                    Center(
                      child: GestureDetector(
                        onTap: isLoading ? null : () {
                          Navigator.pushReplacementNamed(context, Routes.signUpRoute);
                        },
                        child: RichText(
                          text: TextSpan(
                            text: "Don't have an account? ",
                            style: StylesManager.descriptionLine(),
                            children: [
                              TextSpan(
                                text: 'Sign Up',
                                style: StylesManager.descriptionLine().copyWith(
                                  color: ColorManager.white,
                                  fontWeight: FontWeight.bold,
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
          );
        },
      ),
    );
  }
}

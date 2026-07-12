import 'package:basera/core/resources/assets_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../resources/color_manager.dart';
import '../resources/styles_manager.dart';
import '../resources/values_manager.dart';

class BuildTextField extends StatefulWidget {
  const BuildTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.nextFocus,
    this.label,
    this.hint,
    this.isObscured = false,
    this.iconData,
    this.textInputType = TextInputType.text,
    this.backgroundColor,
    this.hintTextStyle,
    this.labelTextStyle,
    this.cursorColor,
    this.readOnly = false,
    this.validation,
    this.onTap,
    this.maxLines,
    this.prefixIcon,
    this.borderBackgroundColor,
    this.suffixIcon,
    this.borderradius,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;
  final bool isObscured;
  final String? label;
  final String? hint;
  final TextInputType textInputType;
  final IconData? iconData;
  final Color? backgroundColor;
  final Color? borderBackgroundColor;
  final TextStyle? hintTextStyle;
  final TextStyle? labelTextStyle;
  final Color? cursorColor;
  final bool readOnly;
  final int? maxLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validation;
  final void Function()? onTap;
  final double? borderradius;

  @override
  State<BuildTextField> createState() => _BuildTextFieldState();
}

class _BuildTextFieldState extends State<BuildTextField> {
  late bool hidden = widget.isObscured;
  String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.label != null
            ? Padding(
                padding: const EdgeInsets.only(top: AppPadding.p2),
                child: Text(
                  widget.label!,
                  style: widget.labelTextStyle ?? StylesManager.lableLine(),
                ),
              )
            : const SizedBox(),
        Container(
          margin: const EdgeInsets.only(top: AppMargin.m5),
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? ColorManager.grey,
            borderRadius: BorderRadius.circular(
              widget.borderradius ?? AppSize.s8,
            ),
            border: Border.all(
              color: widget.borderBackgroundColor ?? ColorManager.transparent,
            ),
          ),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: TextFormField(
            maxLines: widget.maxLines ?? 1,
            controller: widget.controller,
            focusNode: widget.focusNode,
            readOnly: widget.readOnly,
            style: StylesManager.lableLine(),
            obscureText: hidden,
            keyboardType: widget.textInputType,
            obscuringCharacter: '*',
            cursorColor: widget.cursorColor ?? ColorManager.black,
            onTap: widget.onTap,
            onEditingComplete: () {
              widget.focusNode?.unfocus();
              if (widget.nextFocus != null) {
                FocusScope.of(context).requestFocus(widget.nextFocus);
              }
            },
            textInputAction: widget.nextFocus == null
                ? TextInputAction.done
                : TextInputAction.next,
            validator: (value) {
              if (widget.validation == null) {
                setState(() {
                  errorText = null;
                });
              } else {
                setState(() {
                  errorText = widget.validation!(value);
                });
              }
              return errorText;
            },
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(AppPadding.p12),
              hintText: widget.hint,
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.isObscured
                  ? IconButton(
                      onPressed: () {
                        setState(() {
                          hidden = !hidden;
                        });
                      },
                      iconSize: AppSize.s24,
                      splashRadius: AppSize.s1,
                      isSelected: !hidden,
                      color: widget.cursorColor,
                      selectedIcon: const Icon(Icons.remove_red_eye_rounded),
                      icon: SvgPicture.asset(SvgAssets.eye),
                    )
                  : widget.suffixIcon,
              hintStyle: widget.hintTextStyle ?? StylesManager.hintLine(),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorStyle: TextStyle(
                fontSize: AppSize.s0,
                color: ColorManager.transparent,
              ),
            ),
          ),
        ),
        errorText == null
            ? const SizedBox()
            : Padding(
                padding: const EdgeInsets.only(
                  top: AppPadding.p8,
                  left: AppPadding.p8,
                ),
                child: Text(errorText!, style: StylesManager.lableLine()),
              ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';

class AuthScaffold extends StatelessWidget {
  final Widget child;

  final bool showBack;

  const AuthScaffold({super.key, required this.child, this.showBack = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _AuthLogoBar(showBack: showBack),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: SizedBox(width: double.infinity, child: child),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthLogoBar extends StatelessWidget {
  final bool showBack;
  const _AuthLogoBar({required this.showBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.wood900,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 72,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                'asmorobangun',
                style: logoStyle(size: 30, color: AppColors.cream100),
              ),
              if (showBack)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    tooltip: 'Kembali',
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.cream100,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthHeading extends StatelessWidget {
  final String title, subtitle;
  const AuthHeading(this.title, this.subtitle, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: headingStyle(size: 34),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.wood700,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
}

class AuthField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? helperText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enableSuggestions;
  final bool autocorrect;

  final bool boldLabel;
  final int? minLines;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;

  final Widget? trailing;

  final bool obscureText;

  final VoidCallback? onToggleObscure;

  const AuthField({
    super.key,
    required this.label,
    this.hint,
    this.helperText,
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.enableSuggestions = true,
    this.autocorrect = true,
    this.boldLabel = true,
    this.minLines,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.trailing,
    this.obscureText = false,
    this.onToggleObscure,
  });

  OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.wood700,
              fontSize: boldLabel ? 15 : 14,
              fontWeight: boldLabel ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            textCapitalization: textCapitalization,
            autofillHints: autofillHints,
            inputFormatters: inputFormatters,
            validator: validator,
            onChanged: onChanged,
            onFieldSubmitted: onFieldSubmitted,
            enableSuggestions: enableSuggestions,
            autocorrect: autocorrect,
            obscureText: obscureText,
            minLines: minLines,
            maxLines: maxLines,
            readOnly: readOnly,
            onTap: onTap,
            style: const TextStyle(color: AppColors.ink, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppColors.wood700.withAlpha(140),
                fontSize: 14,
              ),
              helperText: helperText,
              helperStyle: const TextStyle(
                color: AppColors.inkSoft,
                fontSize: 12,
              ),
              helperMaxLines: 2,
              errorMaxLines: 3,
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: _border(AppColors.wood700),
              enabledBorder: _border(AppColors.wood700),
              focusedBorder: _border(AppColors.wood700, 2),
              errorBorder: _border(AppColors.danger),
              focusedErrorBorder: _border(AppColors.danger, 2),
              suffixIcon: onToggleObscure == null
                  ? trailing
                  : IconButton(
                      tooltip: obscureText ? 'Tampilkan' : 'Sembunyikan',
                      icon: Icon(
                        obscureText
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.wood700,
                      ),
                      onPressed: onToggleObscure,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback onPressed;

  const AuthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.wood800,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.wood800,
          disabledForegroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        onPressed: busy ? null : onPressed,
        child: busy
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}

class AuthLink extends StatelessWidget {
  final String lead, action;
  final VoidCallback? onTap;

  const AuthLink({
    super.key,
    required this.lead,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: Text.rich(
              TextSpan(
                text: '$lead ',
                style: const TextStyle(
                  color: AppColors.wood700,
                  fontSize: 15,
                ),
                children: [
                  TextSpan(
                    text: action,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
}

class AuthErrorBanner extends StatelessWidget {
  final String message;
  const AuthErrorBanner(this.message, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF4D9D9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          message,
          style: const TextStyle(
            color: AppColors.danger,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}
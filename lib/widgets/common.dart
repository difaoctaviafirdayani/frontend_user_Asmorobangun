import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config.dart';
import '../core/format.dart';
import '../core/theme.dart';

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.wood900,
    ));
}

Future<void> openUrl(BuildContext context, String url) async {
  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) showSnack(context, 'Tidak bisa membuka tautan.');
}

String waUrl([String? text]) =>
    'https://wa.me/${AppConfig.adminWhatsapp}${text == null ? '' : '?text=${Uri.encodeComponent(text)}'}';

Future<bool> confirmDialog(BuildContext context, String message, {String okLabel = 'Ya'}) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.cream100,
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(okLabel)),
      ],
    ),
  );
  return res == true;
}

class ShellScope extends InheritedWidget {
  final VoidCallback goHome;
  const ShellScope({super.key, required this.goHome, required super.child});

  @override
  bool updateShouldNotify(ShellScope oldWidget) => false;
}

Widget? appBarBack(BuildContext context) {
  if (Navigator.canPop(context)) return null;
  final shell = context.dependOnInheritedWidgetOfExactType<ShellScope>();
  if (shell == null) return null;
  return IconButton(
    tooltip: 'Kembali',
    icon: const Icon(Icons.arrow_back),
    onPressed: shell.goHome,
  );
}

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  const AppScaffold({super.key, required this.title, required this.body, this.actions, this.floatingActionButton, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    final Widget? leading = appBarBack(context) ??
        (Navigator.canPop(context)
            ? IconButton(
                tooltip: 'Kembali',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.maybePop(context),
              )
            : null);
    final hasLeading = leading != null;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: leading,
        leadingWidth: hasLeading ? 52 : null,
        titleSpacing: hasLeading ? 4 : 16,
        title: Text(title, style: headingStyle(size: 22, color: AppColors.cream100)),
        backgroundColor: AppColors.wood900,
        foregroundColor: AppColors.cream100,
        elevation: 0,
        actions: actions,
      ),
      floatingActionButton: floatingActionButton,
      body: body,
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.margin, this.onTap, this.color, this.borderColor});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? AppColors.cream100,
        borderRadius: radius,
        border: Border.all(color: borderColor ?? AppColors.line, width: borderColor == null ? 1 : 1.2),
        boxShadow: const [BoxShadow(color: Color(0x142A1E10), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          color: Colors.transparent,
          child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
        ),
      ),
    );
  }
}

class NetImage extends StatelessWidget {
  final String? src;
  final double? width, height;
  final BoxFit fit;
  final BorderRadius? radius;
  const NetImage({super.key, this.src, this.width, this.height, this.fit = BoxFit.cover, this.radius});

  Widget _placeholder() => Container(
        width: width,
        height: height,
        color: AppColors.cream300,
        alignment: Alignment.center,
        child: const Icon(Icons.image_outlined, color: AppColors.inkSoft),
      );

  Widget _image() {
    final s = src ?? '';
    if (s.isEmpty) return _placeholder();
        if (s.startsWith('assets/')) {
      return Image.asset(
        s,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    if (s.startsWith('data:')) {
      try {
        return Image.memory(
          base64Decode(s.substring(s.indexOf(',') + 1)),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      } catch (_) {
        return _placeholder();
      }
    }
    return Image.network(
      assetUrl(s),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => _placeholder(),
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : Container(width: width, height: height, color: AppColors.cream200),
    );
  }

  @override
  Widget build(BuildContext context) {
    final img = _image();
    return radius == null ? img : ClipRRect(borderRadius: radius!, child: img);
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_outlined, size: 40, color: AppColors.inkSoft),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.inkSoft)),
            const SizedBox(height: 14),
            OutlinedButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ]),
        ),
      );
}

class EmptyState extends StatelessWidget {
  final String text;
  final IconData icon;
  const EmptyState(this.text, {super.key, this.icon = Icons.inbox_outlined});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 36, color: AppColors.inkSoft),
            const SizedBox(height: 8),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.inkSoft)),
          ]),
        ),
      );
}

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final (label, color) = statusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(36), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

class NoticeBox extends StatelessWidget {
  final Widget child;
  const NoticeBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFFBEECC), borderRadius: BorderRadius.circular(14)),
        child: child,
      );
}
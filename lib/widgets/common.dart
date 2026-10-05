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

/// Scaffold standar halaman dalam dengan app bar coklat tua.
class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  const AppScaffold({super.key, required this.title, required this.body, this.actions, this.floatingActionButton});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
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
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.margin, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? AppColors.cream100,
        borderRadius: radius,
        border: Border.all(color: AppColors.line),
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

class AsyncView<T> extends StatefulWidget {
  final Future<T> Function() loader;
  final Widget Function(BuildContext context, T data, VoidCallback reload) builder;
  const AsyncView({super.key, required this.loader, required this.builder});

  @override
  State<AsyncView<T>> createState() => _AsyncViewState<T>();
}

class _AsyncViewState<T> extends State<AsyncView<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loader();
  }

  void _reload() => setState(() => _future = widget.loader());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(
            child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppColors.gold400)),
          );
        }
        if (snap.hasError) return ErrorView(message: snap.error.toString(), onRetry: _reload);
        return widget.builder(context, snap.data as T, _reload);
      },
    );
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

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const SectionHeader(this.title, {super.key, this.onSeeAll});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
        child: Row(children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.wood900))),
          if (onSeeAll != null) TextButton(onPressed: onSeeAll, child: const Text('Lihat semua')),
        ]),
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

class TagChip extends StatelessWidget {
  final String text;
  final bool gold;
  const TagChip(this.text, {super.key, this.gold = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: gold ? AppColors.gold400 : AppColors.cream300,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: gold ? AppColors.wood950 : AppColors.wood800)),
      );
}

class StarsRow extends StatelessWidget {
  final double value;
  final double size;
  const StarsRow(this.value, {super.key, this.size = 16});

  @override
  Widget build(BuildContext context) {
    final r = value.round();
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 1; i <= 5; i++)
        Icon(Icons.star_rounded, size: size, color: i <= r ? AppColors.gold400 : AppColors.cream300),
    ]);
  }
}

class KeyValueRow extends StatelessWidget {
  final String label, value;
  const KeyValueRow(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 4, child: Text(label, style: const TextStyle(color: AppColors.inkSoft, fontSize: 13))),
          Expanded(flex: 6, child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ]),
      );
}

/// Kotak informasi kuning untuk ajakan login.
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

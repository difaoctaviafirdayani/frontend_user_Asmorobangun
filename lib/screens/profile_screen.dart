import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth_state.dart';
import '../core/picker.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../repositories/auth_repository.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../widgets/common.dart';
import 'auth_screens.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    if (!auth.isLoggedIn) return const LoginScreen(embedded: true);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        titleSpacing: 20,
        title: Text('Akun Saya', style: headingStyle(size: 20, color: AppColors.cream100)),
        backgroundColor: AppColors.wood900,
        foregroundColor: AppColors.cream100,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ChangeNotifierProvider(
        create: (c) => ProfileViewModel(c.read<AuthRepository>(), c.read<AuthState>()),
        child: const _ProfileBody(),
      ),
    );
  }
}

class _ProfileBody extends StatefulWidget {
  const _ProfileBody();

  @override
  State<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<_ProfileBody> {
  Future<void> _changeAvatar() async {
    final vm = context.read<ProfileViewModel>();
    final f = await pickValidImage(context, allowGif: false);
    if (f == null) return;
    final ok = await vm.changeAvatar(f);
    if (!mounted) return;
    showSnack(context, ok ? 'Foto profil diperbarui.' : (vm.error ?? 'Terjadi kesalahan. Coba lagi.'));
  }

  Future<void> _removeAvatar() async {
    if (!await confirmDialog(context, 'Hapus foto profil?', okLabel: 'Hapus')) return;
    if (!mounted) return;
    final vm = context.read<ProfileViewModel>();
    final ok = await vm.removeAvatar();
    if (!ok && mounted) showSnack(context, vm.error ?? 'Terjadi kesalahan. Coba lagi.');
  }

  Future<void> _logout() async {
    if (!await confirmDialog(context, 'Keluar dari akun ini?', okLabel: 'Keluar')) return;
    await context.read<AuthState>().logout();
  }

  Widget _menuRow({required Widget icon, required Widget label, VoidCallback? onTap}) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(children: [
            SizedBox(width: 28, child: Center(child: icon)),
            const SizedBox(width: 12),
            Expanded(child: label),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    final user = context.watch<AuthState>().user!;
    final hasAvatar = (user.avatar ?? '').isNotEmpty;
    final initial = user.name.trim().isEmpty ? '?' : user.name.trim()[0].toUpperCase();
    const menuText = TextStyle(fontSize: 14, color: AppColors.wood900);
    return ListView(padding: const EdgeInsets.fromLTRB(24, 20, 24, 24), children: [
      Center(
        child: Stack(clipBehavior: Clip.none, children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.wood700,
            child: hasAvatar
                ? ClipOval(child: NetImage(src: user.avatar, width: 96, height: 96))
                : Text(initial, style: const TextStyle(fontSize: 34, color: Colors.white, fontWeight: FontWeight.w500)),
          ),
          Positioned(
            right: 0,
            bottom: 2,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(side: BorderSide(color: AppColors.line)),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: vm.busy ? null : _changeAvatar,
                child: const Padding(padding: EdgeInsets.all(5), child: Icon(Icons.edit_outlined, size: 14, color: AppColors.wood700)),
              ),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 10),
      Center(child: Text(user.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.wood900))),
      Center(child: Text(user.email, style: const TextStyle(fontSize: 12, color: AppColors.wood800))),
      if (hasAvatar)
        Center(
          child: TextButton(
            onPressed: vm.busy ? null : _removeAvatar,
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact, textStyle: const TextStyle(fontSize: 12)),
            child: const Text('Hapus foto profil'),
          ),
        ),
      if (vm.busy) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator(color: AppColors.wood700)),
      const SizedBox(height: 20),
      if (user.role == 'admin')
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: NoticeBox(child: Text('Kamu masuk sebagai admin sanggar. Untuk mengelola data, gunakan dashboard admin di web.')),
        ),
      _menuRow(
        icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.wood900, size: 24),
        label: const Text('Pesanan Saya', style: menuText),
        onTap: () => Navigator.pushNamed(context, Routes.myOrders),
      ),
      const Divider(height: 1, thickness: 1, color: AppColors.wood700),
      _menuRow(
        icon: const _WhatsappIcon(color: AppColors.wood900, size: 26),
        label: const Text('Hubungi Admin (WhatsApp)', style: TextStyle(fontSize: 14, color: AppColors.wood900, decoration: TextDecoration.underline, decorationColor: AppColors.wood900)),
        onTap: () => openUrl(context, waUrl()),
      ),
      const Divider(height: 1, thickness: 1, color: AppColors.line),
      _menuRow(
        icon: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 24),
        label: const Text('Keluar', style: TextStyle(fontSize: 14, color: AppColors.danger)),
        onTap: _logout,
      ),
    ]);
  }
}

class _WhatsappIcon extends StatelessWidget {
  final Color color;
  final double size;
  const _WhatsappIcon({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Stack(alignment: Alignment.center, children: [
          CustomPaint(size: Size.square(size), painter: _BubblePainter(color)),
          Icon(Icons.phone, size: size * 0.5, color: color),
        ]),
      );
}

class _BubblePainter extends CustomPainter {
  final Color color;
  _BubblePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 1.5;
    final rect = Rect.fromCircle(center: c, radius: r);
    const start = 160 * math.pi / 180;
    const sweep = 310 * math.pi / 180;
    final a = Offset(c.dx + r * math.cos(start), c.dy + r * math.sin(start));
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..arcTo(rect, start, sweep, false)
      ..lineTo(c.dx - r * 1.05, c.dy + r * 1.05)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.color != color;
}
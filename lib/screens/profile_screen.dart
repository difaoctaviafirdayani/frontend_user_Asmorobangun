import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api.dart';
import '../core/auth_state.dart';
import '../core/picker.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'auth_screens.dart';
import 'search_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    if (!auth.isLoggedIn) return const LoginScreen(embedded: true);
    return Scaffold(
      appBar: AppBar(
        leading: appBarBack(context),
        title: const Text('Akun', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.wood900,
        foregroundColor: AppColors.cream100,
        elevation: 0,
        actions: [searchAction(context)],
      ),
      body: const _ProfileBody(),
    );
  }
}

class _ProfileBody extends StatefulWidget {
  const _ProfileBody();

  @override
  State<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<_ProfileBody> {
  bool _busy = false;
  static const _maxAvatarBytes = 3 * 1024 * 1024; // sama dengan batas server (3MB)

  Future<void> _changeAvatar() async {
    final f = await pickImageFile();
    if (f == null) return;
    // Lapisan 1: validasi UI (ukuran) sebelum mengunggah
    if (f.bytes.length > _maxAvatarBytes) {
      if (mounted) showSnack(context, 'Ukuran foto maksimal 3MB.');
      return;
    }
    setState(() => _busy = true);
    try {
      // Lapisan 2/3/4: server memeriksa token, tipe & ukuran file, lalu hanya mengubah akun pemilik token
      final res = await api.upload('/auth/me/avatar', field: 'avatar', bytes: f.bytes, filename: f.name);
      if (!mounted) return;
      await context.read<AuthState>().setUserFromResponse(res);
      if (mounted) showSnack(context, 'Foto profil diperbarui.');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeAvatar() async {
    if (!await confirmDialog(context, 'Hapus foto profil?', okLabel: 'Hapus')) return;
    setState(() => _busy = true);
    try {
      final res = await api.delete('/auth/me/avatar');
      if (!mounted) return;
      await context.read<AuthState>().setUserFromResponse(res);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logout() async {
    if (!await confirmDialog(context, 'Keluar dari akun ini?', okLabel: 'Keluar')) return;
    // Token dihapus dari penyimpanan terenkripsi. Pembersihan tumpukan halaman
    // ditangani listener di main.dart (pushNamedAndRemoveUntil).
    await context.read<AuthState>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().user!;
    final hasAvatar = (user.avatar ?? '').isNotEmpty;
    final initial = user.name.trim().isEmpty ? '?' : user.name.trim()[0].toUpperCase();
    return ListView(padding: const EdgeInsets.all(16), children: [
      AppCard(
        child: Column(children: [
          const SizedBox(height: 4),
          Stack(alignment: Alignment.bottomRight, children: [
            CircleAvatar(
              radius: 46,
              backgroundColor: AppColors.wood800,
              child: hasAvatar
                  ? ClipOval(child: NetImage(src: user.avatar, width: 92, height: 92))
                  : Text(initial, style: const TextStyle(fontSize: 34, color: AppColors.gold300, fontWeight: FontWeight.w800)),
            ),
            Material(
              color: AppColors.gold400,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _busy ? null : _changeAvatar,
                child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.camera_alt_outlined, size: 18, color: AppColors.wood950)),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Text(user.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.wood900)),
          const SizedBox(height: 2),
          Text(user.email, style: const TextStyle(color: AppColors.inkSoft)),
          if (user.phone.isNotEmpty) Text(user.phone, style: const TextStyle(color: AppColors.inkSoft)),
          if (hasAvatar) TextButton(onPressed: _busy ? null : _removeAvatar, child: const Text('Hapus foto profil')),
          if (_busy) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator(color: AppColors.gold400)),
        ]),
      ),
      const SizedBox(height: 12),
      // Otorisasi (sisi klien): akun admin hanya diberi petunjuk, bukan akses kelola di aplikasi ini.
      if (user.role == 'admin')
        const NoticeBox(child: Text('Kamu masuk sebagai admin sanggar. Untuk mengelola data, gunakan dashboard admin di web.')),
      AppCard(
        padding: EdgeInsets.zero,
        child: Column(children: [
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined, color: AppColors.wood700),
            title: const Text('Pesanan Saya', style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right_rounded),
            // Rute bernama yang dijaga AppRouter
            onTap: () => Navigator.pushNamed(context, Routes.myOrders),
          ),
          const Divider(height: 1, color: AppColors.line),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
            title: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.danger)),
            onTap: _logout,
          ),
        ]),
      ),
    ]);
  }
}

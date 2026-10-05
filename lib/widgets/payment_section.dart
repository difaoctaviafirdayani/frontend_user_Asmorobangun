import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/picker.dart';
import '../core/theme.dart';
import 'common.dart';

/// Alur pembayaran yang sama untuk booking layanan dan pesanan topeng:
///   QRIS          -> tampil gambar QRIS, lalu unggah bukti pembayaran
///   Transfer Bank -> tampil rekening, lalu unggah bukti pembayaran
///   Tunai         -> cukup pilih "Bayar Tunai", tanpa bukti
/// kind: 'booking' atau 'topeng'.
class PaymentSection extends StatefulWidget {
  final String kind;
  final String id;
  final int? amount;
  final Map<String, dynamic> methods;
  final String? existingProof;
  final String? existingMethod;
  final VoidCallback onDone;

  const PaymentSection({
    super.key,
    required this.kind,
    required this.id,
    required this.onDone,
    this.amount,
    this.methods = const {},
    this.existingProof,
    this.existingMethod,
  });

  @override
  State<PaymentSection> createState() => _PaymentSectionState();
}

class _PaymentSectionState extends State<PaymentSection> {
  String? _method;
  bool _changing = false;
  bool _busy = false;
  Future<Map<String, dynamic>>? _info;
  ({List<int> bytes, String name})? _picked;

  String get _base =>
      widget.kind == 'topeng' ? '/topeng/orders/${widget.id}' : '/bookings/${widget.id}';

  List<String> get _available {
    bool on(String m) {
      final cfg = widget.methods[m];
      return cfg is! Map || cfg['enabled'] != false;
    }

    return ['qris', 'transfer', 'cash'].where(on).toList();
  }

  @override
  void initState() {
    super.initState();
    final first = _available.isEmpty ? null : _available.first;
    if (first != null) _select(first, initial: true);
  }

  void _select(String m, {bool initial = false}) {
    void apply() {
      _method = m;
      _picked = null;
      _info = (m == 'cash') ? null : api.get('$_base/${m == 'qris' ? 'qris' : 'transfer'}');
    }

    if (initial) {
      apply();
    } else {
      setState(apply);
    }
  }

  Future<void> _chooseCash() async {
    setState(() => _busy = true);
    try {
      await api.post('$_base/cash');
      if (!mounted) return;
      showSnack(context, 'Pembayaran tunai dicatat. Bayar langsung di lokasi ya.');
      widget.onDone();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick() async {
    final f = await pickImageFile();
    if (f != null) setState(() => _picked = f);
  }

  Future<void> _uploadProof(String method) async {
    final f = _picked;
    if (f == null) return showSnack(context, 'Pilih foto bukti pembayaran dulu.');
    setState(() => _busy = true);
    try {
      await api.upload('$_base/proof',
          field: 'proof', bytes: f.bytes, filename: f.name, fields: {'paymentMethod': method});
      if (!mounted) return;
      showSnack(context, 'Bukti pembayaran diunggah!');
      widget.onDone();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.existingProof != null && widget.existingProof!.isNotEmpty) return _proofDone();
    if (widget.existingMethod == 'cash' && !_changing) return _cashDone();
    return _picker();
  }

  Widget _doneBox({required IconData icon, required String title, required String subtitle, List<Widget> actions = const []}) {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: AppColors.ok, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: AppColors.inkSoft, fontSize: 13)),
            ]),
          ),
        ]),
        if (actions.isNotEmpty) ...[const SizedBox(height: 10), Wrap(spacing: 8, children: actions)],
      ]),
    );
  }

  Widget _proofDone() => _doneBox(
        icon: Icons.check_rounded,
        title: 'Bukti pembayaran terkirim',
        subtitle: 'Metode: ${methodLabel(widget.existingMethod)} · Menunggu verifikasi admin.',
        actions: [
          OutlinedButton(
            onPressed: () => openUrl(context, assetUrl(widget.existingProof)),
            child: const Text('Lihat bukti'),
          ),
        ],
      );

  Widget _cashDone() => _doneBox(
        icon: Icons.payments_outlined,
        title: 'Pembayaran tunai dicatat',
        subtitle: 'Silakan bayar langsung di lokasi. Tidak perlu unggah bukti pembayaran.',
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _changing = true);
              final first = _available.isEmpty ? null : _available.first;
              if (first != null) _select(first);
            },
            child: const Text('Ganti metode pembayaran'),
          ),
        ],
      );

  Widget _picker() {
    final methods = _available;
    if (methods.isEmpty) {
      return const AppCard(child: EmptyState('Belum ada metode pembayaran yang aktif. Silakan hubungi admin sanggar.'));
    }
    final current = _method ?? methods.first;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Pilih metode pembayaran', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, children: [
          for (final m in methods)
            ChoiceChip(
              label: Text(methodLabel(m)),
              selected: current == m,
              selectedColor: AppColors.gold300,
              onSelected: (_) => _select(m),
            ),
        ]),
        const SizedBox(height: 14),
        if (current == 'cash') _cashArea() else _onlineArea(current),
      ]),
    );
  }

  Widget _cashArea() {
    final cfg = widget.methods['cash'];
    final note = cfg is Map ? (cfg['note'] ?? '').toString() : '';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (note.isNotEmpty) Text('Catatan: $note', style: const TextStyle(fontWeight: FontWeight.w600)),
      const Text('Bayar tunai langsung di lokasi sanggar. Tidak perlu unggah bukti pembayaran.'),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(onPressed: _busy ? null : _chooseCash, child: Text(_busy ? 'Memproses...' : 'Pilih Bayar Tunai')),
      ),
    ]);
  }

  Widget _onlineArea(String method) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _info,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(color: AppColors.gold400)),
          );
        }
        if (snap.hasError) return Text(snap.error.toString(), style: const TextStyle(color: AppColors.danger));
        final data = snap.data ?? {};
        final amount = data['amount'] is num ? (data['amount'] as num).toInt() : widget.amount;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (method == 'qris') _qris(data, amount) else _transfer(data, amount),
          const SizedBox(height: 14),
          const Text('Unggah bukti pembayaran', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.image_outlined),
            label: Text(_picked == null ? 'Pilih foto bukti' : _picked!.name, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _busy ? null : () => _uploadProof(method),
              child: Text(_busy ? 'Mengunggah...' : 'Unggah Bukti'),
            ),
          ),
        ]);
      },
    );
  }

  Widget _qris(Map<String, dynamic> data, int? amount) {
    return Column(children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
        child: Column(children: [
          NetImage(src: data['qris']?.toString(), height: 240, fit: BoxFit.contain),
          if (amount != null) ...[
            const SizedBox(height: 8),
            Text(formatRupiah(amount), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
          const SizedBox(height: 4),
          Text(
            (data['note'] ?? 'Scan dengan aplikasi e-wallet atau mobile banking, lalu unggah bukti pembayaran.').toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.inkSoft, fontSize: 12),
          ),
        ]),
      ),
    ]);
  }

  Widget _transfer(Map<String, dynamic> data, int? amount) {
    final note = (data['note'] ?? '').toString();
    final bank = data['bank'] is Map ? data['bank'] as Map : const {};
    final account = (bank['accountNumber'] ?? '').toString();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.cream200, borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        if (note.isNotEmpty)
          KeyValueRow('Info transfer', note)
        else ...[
          KeyValueRow('Bank', (bank['bankName'] ?? '-').toString()),
          KeyValueRow('No. Rekening', account.isEmpty ? '-' : account),
          KeyValueRow('Atas Nama', (bank['accountName'] ?? '-').toString()),
        ],
        if (amount != null) KeyValueRow('Nominal', formatRupiah(amount)),
        if (note.isEmpty && account.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: account.replaceAll(RegExp(r'[^0-9]'), '')));
                showSnack(context, 'Nomor rekening disalin.');
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Salin no. rekening'),
            ),
          ),
      ]),
    );
  }
}

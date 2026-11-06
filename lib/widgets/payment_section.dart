import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/picker.dart';
import '../core/theme.dart';
import '../repositories/payment_repository.dart';
import '../viewmodels/base_viewmodel.dart';
import '../viewmodels/payment_viewmodel.dart';
import 'common.dart';

class PaymentSection extends StatelessWidget {
  final String kind;
  final String id;
  final int? amount;
  final Map<String, dynamic> methods;
  final String? existingProof;
  final String? existingMethod;
  final VoidCallback onDone;
  final bool verified;
  final bool canChange;

  const PaymentSection({
    super.key,
    required this.kind,
    required this.id,
    required this.onDone,
    this.amount,
    this.methods = const {},
    this.existingProof,
    this.existingMethod,
    this.verified = false,
    this.canChange = true,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => PaymentViewModel(c.read<PaymentRepository>(), kind: kind, id: id, methods: methods),
      child: _PaymentView(
        kind: kind,
        amount: amount,
        methods: methods,
        existingProof: existingProof,
        existingMethod: existingMethod,
        onDone: onDone,
        verified: verified,
        canChange: canChange,
      ),
    );
  }
}

class _PaymentView extends StatefulWidget {
  final String kind;
  final int? amount;
  final Map<String, dynamic> methods;
  final String? existingProof;
  final String? existingMethod;
  final VoidCallback onDone;
  final bool verified;
  final bool canChange;

  const _PaymentView({
    required this.kind,
    required this.onDone,
    required this.amount,
    required this.methods,
    required this.existingProof,
    required this.existingMethod,
    required this.verified,
    required this.canChange,
  });

  @override
  State<_PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<_PaymentView> {
  bool _changing = false;

  PaymentViewModel get _vm => context.read<PaymentViewModel>();

  List<String> get _available => _vm.available;
  String? get _method => _vm.method;
  bool get _busy => _vm.busy;
  PickedImage? get _picked => _vm.picked;

  void _select(String m) => _vm.selectMethod(m);

  Future<void> _chooseCash() async {
    final ok = await _vm.chooseCash();
    if (!mounted) return;
    if (ok) {
      showSnack(context, 'Pembayaran tunai dicatat. Bayar langsung di lokasi ya.');
      widget.onDone();
    } else {
      showSnack(context, _vm.error ?? 'Terjadi kesalahan. Coba lagi.');
    }
  }

  Future<void> _pick() async {
    final vm = _vm;
    final f = await pickValidImage(context);
    if (f != null) vm.setPicked(f);
  }

  Future<void> _uploadProof(String method) async {
    final vm = _vm;
    final ok = await vm.uploadProof(method);
    if (!mounted) return;
    if (ok) {
      showSnack(context, 'Bukti pembayaran diunggah!');
      widget.onDone();
    } else {
      showSnack(context, vm.error ?? 'Terjadi kesalahan. Coba lagi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<PaymentViewModel>();
    if (widget.existingProof != null && widget.existingProof!.isNotEmpty) {
      return _topengDone();
    }
    if (widget.kind != 'topeng' && widget.existingMethod == 'cash' && !_changing) return _cashDone();
    return _topengPicker();
  }

  static const _fill = Color(0xFFFDFBE8);
  static const _brownBtn = Color(0xFF5C3724);

  BoxDecoration _topengBox({Color color = _fill, double radius = 14}) => BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.wood700, width: 1),
      );

  Widget _cashDone() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: _topengBox(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.check_circle_outline_rounded, color: AppColors.wood900, size: 22),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Pembayaran tunai dicatat',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.wood900)),
                SizedBox(height: 2),
                Text('Silakan datang ke sanggar dan bayar langsung di lokasi. Tidak perlu unggah bukti pembayaran.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.wood800)),
              ]),
            ),
          ]),
          if (widget.canChange) ...[
            const SizedBox(height: 8),
            TextButton(
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact, foregroundColor: AppColors.wood800),
              onPressed: () {
                setState(() => _changing = true);
                final first = _available.isEmpty ? null : _available.first;
                if (first != null) _select(first);
              },
              child: const Text('Ganti metode pembayaran', style: TextStyle(fontSize: 12.5)),
            ),
          ],
        ]),
      );

  Widget _topengDone() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: _topengBox(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.check_circle_outline_rounded, color: AppColors.wood900, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Bukti pembayaran terkirim',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.wood900)),
                const SizedBox(height: 2),
                Text('Metode: ${methodLabel(widget.existingMethod)} - ${widget.verified ? 'Pembayaran terverifikasi' : 'Menunggu verifikasi admin'}',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.wood800)),
              ]),
            ),
          ]),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _brownBtn,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => openUrl(context, assetUrl(widget.existingProof)),
              child: const Text('Lihat Bukti yang diunggah', style: TextStyle(fontSize: 14)),
            ),
          ),
        ]),
      );

  Widget _topengPicker() {
    final methods = _available;
    if (methods.isEmpty) {
      return const AppCard(child: EmptyState('Belum ada metode pembayaran yang aktif. Silakan hubungi admin sanggar.'));
    }
    final current = _method ?? methods.first;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: _topengBox(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Pilih Metode Pembayaran',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.wood900)),
        const SizedBox(height: 10),
        Wrap(alignment: WrapAlignment.center, children: [
          for (final m in methods)
            InkWell(
              onTap: _busy ? null : () => _select(m),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(current == m ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      size: 20, color: AppColors.wood900),
                  const SizedBox(width: 6),
                  Text(methodLabel(m),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: current == m ? FontWeight.w700 : FontWeight.w400,
                          color: AppColors.wood900)),
                ]),
              ),
            ),
        ]),
        const SizedBox(height: 12),
        if (current == 'cash') _cashArea() else _onlineArea(current),
      ]),
    );
  }

  Widget _topengQris(Map<String, dynamic> data, int? amount) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: _topengBox(color: Colors.white, radius: 12),
            child: Column(children: [
              NetImage(src: data['qris']?.toString(), height: 220, fit: BoxFit.contain),
              if (amount != null) ...[
                const SizedBox(height: 8),
                Text(formatRupiah(amount),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.wood900)),
              ],
            ]),
          ),
        ),
      );

  Widget _kv(String k, String v, {Widget? trailing}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 4, child: Text(k, style: const TextStyle(fontSize: 12.5, color: AppColors.wood900))),
          Expanded(
            flex: 6,
            child: Row(children: [
              Flexible(child: Text(v, style: const TextStyle(fontSize: 12.5, color: AppColors.wood800))),
              if (trailing != null) trailing,
            ]),
          ),
        ]),
      );

  Widget _topengTransfer(Map<String, dynamic> data, int? amount) {
    final note = (data['note'] ?? '').toString();
    final bank = data['bank'] is Map ? data['bank'] as Map : const {};
    final account = (bank['accountNumber'] ?? '').toString();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFFFEDCB), borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        if (note.isNotEmpty)
          _kv('Info transfer', note)
        else ...[
          _kv('Bank', (bank['bankName'] ?? '-').toString()),
          _kv(
            'No. Rekening',
            account.isEmpty ? '-' : account,
            trailing: account.isEmpty
                ? null
                : InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: account.replaceAll(RegExp(r'[^0-9]'), '')));
                      showSnack(context, 'Nomor rekening disalin.');
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Tooltip(message: 'Salin no. rekening', child: Icon(Icons.copy_rounded, size: 15, color: AppColors.wood800)),
                    ),
                  ),
          ),
          _kv('Nama Pemilik', (bank['accountName'] ?? '-').toString()),
        ],
        if (amount != null) _kv('Nominal', formatRupiah(amount)),
      ]),
    );
  }

  Widget _topengUpload(String method) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 14),
        const Text('Unggah Bukti Pembayaran',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.wood900)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.wood900,
            side: const BorderSide(color: AppColors.wood700, width: 1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: _busy ? null : _pick,
          icon: const Icon(Icons.file_upload_outlined, size: 18),
          label: Text(_picked == null ? 'Pilih Gambar' : _picked!.name,
              overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _brownBtn,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: _busy ? null : () => _uploadProof(method),
          child: Text(_busy ? 'Mengirim...' : 'Kirim', style: const TextStyle(fontSize: 14)),
        ),
      ]);

  Widget _cashArea() {
    final cfg = widget.methods['cash'];
    final note = cfg is Map ? (cfg['note'] ?? '').toString() : '';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFFFEDCB), borderRadius: BorderRadius.circular(10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (note.isNotEmpty) ...[
            Text('Catatan: $note',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: AppColors.wood900)),
            const SizedBox(height: 4),
          ],
          const Text('Bayar tunai langsung di sanggar saat kamu datang. Tidak perlu unggah bukti pembayaran.',
              style: TextStyle(fontSize: 12.5, color: AppColors.wood900, height: 1.4)),
        ]),
      ),
      const SizedBox(height: 12),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _brownBtn,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: _busy ? null : _chooseCash,
        child: Text(_busy ? 'Memproses...' : 'Pilih Bayar Tunai', style: const TextStyle(fontSize: 14)),
      ),
    ]);
  }

  Widget _onlineArea(String method) {
    final vm = _vm;
    switch (vm.infoStatus) {
      case LoadStatus.loading:
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator(color: AppColors.gold400)),
        );
      case LoadStatus.error:
        return Text(vm.infoError ?? '', style: const TextStyle(color: AppColors.danger));
      case LoadStatus.success:
        final data = vm.info;
        final amount = data['amount'] is num ? (data['amount'] as num).toInt() : widget.amount;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (method == 'qris') _topengQris(data, amount) else _topengTransfer(data, amount),
          _topengUpload(method),
        ]);
    }
  }
}

Widget paymentHeading(String text, {double top = 0}) => Padding(
      padding: EdgeInsets.only(top: top, bottom: 10),
      child: Text(text, style: headingStyle(size: 20, color: AppColors.wood700)),
    );

class TransactionBox extends StatelessWidget {
  final String status;
  final List<(String, String)> rows;
  const TransactionBox({super.key, required this.status, required this.rows});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.wood700, width: 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(bottom: 8), child: StatusChip(status)),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 4, child: Text(r.$1, style: const TextStyle(color: AppColors.wood900, fontSize: 13))),
                Expanded(
                  flex: 6,
                  child: Text(r.$2,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.wood900)),
                ),
              ]),
            ),
        ]),
      );
}
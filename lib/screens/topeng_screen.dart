import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api.dart';
import '../core/auth_state.dart';
import '../core/format.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../core/validators.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import '../widgets/payment_section.dart';
import 'auth_screens.dart';
import 'facilities_screen.dart' show SectionHeaderInline;
import 'search_screen.dart';

/// Tombol melayang untuk membuka Asisten Topeng (hanya di bagian topeng).
Widget topengAiButton(BuildContext context) => FloatingActionButton.extended(
      backgroundColor: AppColors.gold400,
      foregroundColor: AppColors.wood950,
      onPressed: () => showTopengAI(context),
      icon: const Icon(Icons.auto_awesome),
      label: const Text('Asisten Topeng'),
    );

class TopengScreen extends StatelessWidget {
  const TopengScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Katalog Topeng',
      actions: [searchAction(context)],
      floatingActionButton: topengAiButton(context),
      body: AsyncView<List<Topeng>>(
        loader: () async => mapList((await api.get('/topeng'))['topeng'], Topeng.fromJson),
        builder: (context, items, _) {
          if (items.isEmpty) return const EmptyState('Katalog topeng belum tersedia.', icon: Icons.face_retouching_natural_outlined);
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.68,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final t = items[i];
              return AppCard(
                padding: EdgeInsets.zero,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TopengDetailScreen(id: t.id))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  NetImage(src: t.image, height: 130, width: double.infinity),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(t.character, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
                      const SizedBox(height: 6),
                      Text(formatRupiah(t.price), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.wood800)),
                      Text('Stok ${t.stock}', style: const TextStyle(color: AppColors.inkSoft, fontSize: 11.5)),
                    ]),
                  ),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}

class TopengDetailScreen extends StatelessWidget {
  final String id;
  const TopengDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Detail topeng',
      floatingActionButton: topengAiButton(context),
      body: AsyncView<Topeng>(
        loader: () async => Topeng.fromJson((await api.get('/topeng/$id'))['topeng'] as Map<String, dynamic>),
        builder: (context, t, _) => _TopengBody(topeng: t),
      ),
    );
  }
}

class _TopengBody extends StatefulWidget {
  final Topeng topeng;
  const _TopengBody({required this.topeng});

  @override
  State<_TopengBody> createState() => _TopengBodyState();
}

class _TopengBodyState extends State<_TopengBody> {
  final _formKey = GlobalKey<FormState>();
  int _qty = 1;
  bool _custom = false;
  bool _busy = false;
  final _customName = TextEditingController();
  final _customDesign = TextEditingController();
  final _phone = TextEditingController();
  final _message = TextEditingController();

  @override
  void initState() {
    super.initState();
    _phone.text = context.read<AuthState>().user?.phone ?? '';
  }

  @override
  void dispose() {
    for (final c in [_customName, _customDesign, _phone, _message]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _order() async {
    // Lapisan 1: validasi UI
    if (!_formKey.currentState!.validate()) return;
    if (_qty > widget.topeng.stock) {
      return showSnack(context, 'Jumlah melebihi stok yang tersedia (${widget.topeng.stock}).');
    }
    // Lapisan 3: autentikasi
    if (!await ensureLogin(context)) return;
    setState(() => _busy = true);
    try {
      // Lapisan 2: server memvalidasi ulang. Harga dihitung server dari katalog,
      // jadi aplikasi hanya mengirim jumlah, bukan total.
      final res = await api.post('/topeng/${widget.topeng.id}/order', body: {
        'qty': _qty,
        'customName': _custom ? Validators.clean(_customName.text) : null,
        'customDesign': _custom ? Validators.clean(_customDesign.text) : null,
        'buyerPhone': _phone.text.replaceAll(RegExp(r'[\s\-]'), ''),
        'message': Validators.clean(_message.text),
      });
      if (!mounted) return;
      showSnack(context, 'Pesanan dibuat, silakan lanjut ke pembayaran!');
      final order = TopengOrder.fromJson(res['order'] as Map<String, dynamic>);
      Navigator.pushNamed(context, Routes.order, arguments: order.id);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.topeng;
    final loggedIn = context.watch<AuthState>().isLoggedIn;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), children: [
      NetImage(src: t.image, height: 240, width: double.infinity, radius: BorderRadius.circular(16)),
      const SizedBox(height: 14),
      Text(t.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.wood900)),
      const SizedBox(height: 2),
      Text('${t.character} · Warna dominan: ${t.color}', style: const TextStyle(color: AppColors.inkSoft, fontSize: 13)),
      const SizedBox(height: 10),
      Text(formatRupiah(t.price), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.wood800)),
      const SizedBox(height: 8),
      Text(t.desc),
      const SizedBox(height: 6),
      Text('Stok tersedia: ${t.stock}', style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5)),
      const SectionHeaderInline('Pesan topeng ini'),
      if (!loggedIn)
        const NoticeBox(child: Text('Kamu perlu masuk dulu untuk memesan. Kamu akan diarahkan ke halaman masuk saat menekan tombol pesan.')),
      AppCard(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('Jumlah', style: TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            IconButton.outlined(
              onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
              icon: const Icon(Icons.remove),
            ),
            SizedBox(width: 40, child: Text('$_qty', textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
            IconButton.outlined(
              onPressed: _qty < widget.topeng.stock ? () => setState(() => _qty++) : null,
              icon: const Icon(Icons.add),
            ),
          ]),
          Align(
            alignment: Alignment.centerRight,
            child: Text('Total ${formatRupiah(t.price * _qty)}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.wood800)),
          ),
          const SizedBox(height: 6),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.gold400,
            title: const Text('Request nama/desain custom'),
            value: _custom,
            onChanged: (v) => setState(() => _custom = v),
          ),
          if (_custom) ...[
            TextFormField(
              controller: _customName,
              inputFormatters: InputFormats.maxLen(60),
              decoration: inputDec('Nama custom', hint: 'Untuk diukir atau label'),
              validator: Validators.text('Nama custom', min: 2, max: 60, required: false),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _customDesign,
              maxLines: 2,
              inputFormatters: InputFormats.maxLen(300),
              decoration: inputDec('Detail desain custom', hint: 'Warna, karakter, detail yang diinginkan'),
              validator: (v) {
                // Bila mode custom aktif, minimal salah satu dari nama atau desain harus terisi.
                if ((v ?? '').trim().isEmpty && _customName.text.trim().isEmpty) {
                  return 'Isi nama atau detail desain custom';
                }
                return Validators.text('Detail desain', min: 3, max: 300, required: false)(v);
              },
            ),
            const SizedBox(height: 10),
          ],
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            inputFormatters: InputFormats.phone,
            decoration: inputDec('Nomor WhatsApp kamu', hint: '08xxxxxxxxxx'),
            validator: (v) => Validators.phone(v, required: true),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _message,
            maxLines: 2,
            inputFormatters: InputFormats.maxLen(300),
            decoration: inputDec('Catatan tambahan', hint: 'Pesan untuk admin (opsional)'),
            validator: Validators.text('Catatan', max: 300, required: false),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _order,
              icon: const Icon(Icons.shopping_bag_outlined),
              label: Text(_busy ? 'Memproses...' : 'Pesan & Lanjut Pembayaran'),
            ),
          ),
        ]),
        ),
      ),
    ]);
  }
}

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Pesanan topeng',
      floatingActionButton: topengAiButton(context),
      body: AsyncView<TopengOrder>(
        loader: () async => TopengOrder.fromJson((await api.get('/topeng/orders/$orderId'))['order'] as Map<String, dynamic>),
        builder: (context, o, reload) => ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), children: [
          Text(o.topengName, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.wood900)),
          const SizedBox(height: 10),
          AppCard(
            child: Column(children: [
              KeyValueRow('Jumlah', '${o.qty}'),
              KeyValueRow('Harga satuan', formatRupiah(o.unitPrice)),
              KeyValueRow('Total', formatRupiah(o.total)),
              if ((o.customName ?? '').isNotEmpty) KeyValueRow('Nama custom', o.customName!),
              if ((o.customDesign ?? '').isNotEmpty) KeyValueRow('Desain custom', o.customDesign!),
              if (o.message.isNotEmpty) KeyValueRow('Catatan', o.message),
              KeyValueRow('Dipesan', formatDate(o.createdAt)),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerLeft, child: StatusChip(o.status)),
            ]),
          ),
          if (o.chatLog.isNotEmpty) ...[
            const SectionHeaderInline('Riwayat pesanan'),
            for (final m in o.chatLog)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  color: AppColors.cream200,
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m.text),
                    const SizedBox(height: 2),
                    Text(formatDate(m.date), style: const TextStyle(color: AppColors.inkSoft, fontSize: 11.5)),
                  ]),
                ),
              ),
          ],
          const SectionHeaderInline('Pembayaran'),
          PaymentSection(
            kind: 'topeng',
            id: o.id,
            amount: o.total,
            existingProof: o.proofFile,
            existingMethod: o.paymentMethod,
            onDone: reload,
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => openUrl(context, waUrl('Halo admin, saya ingin menanyakan pesanan ${o.topengName} (${o.id}).')),
            icon: const Icon(Icons.chat_outlined),
            label: const Text('Tanya admin via WhatsApp'),
          ),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Asisten Topeng (AI). Memanggil POST /api/ai/chat dengan riwayat percakapan.
// ---------------------------------------------------------------------------

void showTopengAI(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cream100,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (_) => const _TopengAiSheet(),
  );
}

class _AiMessage {
  final bool fromUser;
  final String text;
  _AiMessage(this.fromUser, this.text);
}

class _TopengAiSheet extends StatefulWidget {
  const _TopengAiSheet();

  @override
  State<_TopengAiSheet> createState() => _TopengAiSheetState();
}

class _TopengAiSheetState extends State<_TopengAiSheet> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_AiMessage> _messages = [
    _AiMessage(false, 'Halo! Aku Asisten Topeng. Tanya apa saja soal Topeng Malangan: sejarah, tokoh, makna warna, perawatan, sampai katalog di sini.'),
  ];
  bool _busy = false;

  static const _suggestions = [
    'Apa makna warna topeng?',
    'Siapa itu tokoh Klana?',
    'Bagaimana cara merawat topeng kayu?',
    'Bisa pesan topeng custom?',
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _busy) return;
    // Riwayat dikirim tanpa sapaan awal dan tanpa pesan yang baru ini.
    final history = _messages
        .skip(1)
        .map((m) => {'role': m.fromUser ? 'user' : 'assistant', 'content': m.text})
        .toList();
    setState(() {
      _messages.add(_AiMessage(true, text));
      _input.clear();
      _busy = true;
    });
    _scrollDown();
    try {
      final res = await api.post('/ai/chat', body: {'message': text, 'history': history});
      if (!mounted) return;
      setState(() => _messages.add(_AiMessage(false, (res['reply'] ?? '').toString())));
    } on ApiException catch (e) {
      if (mounted) setState(() => _messages.add(_AiMessage(false, 'Maaf, ada kendala: ${e.message}')));
    } finally {
      if (mounted) setState(() => _busy = false);
      _scrollDown();
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(children: [
          const SizedBox(height: 10),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(4))),
          const Padding(
            padding: EdgeInsets.all(14),
            child: Row(children: [
              Icon(Icons.auto_awesome, color: AppColors.gold400),
              SizedBox(width: 8),
              Text('Asisten Topeng', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.wood900)),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _messages.length + (_busy ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(padding: EdgeInsets.all(10), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold400))),
                  );
                }
                final m = _messages[i];
                return Align(
                  alignment: m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: m.fromUser ? AppColors.wood800 : AppColors.cream200,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(m.text, style: TextStyle(color: m.fromUser ? AppColors.cream100 : AppColors.ink)),
                  ),
                );
              },
            ),
          ),
          if (_messages.length == 1)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  for (final s in _suggestions)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(label: Text(s), onPressed: () => _send(s)),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: inputDec('Tulis pertanyaan...'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: AppColors.wood800),
                onPressed: _busy ? null : () => _send(),
                icon: const Icon(Icons.send_rounded),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

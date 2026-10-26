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

Widget topengAiButton(BuildContext context) => FloatingActionButton(
      backgroundColor: AppColors.wood700,
      foregroundColor: Colors.white,
      elevation: 3,
      shape: const CircleBorder(),
      tooltip: 'Asisten Topeng',
      onPressed: () => showTopengAI(context),
      child: const Icon(Icons.chat_bubble_outline_rounded, size: 30),
    );

const _topengFill = Color(0xFFFDFBE8);

const _countryCodes = <(String, String)>[
  ('62', 'Indonesia'),
  ('60', 'Malaysia'),
  ('65', 'Singapura'),
  ('673', 'Brunei'),
  ('66', 'Thailand'),
  ('63', 'Filipina'),
  ('61', 'Australia'),
];

class TopengScreen extends StatelessWidget {
  const TopengScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Katalog Topeng Malangan',
      backgroundColor: Colors.white,
      floatingActionButton: topengAiButton(context),
      body: AsyncView<List<Topeng>>(
        loader: () async => mapList((await api.get('/topeng'))['topeng'], Topeng.fromJson),
        builder: (context, items, _) {
          if (items.isEmpty) return const EmptyState('Katalog topeng belum tersedia.', icon: Icons.face_retouching_natural_outlined);
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
              mainAxisExtent: 270,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final t = items[i];
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TopengDetailScreen(id: t.id))),
                child: Container(
                  decoration: BoxDecoration(color: _topengFill, borderRadius: BorderRadius.circular(20)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      NetImage(src: t.image, height: 190, width: double.infinity),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(t.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: headingStyle(size: 15, color: AppColors.wood700)),
                          const SizedBox(height: 2),
                          Text(formatRupiah(t.price),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.wood700)),
                        ]),
                      ),
                    ]),
                  ),
                ),
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
      title: 'Katalog Topeng Malangan',
      backgroundColor: Colors.white,
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
  bool _busy = false;
  final _phone = TextEditingController();
  final _message = TextEditingController();

  String _dial = '62';

  String get _fullPhone {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^0+'), '');
    return digits.isEmpty ? '' : '+$_dial$digits';
  }

  String? _validatePhone() {
    final full = _fullPhone;
    if (full.isEmpty) return 'Nomor WhatsApp wajib diisi';
    if (_dial == '62') return Validators.phone(full, required: true);
    final n = full.length - 1 - _dial.length; // jumlah digit nomor
    if (n < 6 || n > 14) return 'Nomor tidak valid';
    return null;
  }

  @override
  void initState() {
    super.initState();
    final saved = (context.read<AuthState>().user?.phone ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    _phone.text = saved.replaceFirst(RegExp(r'^(62|0)'), '');
  }

  @override
  void dispose() {
    for (final c in [_phone, _message]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _order() async {
    if (!_formKey.currentState!.validate()) return;
    if (_qty > widget.topeng.stock) {
      return showSnack(context, 'Jumlah melebihi stok yang tersedia (${widget.topeng.stock}).');
    }
    if (!await ensureLogin(context)) return;
    setState(() => _busy = true);
    try {
      final res = await api.post('/topeng/${widget.topeng.id}/order', body: {
        'qty': _qty,
        'buyerPhone': _fullPhone,
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

  OutlineInputBorder _border([Color c = AppColors.wood700, double w = 1.5]) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: c, width: w));

  InputDecoration _dec(String hint, {Widget? prefix}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.inkSoft, fontSize: 15),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: prefix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: _border(),
        enabledBorder: _border(),
        focusedBorder: _border(AppColors.gold400, 2),
        errorBorder: _border(AppColors.danger),
        focusedErrorBorder: _border(AppColors.danger, 2),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontSize: 16, color: AppColors.wood700)),
      );

  Widget _qtyStepper() => Row(children: [
        InkWell(
          onTap: _qty > 1 ? () => setState(() => _qty--) : null,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(Icons.remove, color: _qty > 1 ? AppColors.wood700 : AppColors.line),
          ),
        ),
        Container(
          width: 56,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.wood700, width: 1.3),
          ),
          child: Text('$_qty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.wood700)),
        ),
        InkWell(
          onTap: _qty < widget.topeng.stock ? () => setState(() => _qty++) : null,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(Icons.add, color: _qty < widget.topeng.stock ? AppColors.wood700 : AppColors.line),
          ),
        ),
      ]);

  @override
  Widget build(BuildContext context) {
    final t = widget.topeng;
    final loggedIn = context.watch<AuthState>().isLoggedIn;
    const brown = AppColors.wood700;
    final width = MediaQuery.sizeOf(context).width;
    final imgW = (width * 0.36).clamp(110.0, 220.0);

    return ListView(padding: const EdgeInsets.fromLTRB(24, 24, 24, 110), children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        NetImage(src: t.image, width: imgW, height: imgW * 1.45, radius: BorderRadius.circular(18)),
        const SizedBox(width: 18),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.name, style: headingStyle(size: 26, color: brown)),
            const SizedBox(height: 12),
            Text(formatRupiah(t.price), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: brown)),
            const SizedBox(height: 10),
            Text(t.desc, style: const TextStyle(fontSize: 15, height: 1.45, color: brown)),
          ]),
        ),
      ]),
      const SizedBox(height: 28),
      Text('Pesan Topeng di sini', style: headingStyle(size: 22, color: brown)),
      const SizedBox(height: 14),
      if (!loggedIn)
        GestureDetector(
          onTap: () => ensureLogin(context),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDCB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: brown, width: 1.3),
            ),
            child: const Text('Masuk dulu untuk memesan.', style: TextStyle(fontSize: 16, color: brown)),
          ),
        ),
      Opacity(
        opacity: loggedIn ? 1 : 0.55,
        child: IgnorePointer(
          ignoring: !loggedIn,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
            decoration: BoxDecoration(
              color: _topengFill,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: brown, width: 1.2),
            ),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('Jumlah Pesan'),
                _qtyStepper(),
                const SizedBox(height: 14),
                _label('Nomor WhatsApp'),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  inputFormatters: InputFormats.digitsOnly + InputFormats.maxLen(13),
                  decoration: _dec('', prefix: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 6),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      PopupMenuButton<String>(
                        tooltip: 'Kode negara',
                        initialValue: _dial,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        constraints: const BoxConstraints(minWidth: 220, maxHeight: 340),
                        onSelected: (v) => setState(() => _dial = v),
                        itemBuilder: (_) => [
                          for (final c in _countryCodes)
                            PopupMenuItem<String>(
                              value: c.$1,
                              height: 40,
                              child: Text('${c.$2} (+${c.$1})',
                                  style: const TextStyle(fontSize: 14.5, color: AppColors.wood700)),
                            ),
                        ],
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('+$_dial', style: const TextStyle(fontSize: 15, color: AppColors.wood700)),
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.inkSoft),
                        ]),
                      ),
                      const SizedBox(width: 8),
                      const SizedBox(height: 26, child: VerticalDivider(width: 1, thickness: 1.2, color: AppColors.wood700)),
                    ]),
                  )),
                  validator: (_) => _validatePhone(),
                ),
                const SizedBox(height: 18),
                _label('Catatan Tambahan'),
                TextFormField(
                  controller: _message,
                  maxLines: 1,
                  inputFormatters: InputFormats.maxLen(300),
                  decoration: _dec('Tulis catatan untuk pesananmu (opsional)'),
                  validator: Validators.text('Catatan', max: 300, required: false),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5C3724),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: _busy ? null : _order,
                    child: Text(_busy ? 'Memproses...' : 'Pesan', style: const TextStyle(fontSize: 19)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    ]);
  }
}

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  Widget _section(String text) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 10),
        child: Text(text, style: headingStyle(size: 22, color: AppColors.wood700)),
      );

  Widget _box({required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(16)}) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: _topengFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.wood700, width: 1.2),
        ),
        child: child,
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 4, child: Text(label, style: const TextStyle(color: AppColors.wood700, fontSize: 14))),
          Expanded(
            flex: 6,
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.wood700)),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Pesanan topeng',
      backgroundColor: Colors.white,
      floatingActionButton: topengAiButton(context),
      body: AsyncView<TopengOrder>(
        loader: () async => TopengOrder.fromJson((await api.get('/topeng/orders/$orderId'))['order'] as Map<String, dynamic>),
        builder: (context, o, reload) => ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 110), children: [
          Text(o.topengName, style: headingStyle(size: 26, color: AppColors.wood700)),
          const SizedBox(height: 12),
          _box(
            child: Column(children: [
              _row('Jumlah', '${o.qty}'),
              _row('Harga satuan', formatRupiah(o.unitPrice)),
              _row('Total', formatRupiah(o.total)),
              if ((o.customName ?? '').isNotEmpty) _row('Nama custom', o.customName!),
              if ((o.customDesign ?? '').isNotEmpty) _row('Desain custom', o.customDesign!),
              if (o.message.isNotEmpty) _row('Catatan', o.message),
              _row('Dipesan', formatDate(o.createdAt)),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerLeft, child: StatusChip(o.status)),
            ]),
          ),
          if (o.chatLog.isNotEmpty) ...[
            _section('Riwayat pesanan'),
            for (final m in o.chatLog)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _box(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m.text, style: const TextStyle(height: 1.45, fontSize: 15, color: AppColors.wood700)),
                    const SizedBox(height: 4),
                    Text(formatDate(m.date), style: const TextStyle(color: AppColors.wood700, fontSize: 12.5)),
                  ]),
                ),
              ),
          ],
          _section('Pembayaran'),
          PaymentSection(
            kind: 'topeng',
            id: o.id,
            amount: o.total,
            existingProof: o.proofFile,
            existingMethod: o.paymentMethod,
            onDone: reload,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.wood700,
              side: const BorderSide(color: AppColors.wood700, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => openUrl(context, waUrl('Halo admin, saya ingin menanyakan pesanan ${o.topengName} (${o.id}).')),
            icon: const Icon(Icons.chat_outlined),
            label: const Text('Tanya admin via WhatsApp'),
          ),
        ]),
      ),
    );
  }
}

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
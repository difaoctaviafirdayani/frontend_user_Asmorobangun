import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth_state.dart';
import '../core/format.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../core/validators.dart';
import '../models/models.dart';
import '../repositories/topeng_repository.dart';
import '../viewmodels/order_detail_viewmodel.dart';
import '../viewmodels/topeng_assistant_viewmodel.dart';
import '../viewmodels/topeng_detail_viewmodel.dart';
import '../viewmodels/topeng_list_viewmodel.dart';
import '../widgets/common.dart';
import '../widgets/load_status_view.dart';
import '../widgets/payment_section.dart';
import '../widgets/reviews.dart';
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

class TopengScreen extends StatelessWidget {
  const TopengScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => TopengListViewModel(c.read<TopengRepository>())..load(),
      child: const _TopengListView(),
    );
  }
}

class _TopengListView extends StatelessWidget {
  const _TopengListView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TopengListViewModel>();
    return AppScaffold(
      title: 'Katalog Topeng Malangan',
      backgroundColor: Colors.white,
      floatingActionButton: topengAiButton(context),
      body: LoadStatusView(
        status: vm.status,
        error: vm.error,
        onRetry: vm.load,
        builder: (context) {
          final items = vm.data!;
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
    return ChangeNotifierProvider(
      create: (c) => TopengDetailViewModel(c.read<TopengRepository>(), id)..load(),
      child: const _TopengDetailView(),
    );
  }
}

class _TopengDetailView extends StatelessWidget {
  const _TopengDetailView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TopengDetailViewModel>();
    return AppScaffold(
      title: 'Katalog Topeng Malangan',
      backgroundColor: Colors.white,
      floatingActionButton: topengAiButton(context),
      body: LoadStatusView(
        status: vm.status,
        error: vm.error,
        onRetry: vm.load,
        builder: (_) => _TopengBody(topeng: vm.detail!.topeng, reviews: vm.detail!.reviews),
      ),
    );
  }
}

class _TopengBody extends StatefulWidget {
  final Topeng topeng;
  final List<Review> reviews;
  const _TopengBody({required this.topeng, required this.reviews});

  @override
  State<_TopengBody> createState() => _TopengBodyState();
}

class _TopengBodyState extends State<_TopengBody> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _message = TextEditingController();

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
    if (!await ensureLogin(context)) return;
    if (!mounted) return;
    final vm = context.read<TopengDetailViewModel>();
    final order = await vm.placeOrder(phone: _phone.text, message: _message.text);
    if (!mounted) return;
    if (order == null) {
      showSnack(context, vm.orderError ?? 'Terjadi kesalahan. Coba lagi.');
      return;
    }
    showSnack(context, 'Pesanan dibuat, silakan lanjut ke pembayaran!');
    Navigator.pushNamed(context, Routes.order, arguments: order.id);
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

  Widget _qtyStepper(TopengDetailViewModel vm) => Row(children: [
        InkWell(
          onTap: vm.canDecrease ? vm.decrease : null,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(Icons.remove, color: vm.canDecrease ? AppColors.wood700 : AppColors.line),
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
          child: Text('${vm.qty}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.wood700)),
        ),
        InkWell(
          onTap: vm.canIncrease ? vm.increase : null,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(Icons.add, color: vm.canIncrease ? AppColors.wood700 : AppColors.line),
          ),
        ),
      ]);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TopengDetailViewModel>();
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
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Text(t.name, style: headingStyle(size: 26, color: brown))),
              if (t.avgRating != null) ...[
                const SizedBox(width: 6),
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Icon(Icons.star_rounded, size: 18, color: AppColors.gold400),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(t.avgRating!.toStringAsFixed(1), style: const TextStyle(fontSize: 12.5, color: brown)),
                ),
              ],
            ]),
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
                _qtyStepper(vm),
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
                        initialValue: vm.dial,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        constraints: const BoxConstraints(minWidth: 220, maxHeight: 340),
                        onSelected: vm.selectDial,
                        itemBuilder: (_) => [
                          for (final c in TopengDetailViewModel.countryCodes)
                            PopupMenuItem<String>(
                              value: c.$1,
                              height: 40,
                              child: Text('${c.$2} (+${c.$1})',
                                  style: const TextStyle(fontSize: 14.5, color: AppColors.wood700)),
                            ),
                        ],
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('+${vm.dial}', style: const TextStyle(fontSize: 15, color: AppColors.wood700)),
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.inkSoft),
                        ]),
                      ),
                      const SizedBox(width: 8),
                      const SizedBox(height: 26, child: VerticalDivider(width: 1, thickness: 1.2, color: AppColors.wood700)),
                    ]),
                  )),
                  validator: (v) => vm.validatePhone(v ?? ''),
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
                    onPressed: vm.busy ? null : _order,
                    child: Text(vm.busy ? 'Memproses...' : 'Pesan', style: const TextStyle(fontSize: 19)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
      const SizedBox(height: 24),
      ReviewList(widget.reviews),
    ]);
  }
}

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => OrderDetailViewModel(c.read<TopengRepository>(), orderId)..load(),
      child: const _OrderDetailView(),
    );
  }
}

class _OrderDetailView extends StatelessWidget {
  const _OrderDetailView();

  Widget _section(String text, {double top = 24}) => Padding(
        padding: EdgeInsets.only(top: top, bottom: 10),
        child: Text(text, style: headingStyle(size: 20, color: AppColors.wood700)),
      );

  Widget _box({required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(14), Color color = Colors.white}) =>
      Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.wood700, width: 1),
        ),
        child: child,
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 4, child: Text(label, style: const TextStyle(color: AppColors.wood900, fontSize: 13))),
          Expanded(
            flex: 6,
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.wood900)),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OrderDetailViewModel>();
    return AppScaffold(
      title: 'Katalog Topeng Malangan',
      backgroundColor: Colors.white,
      floatingActionButton: topengAiButton(context),
      body: LoadStatusView(
        status: vm.status,
        error: vm.error,
        onRetry: vm.load,
        builder: (context) => _content(vm.data!, vm.load),
      ),
    );
  }

  Widget _content(TopengOrder o, VoidCallback reload) =>
      ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 110), children: [
          Text('Detail Transaksi', style: headingStyle(size: 20, color: AppColors.wood700)),
          const SizedBox(height: 10),
          _box(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: StatusChip(o.status),
              ),
              _row('Nama Pesanan', o.topengName),
              _row('Jumlah Pesanan', '${o.qty}'),
              if ((o.customName ?? '').isNotEmpty) _row('Nama custom', o.customName!),
              if ((o.customDesign ?? '').isNotEmpty) _row('Desain custom', o.customDesign!),
              _row('Catatan Tambahan', o.message.isEmpty ? '-' : o.message),
              _row('Total Pembayaran', formatRupiah(o.total)),
              _row('Dipesan', formatDate(o.createdAt)),
            ]),
          ),
          _section('Pembayaran'),
          if (o.isCancelled)
            const NoticeBox(child: Text('Pesanan ini dibatalkan karena tidak dibayar dalam 24 jam. Silakan buat pesanan baru.'))
          else ...[
            if (o.awaitingPayment)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text('Selesaikan pembayaran dalam 24 jam, atau pesanan akan dibatalkan otomatis.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.wood800)),
              ),
            PaymentSection(
              kind: 'topeng',
              id: o.id,
              amount: o.total,
              existingProof: o.proofFile,
              existingMethod: o.paymentMethod,
              verified: const ['dikonfirmasi', 'diproses', 'dikirim', 'selesai'].contains(o.status),
              onDone: reload,
            ),
          ],
      ]);
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

class _TopengAiSheet extends StatelessWidget {
  const _TopengAiSheet();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => TopengAssistantViewModel(c.read<TopengRepository>()),
      child: const _TopengAiView(),
    );
  }
}

class _TopengAiView extends StatefulWidget {
  const _TopengAiView();

  @override
  State<_TopengAiView> createState() => _TopengAiViewState();
}

class _TopengAiViewState extends State<_TopengAiView> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final vm = context.read<TopengAssistantViewModel>();
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || vm.busy) return;
    _input.clear();
    final sending = vm.send(text);
    _scrollDown();
    await sending;
    _scrollDown();
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
    final vm = context.watch<TopengAssistantViewModel>();
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
              itemCount: vm.messages.length + (vm.busy ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == vm.messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(padding: EdgeInsets.all(10), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold400))),
                  );
                }
                final m = vm.messages[i];
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
          if (vm.isFresh)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  for (final s in TopengAssistantViewModel.suggestions)
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
                onPressed: vm.busy ? null : () => _send(),
                icon: const Icon(Icons.send_rounded),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../repositories/facility_repository.dart';
import '../repositories/topeng_repository.dart';
import '../viewmodels/booking_detail_viewmodel.dart';
import '../viewmodels/my_orders_viewmodel.dart';
import '../widgets/common.dart';
import '../widgets/load_status_view.dart';
import '../widgets/payment_section.dart';
import '../widgets/reviews.dart';

const _cardFill = Color(0xFFFDFBE8);
const _brownBtn = Color(0xFF5C3724);

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (c) => TopengOrdersViewModel(c.read<TopengRepository>())..load()),
        ChangeNotifierProvider(create: (c) => BookingsViewModel(c.read<FacilityRepository>())..load()),
      ],
      child: _tabs(),
    );
  }

  Widget _tabs() {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Pesanan Saya', style: headingStyle(size: 20, color: AppColors.cream100)),
          backgroundColor: AppColors.wood900,
          foregroundColor: AppColors.cream100,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: const Column(children: [
          _PillTabs(),
          Expanded(child: TabBarView(children: [_TopengOrdersTab(), _BookingsTab()])),
        ]),
      ),
    );
  }
}

class _PillTabs extends StatelessWidget {
  const _PillTabs();

  @override
  Widget build(BuildContext context) {
    final c = DefaultTabController.of(context);
    const labels = ['Pesanan Topeng', 'Pendaftaran dan Booking'];
    return AnimatedBuilder(
      animation: c.animation!,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Row(children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Flexible(
              child: GestureDetector(
                onTap: () => c.animateTo(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: c.index == i ? _brownBtn : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.wood700, width: 1),
                  ),
                  child: Text(labels[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: c.index == i ? Colors.white : AppColors.wood700)),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final String status, title, date;
  final String? price;
  final VoidCallback? onTap;
  final List<Widget> actions;
  final String? hint;
  const _OrderCard({
    required this.status,
    required this.title,
    required this.date,
    this.price,
    this.onTap,
    this.actions = const [],
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _cardFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.wood700, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              StatusChip(status),
              const Spacer(),
              Text(date, style: const TextStyle(fontSize: 11.5, color: AppColors.wood700)),
            ]),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.wood900)),
            if (price != null) ...[
              const SizedBox(height: 2),
              Text(price!, style: const TextStyle(fontSize: 13, color: AppColors.wood800)),
            ],
            if (hint != null) ...[
              const SizedBox(height: 6),
              Text(hint!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.wood700)),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: Wrap(spacing: 8, children: actions)),
            ],
          ]),
        ),
      ),
    );
  }
}

Widget _smallButton(String label, VoidCallback onPressed) => SizedBox(
      height: 30,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.wood900,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          side: const BorderSide(color: AppColors.wood700, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
      ),
    );

Widget? _reviewButton(BuildContext context, {required String status, required Review? review, required String path, required VoidCallback reload}) {
  if (status != 'selesai') return null;
  return _smallButton(
    review == null ? 'Tulis Ulasan' : 'Edit Ulasan',
    () async {
      final changed = await showReviewDialog(context, basePath: path, existing: review);
      if (changed) reload();
    },
  );
}

class _TopengOrdersTab extends StatelessWidget {
  const _TopengOrdersTab();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TopengOrdersViewModel>();
    final reload = vm.load;
    return LoadStatusView(
      status: vm.status,
      error: vm.error,
      onRetry: reload,
      builder: (context) {
        final items = vm.data!;
        if (items.isEmpty) return const EmptyState('Belum ada pesanan topeng.', icon: Icons.face_retouching_natural_outlined);
        return RefreshIndicator(
          onRefresh: () async => reload(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final o = items[i];
              final review = _reviewButton(context,
                  status: o.status, review: o.review, path: vm.reviewPath(o), reload: reload);
              return _OrderCard(
                status: o.status,
                title: '${o.topengName} (${o.qty} pcs)',
                price: formatRupiah(o.total),
                date: formatDateLong(o.createdAt),
                onTap: () => Navigator.pushNamed(context, Routes.order, arguments: o.id).then((_) => reload()),
                actions: [
                  if (review != null) review,
                  _smallButton('Lihat Detail', () => Navigator.pushNamed(context, Routes.order, arguments: o.id).then((_) => reload())),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _BookingsTab extends StatelessWidget {
  const _BookingsTab();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BookingsViewModel>();
    final reload = vm.load;
    return LoadStatusView(
      status: vm.status,
      error: vm.error,
      onRetry: reload,
      builder: (context) {
        final items = vm.data!;
        if (items.isEmpty) return const EmptyState('Belum ada pendaftaran atau booking.', icon: Icons.event_note_outlined);
        return RefreshIndicator(
          onRefresh: () async => reload(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final b = items[i];
              final needsPayment = b.status == 'menunggu_pembayaran';
              final review = _reviewButton(context,
                  status: b.status, review: b.review, path: vm.reviewPath(b), reload: reload);
              void openDetail() => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingDetailScreen(booking: b))).then((_) => reload());
              return _OrderCard(
                status: b.status,
                title: b.facilityName,
                price: b.amount != null ? formatRupiah(b.amount) : null,
                date: (b.date ?? '').isNotEmpty ? formatDateLong(b.date) : formatDateLong(b.createdAt),
                hint: needsPayment ? 'Ketuk untuk bayar' : null,
                onTap: openDetail,
                actions: [
                  if (review != null) review,
                  _smallButton('Lihat Detail', openDetail),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class BookingDetailScreen extends StatelessWidget {
  final Booking booking;
  const BookingDetailScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => BookingDetailViewModel(c.read<FacilityRepository>(), booking)..load(),
      child: _BookingDetailView(booking: booking),
    );
  }
}

class _BookingDetailView extends StatelessWidget {
  final Booking booking;
  const _BookingDetailView({required this.booking});

  String? _statusNote(Booking b) {
    switch (b.status) {
      case 'menunggu_kedatangan':
        return 'Silakan datang sesuai jadwal dan bayar tunai langsung di sanggar.';
      case 'menunggu_verifikasi':
        return 'Bukti pembayaran sudah terkirim. Admin akan memverifikasinya dalam 1x24 jam.';
      case 'menunggu_konfirmasi_admin':
        return 'Permintaanmu sudah kami terima. Admin akan menghubungimu lewat email atau WhatsApp.';
      case 'dikonfirmasi':
        return 'Booking dikonfirmasi. Sampai jumpa di sanggar!';
      case 'selesai':
        return 'Terima kasih sudah berkunjung. Kamu bisa menulis ulasan dari halaman Pesanan Saya.';
      case 'ditolak':
        return 'Maaf, permintaan ini tidak dapat diproses. Hubungi admin untuk informasi lebih lanjut.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BookingDetailViewModel>();
    final b = booking;
    final note = _statusNote(b);
    final needsPayment = b.status == 'menunggu_pembayaran';
    final hasProof = (b.proofFile ?? '').isNotEmpty;
    final waitingArrival = b.paymentMethod == 'cash' && b.status == 'menunggu_kedatangan';
    return AppScaffold(
      title: 'Layanan Sanggar',
      backgroundColor: Colors.white,
      body: LoadStatusView(
        status: vm.status,
        error: vm.error,
        onRetry: vm.load,
        builder: (context) {
          final f = vm.data;
          return ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 40), children: [
          paymentHeading('Detail Transaksi'),
          TransactionBox(status: b.status, rows: [
            ('Nama Layanan', b.facilityName),
            if ((b.date ?? '').isNotEmpty) ('Jadwal', formatDate(b.date)),
            if (b.guestCount != null) (b.bookingType == 'event' ? 'Perkiraan Peserta' : 'Jumlah Peserta', '${b.guestCount} orang'),
            if ((b.eventType ?? '').isNotEmpty) ('Jenis Acara', b.eventType!),
            if ((b.location ?? '').isNotEmpty) ('Lokasi', b.location!),
            ('Catatan Tambahan', b.notes.isEmpty ? '-' : b.notes),
            if (b.amount != null) ('Total Pembayaran', formatRupiah(b.amount)),
            if (b.paymentMethod != null) ('Metode Pembayaran', methodLabel(b.paymentMethod)),
            ('Dipesan', formatDate(b.createdAt)),
          ]),
          if (needsPayment && f != null) ...[
            paymentHeading('Pembayaran', top: 24),
            PaymentSection(
              kind: 'booking',
              id: b.id,
              amount: b.amount,
              methods: f.paymentMethods,
              existingProof: b.proofFile,
              existingMethod: b.paymentMethod,
              onDone: () => Navigator.pop(context),
            ),
          ] else if (hasProof || waitingArrival) ...[
            paymentHeading('Pembayaran', top: 24),
            PaymentSection(
              kind: 'booking',
              id: b.id,
              amount: b.amount,
              existingProof: b.proofFile,
              existingMethod: b.paymentMethod,
              verified: b.status == 'dikonfirmasi' || b.status == 'selesai',
              canChange: false,
              onDone: () {},
            ),
          ] else if (note != null) ...[
            paymentHeading('Status', top: 24),
            Text(note, style: const TextStyle(fontSize: 13.5, height: 1.45, color: AppColors.wood800)),
            if ((b.proofFile ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.wood900,
                  side: const BorderSide(color: AppColors.wood700, width: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => openUrl(context, assetUrl(b.proofFile)),
                child: const Text('Lihat Bukti yang diunggah'),
              ),
            ],
          ],
        ]);
        },
      ),
    );
  }
}

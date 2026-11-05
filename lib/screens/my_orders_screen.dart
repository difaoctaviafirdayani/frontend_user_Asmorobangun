import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import '../widgets/payment_section.dart';
import '../widgets/reviews.dart';

const _cardFill = Color(0xFFFDFBE8);
const _brownBtn = Color(0xFF5C3724);

/// Halaman ini hanya bisa dibuka lewat rute bernama Routes.myOrders,
/// yang sudah dijaga AppRouter (harus login). Server juga hanya mengembalikan
/// pesanan milik pemilik token (/orders/mine, /bookings/mine).
///
/// Ulasan hanya bisa ditulis dari sini, setelah pesanan topeng atau booking
/// berstatus "selesai". Ulasan yang sudah dikirim bisa diedit atau dihapus.
class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
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

/// Dua tab berbentuk pil (sesuai desain).
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

/// Kartu pesanan/booking: status di kiri atas, tanggal di kanan atas,
/// judul dan harga, lalu tombol kecil di kanan bawah.
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

Widget _smallButton(String label, VoidCallback onPressed, {bool filled = false}) => SizedBox(
      height: 30,
      child: filled
          ? ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _brownBtn,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: onPressed,
              child: Text(label, style: const TextStyle(fontSize: 12)),
            )
          : OutlinedButton(
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

/// Tombol ulasan: hanya muncul bila pesanan sudah selesai.
/// Belum ada ulasan -> "Beri Ulasan". Sudah ada -> "Edit Ulasan" (bisa hapus di dialog).
Widget? _reviewButton(BuildContext context, {required String status, required Review? review, required String path, required VoidCallback reload}) {
  if (status != 'selesai') return null;
  return _smallButton(
    review == null ? 'Beri Ulasan' : 'Edit Ulasan',
    () async {
      final changed = await showReviewDialog(context, basePath: path, existing: review);
      if (changed) reload();
    },
    filled: review == null,
  );
}

class _TopengOrdersTab extends StatelessWidget {
  const _TopengOrdersTab();

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<TopengOrder>>(
      loader: () async => mapList((await api.get('/topeng/orders/mine'))['orders'], TopengOrder.fromJson),
      builder: (context, items, reload) {
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
                  status: o.status, review: o.review, path: '/topeng/orders/${o.id}/review', reload: reload);
              return _OrderCard(
                status: o.status,
                title: '${o.topengName} (${o.qty} pcs)',
                price: formatRupiah(o.total),
                date: formatDateLong(o.createdAt),
                // Navigator rute bernama + argumen; kembali dari detail menyegarkan daftar.
                onTap: () => Navigator.pushNamed(context, Routes.order, arguments: o.id).then((_) => reload()),
                actions: [if (review != null) review],
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
    return AsyncView<List<Booking>>(
      loader: () async => mapList((await api.get('/bookings/mine'))['bookings'], Booking.fromJson),
      builder: (context, items, reload) {
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
                  status: b.status, review: b.review, path: '/bookings/${b.id}/review', reload: reload);
              return _OrderCard(
                status: b.status,
                title: b.facilityName,
                price: b.amount != null ? formatRupiah(b.amount) : null,
                date: (b.date ?? '').isNotEmpty ? formatDateLong(b.date) : formatDateLong(b.createdAt),
                hint: needsPayment ? 'Ketuk untuk bayar' : null,
                onTap: needsPayment
                    ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingPaymentScreen(booking: b))).then((_) => reload())
                    : null,
                actions: [if (review != null) review],
              );
            },
          ),
        );
      },
    );
  }
}

/// Melanjutkan pembayaran booking yang masih "menunggu pembayaran".
class BookingPaymentScreen extends StatelessWidget {
  final Booking booking;
  const BookingPaymentScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Pembayaran',
      body: AsyncView<Facility>(
        loader: () async => Facility.fromJson((await api.get('/facilities/${Uri.encodeComponent(booking.facilityId)}'))['facility'] as Map<String, dynamic>),
        builder: (context, f, _) => ListView(padding: const EdgeInsets.all(16), children: [
          AppCard(
            child: Column(children: [
              KeyValueRow('Layanan', booking.facilityName),
              if ((booking.date ?? '').isNotEmpty) KeyValueRow('Jadwal', formatDate(booking.date)),
              if (booking.amount != null) KeyValueRow('Nominal', formatRupiah(booking.amount)),
            ]),
          ),
          const SizedBox(height: 12),
          PaymentSection(
            kind: 'booking',
            id: booking.id,
            amount: booking.amount,
            methods: f.paymentMethods,
            existingProof: booking.proofFile,
            existingMethod: booking.paymentMethod,
            onDone: () => Navigator.pop(context),
          ),
        ]),
      ),
    );
  }
}
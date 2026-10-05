import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import '../widgets/payment_section.dart';

/// Halaman ini hanya bisa dibuka lewat rute bernama Routes.myOrders,
/// yang sudah dijaga AppRouter (harus login). Server juga hanya mengembalikan
/// pesanan milik pemilik token (/orders/mine, /bookings/mine).
class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pesanan Saya', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.wood900,
          foregroundColor: AppColors.cream100,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: AppColors.gold300,
            labelColor: AppColors.gold300,
            unselectedLabelColor: AppColors.cream200,
            tabs: [Tab(text: 'Pesanan Topeng'), Tab(text: 'Pendaftaran & Booking')],
          ),
        ),
        body: const TabBarView(children: [_TopengOrdersTab(), _BookingsTab()]),
      ),
    );
  }
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
              return AppCard(
                padding: const EdgeInsets.all(12),
                // Navigator rute bernama + argumen; kembali dari detail menyegarkan daftar.
                onTap: () => Navigator.pushNamed(context, Routes.order, arguments: o.id).then((_) => reload()),
                child: Row(children: [
                  NetImage(src: o.topengImage, width: 56, height: 56, radius: BorderRadius.circular(12)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${o.topengName} x${o.qty}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('${formatRupiah(o.total)} · ${formatDate(o.createdAt)}', style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5)),
                      const SizedBox(height: 6),
                      StatusChip(o.status),
                    ]),
                  ),
                ]),
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
              return AppCard(
                onTap: needsPayment
                    ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingPaymentScreen(booking: b))).then((_) => reload())
                    : null,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(b.facilityName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    [if ((b.date ?? '').isNotEmpty) formatDate(b.date), if (b.amount != null) formatRupiah(b.amount)].join(' · '),
                    style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    StatusChip(b.status),
                    if (needsPayment) ...[
                      const Spacer(),
                      const Text('Ketuk untuk bayar', style: TextStyle(color: AppColors.wood700, fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ],
                  ]),
                ]),
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

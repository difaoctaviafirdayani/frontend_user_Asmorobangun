import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api.dart';
import '../core/auth_state.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../core/validators.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import '../widgets/payment_section.dart';
import 'auth_screens.dart';
import 'search_screen.dart';

class FacilitiesScreen extends StatelessWidget {
  const FacilitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Fasilitas & Layanan',
      actions: [searchAction(context)],
      body: AsyncView<List<Facility>>(
        loader: () async => mapList((await api.get('/facilities'))['facilities'], Facility.fromJson),
        builder: (context, items, _) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) => FacilityTile(facility: items[i]),
        ),
      ),
    );
  }
}

class FacilityTile extends StatelessWidget {
  final Facility facility;
  const FacilityTile({super.key, required this.facility});

  @override
  Widget build(BuildContext context) {
    final f = facility;
    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FacilityDetailScreen(id: f.id))),
      child: Row(children: [
        NetImage(src: f.image, width: 64, height: 64, radius: BorderRadius.circular(12)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(f.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(f.shortDesc, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5)),
          ]),
        ),
        if (f.avgRating != null) ...[
          const SizedBox(width: 8),
          Column(children: [
            const Icon(Icons.star_rounded, color: AppColors.gold400, size: 18),
            Text('${f.avgRating}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ]),
        ],
      ]),
    );
  }
}

class _FacilityData {
  final Facility facility;
  final List<Review> reviews;
  _FacilityData(this.facility, this.reviews);
}

class FacilityDetailScreen extends StatelessWidget {
  final String id;
  const FacilityDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Detail layanan',
      body: AsyncView<_FacilityData>(
        loader: () async {
          final res = await api.get('/facilities/$id');
          return _FacilityData(
            Facility.fromJson(res['facility'] as Map<String, dynamic>),
            mapList(res['reviews'], Review.fromJson),
          );
        },
        builder: (context, data, reload) => _FacilityBody(data: data, reload: reload),
      ),
    );
  }
}

class _FacilityBody extends StatelessWidget {
  final _FacilityData data;
  final VoidCallback reload;
  const _FacilityBody({required this.data, required this.reload});

  @override
  Widget build(BuildContext context) {
    final f = data.facility;
    return ListView(padding: const EdgeInsets.all(16), children: [
      NetImage(src: f.image, height: 200, width: double.infinity, radius: BorderRadius.circular(16)),
      const SizedBox(height: 14),
      Align(alignment: Alignment.centerLeft, child: TagChip(f.category)),
      const SizedBox(height: 8),
      Text(f.name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.wood900)),
      const SizedBox(height: 4),
      if (f.avgRating != null)
        Row(children: [
          StarsRow(f.avgRating!),
          const SizedBox(width: 6),
          Text('${f.avgRating} (${f.reviewCount} ulasan)', style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5)),
        ])
      else
        const Text('Belum ada ulasan', style: TextStyle(color: AppColors.inkSoft, fontSize: 12.5)),
      const SizedBox(height: 10),
      Text(f.longDesc),
      const SizedBox(height: 14),
      AppCard(
        color: AppColors.cream200,
        child: Row(children: [
          const Icon(Icons.payments_outlined, color: AppColors.wood700),
          const SizedBox(width: 10),
          Expanded(child: Text(f.priceInfo, style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
      ),
      const SizedBox(height: 8),
      BookingForm(facility: f),
      const SectionHeaderInline('Ulasan pendaftar'),
      ReviewForm(facilityId: f.id, onSubmitted: reload),
      if (data.reviews.isEmpty)
        const EmptyState('Jadilah yang pertama memberi ulasan.', icon: Icons.rate_review_outlined)
      else
        for (final r in data.reviews)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(r.userName, style: const TextStyle(fontWeight: FontWeight.w700))),
                  Text(formatDate(r.date), style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
                ]),
                const SizedBox(height: 2),
                StarsRow(r.rating.toDouble(), size: 15),
                const SizedBox(height: 4),
                Text(r.comment),
              ]),
            ),
          ),
    ]);
  }
}

class SectionHeaderInline extends StatelessWidget {
  final String text;
  const SectionHeaderInline(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.wood900)),
      );
}

const _ratingLabels = {5: 'Sangat baik', 4: 'Baik', 3: 'Cukup', 2: 'Kurang', 1: 'Buruk'};

class ReviewForm extends StatefulWidget {
  final String facilityId;
  final VoidCallback onSubmitted;
  const ReviewForm({super.key, required this.facilityId, required this.onSubmitted});

  @override
  State<ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {
  final _formKey = GlobalKey<FormState>();
  final _comment = TextEditingController();
  int _rating = 5;
  bool _busy = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Lapisan 1: validasi UI
    if (!_formKey.currentState!.validate()) return;
    // Lapisan 3: autentikasi (arahkan ke login bila belum)
    if (!await ensureLogin(context)) return;
    setState(() => _busy = true);
    try {
      // Lapisan 2: server memvalidasi ulang dan bisa menolak
      await api.post('/facilities/${widget.facilityId}/reviews',
          body: {'rating': _rating, 'comment': Validators.clean(_comment.text)});
      if (!mounted) return;
      showSnack(context, 'Ulasan terkirim, makasih!');
      widget.onSubmitted();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.watch<AuthState>().isLoggedIn;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (!loggedIn)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text('Masuk untuk memberi ulasan. Kamu akan diarahkan ke halaman masuk saat mengirim.',
                    style: TextStyle(color: AppColors.inkSoft, fontSize: 13)),
              ),
            const Text('Rating kamu', style: TextStyle(fontWeight: FontWeight.w600)),
            Row(children: [
              for (var n = 1; n <= 5; n++)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _rating = n),
                  icon: Icon(Icons.star_rounded, size: 30, color: n <= _rating ? AppColors.gold400 : AppColors.cream300),
                ),
              const SizedBox(width: 6),
              Text('$_rating - ${_ratingLabels[_rating]}', style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5)),
            ]),
            TextFormField(
              controller: _comment,
              maxLines: 3,
              inputFormatters: InputFormats.maxLen(500),
              decoration: inputDec('Komentar', hint: 'Bagikan pengalamanmu...'),
              validator: Validators.text('Komentar', min: 3, max: 500),
            ),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: _busy ? null : _submit, child: Text(_busy ? 'Mengirim...' : 'Kirim ulasan')),
          ]),
        ),
      ),
    );
  }
}

/// Kolom tanggal yang ikut divalidasi oleh Form (menampilkan pesan error di bawahnya).
class DateFormField extends FormField<DateTime> {
  DateFormField({super.key, required String label, required DateTime? value, required ValueChanged<DateTime> onPicked})
      : super(
          initialValue: value,
          validator: (v) => v == null ? 'Tanggal wajib dipilih' : null,
          builder: (state) {
            final context = state.context;
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final now = DateTime.now();
                  final d = await showDatePicker(
                    context: context,
                    initialDate: state.value ?? now,
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 730)),
                  );
                  if (d != null) {
                    state.didChange(d);
                    onPicked(d);
                  }
                },
                icon: const Icon(Icons.event_outlined),
                label: Text(state.value == null ? label : formatDate(dateParam(state.value!))),
              ),
              if (state.hasError)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 6),
                  child: Text(state.errorText!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                ),
            ]);
          },
        );
}

/// Formulir pendaftaran/booking. Isinya berbeda untuk tiap jenis layanan:
/// wisata, reguler, rental, dan event.
class BookingForm extends StatefulWidget {
  final Facility facility;
  const BookingForm({super.key, required this.facility});

  @override
  State<BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingForm> {
  final _formKey = GlobalKey<FormState>();
  final _scheduleText = TextEditingController();
  final _notes = TextEditingController();
  final _eventType = TextEditingController();
  final _location = TextEditingController();
  final _guests = TextEditingController();
  final _qty = TextEditingController(text: '1');
  DateTime? _date;
  bool _busy = false;
  Booking? _result;

  Facility get f => widget.facility;
  bool get _needsPaymentNow => f.bookingType == 'wisata' || f.bookingType == 'rental';
  bool get _usesDatePicker => f.bookingType != 'reguler';

  @override
  void dispose() {
    for (final c in [_scheduleText, _notes, _eventType, _location, _guests, _qty]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _heading => const {
        'wisata': 'Daftar & bayar',
        'reguler': 'Formulir pendaftaran',
        'rental': 'Ajukan sewa',
        'event': 'Ajukan panggilan / kunjungan',
      }[f.bookingType] ??
      'Daftar';

  String get _submitLabel => const {
        'wisata': 'Daftar & Bayar',
        'reguler': 'Kirim Pendaftaran',
        'rental': 'Ajukan Sewa',
        'event': 'Ajukan Permintaan',
      }[f.bookingType] ??
      'Kirim';

  Future<void> _submit() async {
    // Lapisan 1: validasi UI
    if (!_formKey.currentState!.validate()) return;
    // Lapisan 3: autentikasi
    if (!await ensureLogin(context)) return;

    final body = <String, dynamic>{
      'facilityId': f.id,
      'date': _usesDatePicker ? dateParam(_date!) : Validators.clean(_scheduleText.text),
      'notes': Validators.clean(_notes.text),
      // Metode pembayaran dipilih setelahnya lewat bagian pembayaran.
      'paymentMethod': _needsPaymentNow ? 'qris' : null,
    };
    if (f.bookingType == 'event') {
      body['eventType'] = Validators.clean(_eventType.text);
      body['location'] = Validators.clean(_location.text);
      final g = int.tryParse(_guests.text.trim());
      if (g != null) body['guestCount'] = g;
    }
    // Sengaja TIDAK mengirim nominal harga: harga harus dihitung server dari
    // data fasilitas, bukan dipercaya dari aplikasi (mencegah manipulasi harga).
    if (f.bookingType == 'wisata') body['guestCount'] = int.parse(_qty.text.trim());

    setState(() => _busy = true);
    try {
      // Lapisan 2: server memvalidasi ulang. Otorisasi: userId diambil dari token, bukan dari body.
      final res = await api.post('/bookings', body: body);
      if (!mounted) return;
      showSnack(context, 'Permintaan terkirim!');
      setState(() => _result = Booking.fromJson(res['booking'] as Map<String, dynamic>));
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.watch<AuthState>().isLoggedIn;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeaderInline(_heading),
      if (!loggedIn)
        const NoticeBox(
          child: Text('Perlu masuk dulu. Pendaftaran/booking mengharuskan kamu login supaya statusnya bisa dipantau. Kamu akan diarahkan ke halaman masuk saat mengirim.'),
        ),
      if (_result != null) _resultView(_result!) else _form(),
    ]);
  }

  Widget _form() {
    return AppCard(
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (f.bookingType == 'event') ...[
            TextFormField(
              controller: _eventType,
              inputFormatters: InputFormats.maxLen(80),
              decoration: inputDec('Jenis acara', hint: 'mis. Pernikahan, Festival, Study Tour'),
              validator: Validators.text('Jenis acara', min: 3, max: 80),
            ),
            const SizedBox(height: 12),
          ],
          if (_usesDatePicker)
            DateFormField(
              label: f.bookingType == 'rental'
                  ? 'Pilih tanggal sewa'
                  : f.bookingType == 'event'
                      ? 'Pilih tanggal acara'
                      : 'Pilih tanggal kunjungan',
              value: _date,
              onPicked: (d) => _date = d,
            )
          else
            TextFormField(
              controller: _scheduleText,
              inputFormatters: InputFormats.maxLen(100),
              decoration: inputDec('Jadwal yang diinginkan', hint: 'mis. Sabtu sore, atau sesuai jadwal tersedia'),
              validator: Validators.text('Jadwal', min: 3, max: 100),
            ),
          const SizedBox(height: 12),
          if (f.bookingType == 'wisata') ...[
            TextFormField(
              controller: _qty,
              keyboardType: TextInputType.number,
              inputFormatters: InputFormats.digitsOnly,
              decoration: inputDec('Jumlah peserta'),
              validator: Validators.integer('Jumlah peserta', min: 1, max: 50),
            ),
            const SizedBox(height: 12),
          ],
          if (f.bookingType == 'event') ...[
            TextFormField(
              controller: _location,
              maxLines: 2,
              inputFormatters: InputFormats.maxLen(200),
              decoration: inputDec('Lokasi acara', hint: 'Alamat lengkap lokasi acara'),
              validator: Validators.text('Lokasi acara', min: 5, max: 200),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _guests,
              keyboardType: TextInputType.number,
              inputFormatters: InputFormats.digitsOnly,
              decoration: inputDec('Perkiraan jumlah tamu/peserta (opsional)'),
              validator: Validators.integer('Jumlah tamu', min: 1, max: 5000, required: false),
            ),
            const SizedBox(height: 12),
          ],
          if (f.bookingType != 'wisata')
            TextFormField(
              controller: _notes,
              maxLines: 2,
              inputFormatters: InputFormats.maxLen(500),
              decoration: inputDec(
                f.bookingType == 'rental' ? 'Karakter / ukuran kostum' : (f.bookingType == 'event' ? 'Catatan tambahan (opsional)' : 'Catatan (usia, pengalaman, dll)'),
                hint: f.bookingType == 'rental' ? 'mis. Kostum Panji, ukuran M' : (f.bookingType == 'event' ? 'Durasi, lakon yang diinginkan, dll' : 'Ceritakan sedikit tentang dirimu'),
              ),
              validator: Validators.text('Catatan', min: 2, max: 500, required: f.bookingType == 'rental'),
            ),
          const SizedBox(height: 10),
          Text(_hint(), style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: _busy ? null : _submit, child: Text(_busy ? 'Mengirim...' : _submitLabel)),
          ),
        ]),
      ),
    );
  }

  String _hint() {
    if (f.bookingType == 'event') return 'Tim kami akan meninjau permintaan ini dan menghubungimu untuk penawaran harga.';
    if (f.id == 'les-karawitan') return 'Kelas karawitan masih gratis. Cukup kirim pendaftaran, admin akan menghubungimu untuk jadwal.';
    if (_needsPaymentNow) return 'Setelah mengirim, kamu akan memilih metode pembayaran (QRIS / Transfer / Tunai). Bukti pembayaran hanya diperlukan untuk QRIS dan transfer.';
    return 'Metode pembayaran bisa dikonfirmasi belakangan bila diperlukan.';
  }

  Widget _resultView(Booking b) {
    if (b.status == 'menunggu_pembayaran') {
      return Column(children: [
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            StatusChip(b.status),
            const SizedBox(height: 8),
            const Text('Pilih metode pembayaran. Untuk QRIS dan transfer, unggah bukti pembayaranmu setelah membayar.'),
          ]),
        ),
        const SizedBox(height: 10),
        PaymentSection(
          kind: 'booking',
          id: b.id,
          amount: b.amount,
          methods: f.paymentMethods,
          onDone: () async {
            // Ambil status terbaru agar tampilan menyesuaikan (tunai / menunggu verifikasi).
            try {
              final res = await api.get('/bookings/mine');
              final mine = mapList(res['bookings'], Booking.fromJson).where((x) => x.id == b.id);
              if (mine.isNotEmpty && mounted) setState(() => _result = mine.first);
            } on ApiException {
              // biarkan tampilan apa adanya
            }
          },
        ),
      ]);
    }
    final text = b.status == 'menunggu_kedatangan'
        ? 'Silakan datang sesuai jadwal dan bayar tunai langsung di lokasi. Sampai jumpa di sanggar!'
        : b.status == 'menunggu_verifikasi'
            ? 'Terima kasih! Admin akan memverifikasi pembayaranmu dalam 1x24 jam.'
            : 'Permintaanmu sudah kami terima. Pantau statusnya di Akun > Pesanan Saya, admin akan menghubungimu lewat email/WhatsApp.';
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        StatusChip(b.status),
        const SizedBox(height: 8),
        Text(text),
      ]),
    );
  }
}

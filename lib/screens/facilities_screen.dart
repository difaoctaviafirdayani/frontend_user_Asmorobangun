import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api.dart';
import '../core/auth_state.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../core/validators.dart';
import '../models/models.dart';
import '../widgets/auth_ui.dart';
import '../widgets/common.dart';
import '../widgets/payment_section.dart';
import 'auth_screens.dart';

const _cardColor = Color(0xFFFDFAE8);

String _shortName(String name) =>
    name.replaceAll(RegExp(r'\s*\(.*\)'), '').trim();

class FacilitiesScreen extends StatelessWidget {
  const FacilitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Layanan Sanggar',
      backgroundColor: Colors.white,
      body: AsyncView<List<Facility>>(
        loader: () async => mapList(
          (await api.get('/facilities'))['facilities'],
          Facility.fromJson,
        ),
        builder: (context, items, _) => ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
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
    return Material(
      color: _cardColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.wood800, width: 1),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FacilityDetailScreen(id: f.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 10,
                child: AspectRatio(
                  aspectRatio: 1.6,
                  child: NetImage(
                    src: f.image,
                    width: double.infinity,
                    height: double.infinity,
                    radius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 9,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _shortName(f.name),
                            style: headingStyle(size: 16),
                          ),
                        ),
                        if (f.avgRating != null) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.gold400,
                            size: 18,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            f.avgRating!.toStringAsFixed(1),
                            style: const TextStyle(
                              color: AppColors.wood700,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      f.shortDesc,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.wood700,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
      title: 'Layanan Sanggar',
      backgroundColor: Colors.white,
      body: AsyncView<_FacilityData>(
        loader: () async {
          final res = await api.get('/facilities/$id');
          return _FacilityData(
            Facility.fromJson(res['facility'] as Map<String, dynamic>),
            mapList(res['reviews'], Review.fromJson),
          );
        },
        builder: (context, data, reload) =>
            _FacilityBody(data: data, reload: reload),
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: NetImage(
            src: f.image,
            width: double.infinity,
            height: double.infinity,
            radius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(_shortName(f.name), style: headingStyle(size: 24)),
            ),
            if (f.avgRating != null) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.star_rounded,
                color: AppColors.gold400,
                size: 22,
              ),
              const SizedBox(width: 3),
              Text(
                f.avgRating!.toStringAsFixed(1),
                style: const TextStyle(
                  color: AppColors.wood700,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          f.longDesc,
          style: const TextStyle(
            color: AppColors.wood800,
            fontSize: 13.5,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.paid_outlined,
              color: AppColors.wood800,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                f.priceInfo,
                style: const TextStyle(
                  color: AppColors.wood800,
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
        BookingForm(facility: f),
        const _Heading('Ulasan'),
        ReviewForm(facilityId: f.id, onSubmitted: reload),
        if (data.reviews.isEmpty)
          const EmptyState(
            'Jadilah yang pertama memberi ulasan.',
            icon: Icons.rate_review_outlined,
          )
        else
          for (var i = 0; i < data.reviews.length; i++)
            _ReviewItem(
              review: data.reviews[i],
              showDivider: i < data.reviews.length - 1,
            ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;
  const _Heading(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Text(text, style: headingStyle(size: 22)),
      );
}

class _FormCard extends StatelessWidget {
  final Widget child;
  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.wood700, width: 1),
        ),
        child: child,
      );
}

class _Gate extends StatelessWidget {
  final bool enabled;
  final Widget child;
  const _Gate({required this.enabled, required this.child});

  @override
  Widget build(BuildContext context) => IgnorePointer(
        ignoring: !enabled,
        child: Opacity(opacity: enabled ? 1 : 0.5, child: child),
      );
}

class _LoginNotice extends StatelessWidget {
  final VoidCallback onTap;
  const _LoginNotice({required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SizedBox(
          width: double.infinity,
          child: Material(
            color: const Color(0xFFFFEBC8),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: AppColors.wood700, width: 1),
            ),
            child: InkWell(
              onTap: onTap,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Text(
                  'Silakan daftar/masuk terlebih dahulu',
                  style: TextStyle(
                    color: AppColors.wood800,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _StarRow extends StatelessWidget {
  final int value;
  final double size;
  const _StarRow(this.value, {this.size = 20});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(
              i <= value ? Icons.star_rounded : Icons.star_border_rounded,
              size: size,
              color: AppColors.gold400,
            ),
        ],
      );
}

class _ReviewItem extends StatelessWidget {
  final Review review;
  final bool showDivider;
  const _ReviewItem({required this.review, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    final r = review;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  r.userName,
                  style: const TextStyle(
                    color: AppColors.wood800,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                formatDateLong(r.date),
                style: const TextStyle(
                  color: AppColors.wood700,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          _StarRow(r.rating),
          const SizedBox(height: 4),
          Text(
            r.comment,
            style: const TextStyle(
              color: AppColors.wood800,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          if (showDivider)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, thickness: 1, color: AppColors.wood700),
            ),
        ],
      ),
    );
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
  int _rating = 0;
  bool _busy = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating < 1) {
      showSnack(context, 'Pilih jumlah bintang dulu ya.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (!await ensureLogin(context)) return;
    setState(() => _busy = true);
    try {
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
      padding: const EdgeInsets.only(bottom: 18),
      child: _Gate(
        enabled: loggedIn,
        child: _FormCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Rating Anda',
                  style: TextStyle(
                    color: AppColors.wood700,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (var n = 1; n <= 5; n++)
                      GestureDetector(
                        onTap: () => setState(() => _rating = n),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            n <= _rating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 32,
                            color: n <= _rating
                                ? AppColors.gold400
                                : AppColors.wood800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                AuthField(
                  label: 'Komentar',
                  hint: 'Tulis komentar Anda di sini',
                  controller: _comment,
                  minLines: 1,
                  maxLines: 4,
                  inputFormatters: InputFormats.maxLen(500),
                  validator: Validators.text('Komentar', min: 3, max: 500),
                ),
                AuthButton(
                  label: 'Kirim Ulasan',
                  busy: _busy,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
  final _dateCtrl = TextEditingController();
  DateTime? _date;
  bool _busy = false;
  Booking? _result;

  Facility get f => widget.facility;
  bool get _needsPaymentNow => f.bookingType == 'wisata' || f.bookingType == 'rental';
  bool get _usesDatePicker => f.bookingType != 'reguler';

  @override
  void dispose() {
    for (final c in [_scheduleText, _notes, _eventType, _location, _guests, _qty, _dateCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _heading => f.bookingType == 'event'
      ? 'Ajukan ${_shortName(f.name)}'
      : const {
            'wisata': 'Daftar & bayar',
            'reguler': 'Formulir pendaftaran',
            'rental': 'Ajukan sewa',
          }[f.bookingType] ??
          'Daftar';

  String get _submitLabel => const {
        'wisata': 'Daftar & Bayar',
        'reguler': 'Kirim Pendaftaran',
        'rental': 'Ajukan Sewa',
        'event': 'Ajukan Permintaan',
      }[f.bookingType] ??
      'Kirim';

  String get _dateLabel => f.bookingType == 'rental'
      ? 'Tanggal Sewa'
      : f.bookingType == 'event'
          ? 'Tanggal Acara'
          : 'Tanggal Kunjungan';

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
    );
    if (d != null && mounted) {
      _date = d;
      _dateCtrl.text = _fmtDate(d);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!await ensureLogin(context)) return;

    final body = <String, dynamic>{
      'facilityId': f.id,
      'date': _usesDatePicker ? dateParam(_date!) : Validators.clean(_scheduleText.text),
      'notes': Validators.clean(_notes.text),
      'paymentMethod': _needsPaymentNow ? 'qris' : null,
    };
    if (f.bookingType == 'event') {
      body['eventType'] = Validators.clean(_eventType.text);
      body['location'] = Validators.clean(_location.text);
      final g = int.tryParse(_guests.text.trim());
      if (g != null) body['guestCount'] = g;
    }
    if (f.bookingType == 'wisata') body['guestCount'] = int.parse(_qty.text.trim());

    setState(() => _busy = true);
    try {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Heading(_heading),
        if (_result != null)
          _resultView(_result!)
        else ...[
          if (!loggedIn)
            _LoginNotice(onTap: () {
              ensureLogin(context);
            }),
          _form(loggedIn),
        ],
      ],
    );
  }

  Widget _form(bool loggedIn) {
    final type = f.bookingType;
    return _Gate(
      enabled: loggedIn,
      child: _FormCard(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (type == 'event')
                AuthField(
                  label: 'Jenis Acara',
                  hint: 'misalnya Pernikahan atau Festival',
                  boldLabel: false,
                  controller: _eventType,
                  inputFormatters: InputFormats.maxLen(80),
                  validator: Validators.text('Jenis acara', min: 3, max: 80),
                ),
              if (_usesDatePicker)
                AuthField(
                  label: _dateLabel,
                  hint: 'dd/mm/yyyy',
                  boldLabel: false,
                  controller: _dateCtrl,
                  readOnly: true,
                  onTap: _pickDate,
                  trailing: const Icon(
                    Icons.calendar_today_outlined,
                    size: 20,
                    color: AppColors.wood700,
                  ),
                  validator: (_) => _date == null ? 'Tanggal wajib dipilih' : null,
                )
              else
                AuthField(
                  label: 'Jadwal yang Diinginkan',
                  hint: 'mis. Sabtu sore, atau sesuai jadwal tersedia',
                  boldLabel: false,
                  controller: _scheduleText,
                  inputFormatters: InputFormats.maxLen(100),
                  validator: Validators.text('Jadwal', min: 3, max: 100),
                ),
              if (type == 'wisata')
                AuthField(
                  label: 'Jumlah Peserta',
                  boldLabel: false,
                  controller: _qty,
                  keyboardType: TextInputType.number,
                  inputFormatters: InputFormats.digitsOnly,
                  validator: Validators.integer('Jumlah peserta', min: 1, max: 50),
                ),
              if (type == 'event') ...[
                AuthField(
                  label: 'Lokasi Acara',
                  hint: 'Alamat lengkap',
                  boldLabel: false,
                  controller: _location,
                  minLines: 1,
                  maxLines: 3,
                  inputFormatters: InputFormats.maxLen(200),
                  validator: Validators.text('Lokasi acara', min: 5, max: 200),
                ),
                AuthField(
                  label: 'Perkiraan Jumlah Audiens',
                  hint: 'mis. 100 orang (opsional)',
                  boldLabel: false,
                  controller: _guests,
                  keyboardType: TextInputType.number,
                  inputFormatters: InputFormats.digitsOnly,
                  validator: Validators.integer('Jumlah tamu', min: 1, max: 5000, required: false),
                ),
              ],
              if (type != 'wisata')
                AuthField(
                  label: type == 'rental'
                      ? 'Karakter / Ukuran Kostum'
                      : (type == 'event' ? 'Catatan Tambahan' : 'Catatan (usia, pengalaman, dll)'),
                  hint: type == 'rental'
                      ? 'mis. Kostum Panji, ukuran M'
                      : (type == 'event' ? 'Durasi, lakon yang diinginkan, dll' : 'Ceritakan sedikit tentang dirimu'),
                  boldLabel: false,
                  controller: _notes,
                  minLines: 1,
                  maxLines: 3,
                  inputFormatters: InputFormats.maxLen(500),
                  validator: Validators.text('Catatan', min: 2, max: 500, required: type == 'rental'),
                ),
              if (type != 'event')
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    _hint(),
                    style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5),
                  ),
                ),
              AuthButton(label: _submitLabel, busy: _busy, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }

  String _hint() {
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
            try {
              final res = await api.get('/bookings/mine');
              final mine = mapList(res['bookings'], Booking.fromJson).where((x) => x.id == b.id);
              if (mine.isNotEmpty && mounted) setState(() => _result = mine.first);
            } on ApiException {}
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
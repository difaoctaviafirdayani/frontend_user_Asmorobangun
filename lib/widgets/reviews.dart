import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/picker.dart';
import '../core/theme.dart';
import '../models/models.dart';
import 'common.dart';

const _fill = Color(0xFFFDFBE8);
const _brownBtn = Color(0xFF5C3724);

/// Deretan bintang (hanya tampilan).
class StarRow extends StatelessWidget {
  final int value;
  final double size;
  const StarRow(this.value, {super.key, this.size = 18});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(i <= value ? Icons.star_rounded : Icons.star_border_rounded, size: size, color: AppColors.gold400),
        ],
      );
}

/// Satu ulasan di halaman layanan dan katalog topeng (hanya dibaca).
class ReviewTile extends StatelessWidget {
  final Review review;
  final bool showDivider;
  const ReviewTile({super.key, required this.review, this.showDivider = true});

  @override
  Widget build(BuildContext context) {
    final r = review;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Text(r.userName,
                style: const TextStyle(color: AppColors.wood800, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          Text(formatDateLong(r.date), style: const TextStyle(color: AppColors.wood700, fontSize: 11.5)),
        ]),
        const SizedBox(height: 2),
        StarRow(r.rating),
        const SizedBox(height: 4),
        Text(r.comment, style: const TextStyle(color: AppColors.wood800, fontSize: 13.5, height: 1.45)),
        if ((r.image ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          NetImage(src: r.image, width: 110, height: 110, radius: BorderRadius.circular(8)),
        ],
        if (showDivider)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 1, color: AppColors.wood700),
          ),
      ]),
    );
  }
}

/// Daftar ulasan + teks kosong. Dipakai di layanan dan topeng.
class ReviewList extends StatelessWidget {
  final List<Review> reviews;
  const ReviewList(this.reviews, {super.key});

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const EmptyState('Belum ada ulasan.', icon: Icons.rate_review_outlined);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (var i = 0; i < reviews.length; i++) ReviewTile(review: reviews[i], showDivider: i < reviews.length - 1),
    ]);
  }
}

/// Dialog "Berikan Pengalamanmu". Dibuka dari Pesanan Saya setelah pesanan/booking selesai.
/// [basePath] contoh: /bookings/bk-123/review atau /topeng/orders/ord-123/review.
/// Bila [existing] diisi, dialog menjadi mode edit (ada tombol Hapus dan Simpan).
/// Mengembalikan true kalau ada perubahan (kirim, simpan, atau hapus).
Future<bool> showReviewDialog(BuildContext context, {required String basePath, Review? existing}) async {
  final changed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ReviewDialog(basePath: basePath, existing: existing),
  );
  return changed == true;
}

class _ReviewDialog extends StatefulWidget {
  final String basePath;
  final Review? existing;
  const _ReviewDialog({required this.basePath, this.existing});

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  late int _rating = widget.existing?.rating ?? 0;
  late final _comment = TextEditingController(text: widget.existing?.comment ?? '');
  ({List<int> bytes, String name})? _picked;
  bool _removeImage = false;
  bool _busy = false;
  String? _error;

  bool get _editing => widget.existing != null;
  bool get _hasOldImage => (widget.existing?.image ?? '').isNotEmpty && !_removeImage;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final f = await pickImageFile();
    if (f == null) return;
    if (f.bytes.length > 5 * 1024 * 1024) {
      setState(() => _error = 'Ukuran foto maksimal 5MB.');
      return;
    }
    setState(() {
      _picked = f;
      _error = null;
    });
  }

  Future<void> _submit() async {
    final text = _comment.text.trim();
    if (_rating < 1) return setState(() => _error = 'Pilih jumlah bintang dulu ya.');
    if (text.length < 3) return setState(() => _error = 'Komentar minimal 3 karakter.');
    setState(() {
      _busy = true;
      _error = null;
    });
    final body = {'rating': _rating, 'comment': text};
    try {
      if (_editing) {
        await api.put(widget.basePath, body: body);
      } else {
        await api.post(widget.basePath, body: body);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() {
        _busy = false;
        _error = e.message;
      });
      return;
    }

    // Ulasan sudah tersimpan. Foto bersifat opsional, jadi kegagalannya tidak membatalkan ulasan.
    String message = _editing ? 'Ulasan diperbarui.' : 'Ulasan terkirim, makasih!';
    try {
      if (_picked != null) {
        await api.upload('${widget.basePath}/image', field: 'image', bytes: _picked!.bytes, filename: _picked!.name);
      } else if (_removeImage && (widget.existing?.image ?? '').isNotEmpty) {
        await api.delete('${widget.basePath}/image');
      }
    } on ApiException catch (e) {
      message = 'Ulasan tersimpan, tapi foto gagal diunggah: ${e.message}';
    }
    if (!mounted) return;
    showSnack(context, message);
    Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    if (!await confirmDialog(context, 'Hapus ulasan ini?', okLabel: 'Hapus')) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await api.delete(widget.basePath);
      if (!mounted) return;
      showSnack(context, 'Ulasan dihapus.');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() {
        _busy = false;
        _error = e.message;
      });
    }
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.wood900)),
      );

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.wood700, width: 1),
    );
    return Dialog(
      backgroundColor: _fill,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.wood700, width: 1),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              const SizedBox(width: 32),
              const Expanded(
                child: Text('Berikan Pengalamanmu',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.wood900)),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Tutup',
                onPressed: _busy ? null : () => Navigator.pop(context, false),
                icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.wood900),
              ),
            ]),
            _label('Rating Anda'),
            Row(children: [
              for (var n = 1; n <= 5; n++)
                GestureDetector(
                  onTap: _busy ? null : () => setState(() => _rating = n),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(n <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 30, color: n <= _rating ? AppColors.gold400 : AppColors.wood800),
                  ),
                ),
            ]),
            _label('Komentar'),
            TextField(
              controller: _comment,
              enabled: !_busy,
              minLines: 2,
              maxLines: 4,
              maxLength: 500,
              style: const TextStyle(fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Tulis komentarmu di sini',
                hintStyle: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
                counterText: '',
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: border,
                enabledBorder: border,
                focusedBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.gold400, width: 2)),
              ),
            ),
            _label('Gambar (Opsional)'),
            if (_hasOldImage && _picked == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  NetImage(src: widget.existing!.image, width: 64, height: 64, radius: BorderRadius.circular(8)),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _busy ? null : () => setState(() => _removeImage = true),
                    child: const Text('Hapus foto', style: TextStyle(fontSize: 12.5)),
                  ),
                ]),
              ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.wood900,
                side: const BorderSide(color: AppColors.wood700, width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: _busy ? null : _pick,
              icon: const Icon(Icons.file_upload_outlined, size: 18),
              label: Text(_picked?.name ?? 'Pilih file',
                  overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400)),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
              ),
            const SizedBox(height: 16),
            if (_editing)
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger, width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    onPressed: _busy ? null : _delete,
                    child: const Text('Hapus', style: TextStyle(fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: _primary('Simpan')),
              ])
            else
              _primary('Kirim Ulasan'),
          ]),
        ),
      ),
    );
  }

  Widget _primary(String label) => ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _brownBtn,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 11),
        ),
        onPressed: _busy ? null : _submit,
        child: Text(_busy ? 'Memproses...' : label, style: const TextStyle(fontSize: 14)),
      );
}
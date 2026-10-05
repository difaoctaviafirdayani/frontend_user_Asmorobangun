import 'package:flutter/material.dart';

import 'config.dart';
import 'theme.dart';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

String formatRupiah(num? n) {
  if (n == null) return '-';
  final s = n.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final fromEnd = s.length - i;
    buf.write(s[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buf.write('.');
  }
  return 'Rp $buf';
}

String formatDate(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final d = DateTime.tryParse(iso);
  if (d == null) return iso; // mis. "Sabtu sore" pada pendaftaran reguler
  final l = d.toLocal();
  return '${l.day} ${_months[l.month - 1]} ${l.year}';
}

String dateParam(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Gambar bisa berupa URL penuh, data URL (QRIS simulasi), path /uploads/...,
/// atau nama file lama dari data seed (dilayani backend di /app/assets).
String assetUrl(String? image) {
  if (image == null || image.isEmpty) return '';
  if (image.startsWith('http')) return image;
  if (image.startsWith('/')) return '${AppConfig.origin}$image';
  return '${AppConfig.origin}/app/assets/$image';
}

/// (label, warna) untuk chip status booking & pesanan.
(String, Color) statusInfo(String status) {
  const labels = {
    'menunggu_pembayaran': 'Menunggu Pembayaran',
    'menunggu_verifikasi': 'Menunggu Verifikasi',
    'menunggu_kedatangan': 'Menunggu Kedatangan',
    'menunggu_konfirmasi_admin': 'Menunggu Konfirmasi',
    'dikonfirmasi': 'Dikonfirmasi',
    'diproses': 'Diproses',
    'dikirim': 'Dikirim',
    'selesai': 'Selesai',
    'ditolak': 'Ditolak',
  };
  final label = labels[status] ?? status;
  Color color = AppColors.wait;
  if (status == 'dikonfirmasi' || status == 'selesai' || status == 'dikirim') color = AppColors.ok;
  if (status == 'ditolak') color = AppColors.danger;
  return (label, color);
}

String methodLabel(String? m) =>
    const {'qris': 'QRIS', 'transfer': 'Transfer Bank', 'cash': 'Tunai'}[m] ?? '-';

import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

import '../widgets/common.dart';

String? detectImageType(List<int> b) {
  bool starts(List<int> p) {
    if (b.length < p.length) return false;
    for (var i = 0; i < p.length; i++) {
      if (b[i] != p[i]) return false;
    }
    return true;
  }

  if (b.length < 12) return null;
  if (starts([0xFF, 0xD8, 0xFF])) return 'jpg';
  if (starts([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) return 'png';
  if (starts([0x47, 0x49, 0x46, 0x38])) return 'gif';
  if (starts([0x52, 0x49, 0x46, 0x46]) && b[8] == 0x57 && b[9] == 0x45 && b[10] == 0x42 && b[11] == 0x50) return 'webp';
  return null;
}

Future<({List<int> bytes, String name})?> pickImageFile() async {
  final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1800, imageQuality: 85);
  if (x == null) return null;
  return (bytes: await x.readAsBytes(), name: x.name);
}

Future<({List<int> bytes, String name})?> pickValidImage(
  BuildContext context, {
  bool allowGif = true,
  void Function(String message)? onInvalid,
}) async {
  final f = await pickImageFile();
  if (f == null) return null;
  final type = detectImageType(f.bytes);
  if (type == null || (type == 'gif' && !allowGif)) {
    final list = allowGif ? 'JPG, PNG, WEBP, atau GIF' : 'JPG, PNG, atau WEBP';
    final msg = 'Gagal upload: format foto tidak didukung. Gunakan $list.';
    if (context.mounted) showSnack(context, msg);
    onInvalid?.call(msg);
    return null;
  }
  final base = f.name.contains('.') ? f.name.substring(0, f.name.lastIndexOf('.')) : f.name;
  return (bytes: f.bytes, name: '$base.$type');
}
import 'package:image_picker/image_picker.dart';

/// Pilih foto dari galeri. Nama file dipastikan berekstensi gambar karena backend
/// memfilter upload berdasarkan ekstensi (jpg, png, webp, gif, pdf).
Future<({List<int> bytes, String name})?> pickImageFile() async {
  final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1800, imageQuality: 85);
  if (x == null) return null;
  final bytes = await x.readAsBytes();
  var name = x.name;
  if (!RegExp(r'\.(jpe?g|png|webp|gif)$', caseSensitive: false).hasMatch(name)) {
    name = '$name.jpg';
  }
  return (bytes: bytes, name: name);
}

import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Picks an image from the gallery and copies it into app storage so the
/// path stays valid across restarts. Returns null when unavailable/denied.
class MediaPickerService {
  static Future<String?> pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return null;
      final directory = await getApplicationDocumentsDirectory();
      final extension = picked.name.contains('.')
          ? picked.name.split('.').last
          : 'jpg';
      final target = File(
        '${directory.path}/ig_${DateTime.now().microsecondsSinceEpoch}.$extension',
      );
      return (await File(picked.path).copy(target.path)).path;
    } catch (_) {
      return null;
    }
  }
}

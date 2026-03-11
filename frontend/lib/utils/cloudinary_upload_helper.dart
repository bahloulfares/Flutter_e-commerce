import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

class CloudinaryUploadHelper {
  static const String _cloudName = 'dymt4nyul';
  static const String _uploadPreset = 'koyuqu3d';

  static Future<String> uploadImage(
    XFile file, {
    List<int>? bytes,
  }) async {
    final fileBytes = bytes ?? await file.readAsBytes();
    final fileName = file.name.isNotEmpty ? file.name : p.basename(file.path);

    final formData = FormData.fromMap({
      'upload_preset': _uploadPreset,
      'file': MultipartFile.fromBytes(
        fileBytes,
        filename: fileName,
      ),
    });

    final response = await Dio().post(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      data: formData,
    );

    final secureUrl = response.data['secure_url']?.toString() ?? '';
    if (secureUrl.isEmpty) {
      throw Exception('Réponse Cloudinary invalide');
    }

    return secureUrl;
  }
}

import 'package:file_picker/file_picker.dart';
import 'permission_service.dart';

class AudioPickResult {
  final String path;
  final String name;

  AudioPickResult({required this.path, required this.name});
}

class AudioPickerService {
  static Future<AudioPickResult?> pickAudioFile() async {
    try {
      // Ensure storage/audio permissions are granted
      await PermissionService.requestStoragePermission();

      final file = await FilePicker.pickFile(
        type: FileType.audio,
      );

      if (file != null && file.path != null) {
        return AudioPickResult(
          path: file.path!,
          name: file.name,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

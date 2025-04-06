class FileUtils {
  static String formatFileSize(int bytes) {
    const int kb = 1024;
    const int mb = kb * 1024;
    const int gb = mb * 1024;

    if (bytes < kb) {
      return '$bytes B';
    } else if (bytes < mb) {
      final double size = bytes / kb;
      return '${size.toStringAsFixed(1)} KB';
    } else if (bytes < gb) {
      final double size = bytes / mb;
      return '${size.toStringAsFixed(1)} MB';
    } else {
      final double size = bytes / gb;
      return '${size.toStringAsFixed(1)} GB';
    }
  }

  static String getFileIconName(String? extension) {
    if (extension == null) return 'file';

    switch (extension.toLowerCase()) {
      case 'dart':
        return 'dart';
      case 'json':
        return 'json';
      case 'yaml':
      case 'yml':
        return 'yaml';
      case 'md':
        return 'markdown';
      case 'txt':
        return 'text';
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'bmp':
      case 'svg':
        return 'image';
      case 'pdf':
        return 'pdf';
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return 'archive';
      case 'mp3':
      case 'wav':
      case 'aac':
      case 'flac':
        return 'audio';
      case 'mp4':
      case 'avi':
      case 'mkv':
      case 'mov':
        return 'video';
      case 'html':
      case 'htm':
        return 'html';
      case 'css':
        return 'css';
      case 'js':
        return 'javascript';
      case 'ts':
        return 'typescript';
      case 'xml':
        return 'xml';
      case 'java':
        return 'java';
      case 'py':
        return 'python';
      case 'rb':
        return 'ruby';
      case 'c':
      case 'cpp':
      case 'h':
        return 'c';
      case 'cs':
        return 'csharp';
      case 'go':
        return 'go';
      case 'php':
        return 'php';
      case 'swift':
        return 'swift';
      case 'kt':
        return 'kotlin';
      case 'rs':
        return 'rust';
      case 'sh':
        return 'shell';
      case 'bat':
      case 'cmd':
        return 'batch';
      case 'sql':
        return 'sql';
      case 'psd':
        return 'photoshop';
      case 'ai':
        return 'illustrator';
      case 'doc':
      case 'docx':
        return 'word';
      case 'xls':
      case 'xlsx':
        return 'excel';
      case 'ppt':
      case 'pptx':
        return 'powerpoint';
      default:
        return 'file';
    }
  }

  static bool isCodeFile(String? extension) {
    if (extension == null) return false;

    final codeExtensions = [
      'dart', 'java', 'js', 'ts', 'py', 'rb', 'c', 'cpp', 'h', 'cs', 'go',
      'php', 'swift', 'kt', 'rs', 'sh', 'bat', 'cmd', 'sql', 'html', 'htm',
      'css', 'xml', 'yaml', 'yml', 'json', 'md', 'txt'
    ];

    return codeExtensions.contains(extension.toLowerCase());
  }

  static bool isImageFile(String? extension) {
    if (extension == null) return false;

    final imageExtensions = [
      'png', 'jpg', 'jpeg', 'gif', 'bmp', 'svg', 'webp', 'tiff'
    ];

    return imageExtensions.contains(extension.toLowerCase());
  }
}
// lib/providers/code_summary_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

// Summary options state
class SummaryOptions {
  final List<String> excludedFolders;
  final List<String> excludedFiles; 
  final List<String> excludedExtensions;
  final bool removeImports;
  final bool removeComments;
  final bool removeEmptyLines;

  SummaryOptions({
    this.excludedFolders = const ['node_modules', 'build', '.git', '.dart_tool'],
    this.excludedFiles = const ['firebase_options.dart'],
    this.excludedExtensions = const ['png', 'jpg', 'jpeg', 'gif', 'ttf', 'woff', 'woff2'],
    this.removeImports = true,
    this.removeComments = false,
    this.removeEmptyLines = true,
  });

  SummaryOptions copyWith({
    List<String>? excludedFolders,
    List<String>? excludedFiles,
    List<String>? excludedExtensions,
    bool? removeImports,
    bool? removeComments,
    bool? removeEmptyLines,
  }) {
    return SummaryOptions(
      excludedFolders: excludedFolders ?? this.excludedFolders,
      excludedFiles: excludedFiles ?? this.excludedFiles,
      excludedExtensions: excludedExtensions ?? this.excludedExtensions,
      removeImports: removeImports ?? this.removeImports,
      removeComments: removeComments ?? this.removeComments,
      removeEmptyLines: removeEmptyLines ?? this.removeEmptyLines,
    );
  }
}

// Summary options notifier
class SummaryOptionsNotifier extends StateNotifier<SummaryOptions> {
  SummaryOptionsNotifier() : super(SummaryOptions());

  void addExcludedFolder(String folder) {
    state = state.copyWith(
      excludedFolders: [...state.excludedFolders, folder],
    );
  }

  void removeExcludedFolder(String folder) {
    state = state.copyWith(
      excludedFolders: state.excludedFolders.where((f) => f != folder).toList(),
    );
  }

  void addExcludedFile(String file) {
    state = state.copyWith(
      excludedFiles: [...state.excludedFiles, file],
    );
  }

  void removeExcludedFile(String file) {
    state = state.copyWith(
      excludedFiles: state.excludedFiles.where((f) => f != file).toList(),
    );
  }

  void addExcludedExtension(String extension) {
    state = state.copyWith(
      excludedExtensions: [...state.excludedExtensions, extension],
    );
  }

  void removeExcludedExtension(String extension) {
    state = state.copyWith(
      excludedExtensions: state.excludedExtensions.where((e) => e != extension).toList(),
    );
  }

  void setRemoveImports(bool value) {
    state = state.copyWith(removeImports: value);
  }

  void setRemoveComments(bool value) {
    state = state.copyWith(removeComments: value);
  }

  void setRemoveEmptyLines(bool value) {
    state = state.copyWith(removeEmptyLines: value);
  }
}

// Summary generation state
class SummaryState {
  final bool isGenerating;
  final String? summary;
  final String? error;
  final double fontSize;

  SummaryState({
    this.isGenerating = false,
    this.summary,
    this.error,
    this.fontSize = 12.0,
  });

  SummaryState copyWith({
    bool? isGenerating,
    String? summary,
    String? error,
    double? fontSize,
  }) {
    return SummaryState(
      isGenerating: isGenerating ?? this.isGenerating,
      summary: summary ?? this.summary,
      error: error != null ? error : this.error,
      fontSize: fontSize ?? this.fontSize,
    );
  }
}

// Summary generation notifier
class SummaryGeneratorNotifier extends StateNotifier<SummaryState> {
  SummaryGeneratorNotifier() : super(SummaryState());

  void reset() {
    state = SummaryState();
  }

  Future<void> generateSummary(String directoryPath, SummaryOptions options) async {
    state = SummaryState(isGenerating: true);

    try {
      final summary = await _processDirectory(directoryPath, options);
      state = SummaryState(summary: summary);
    } catch (e) {
      state = SummaryState(error: 'Error generating summary: ${e.toString()}');
    }
  }

  Future<String> _processDirectory(String directoryPath, SummaryOptions options) async {
    final StringBuffer buffer = StringBuffer();
    
    buffer.writeln('CODE SUMMARY - Generated ${DateTime.now().toString()}');
    buffer.writeln('===================================================');
    buffer.writeln('Directory: $directoryPath');
    buffer.writeln('Excluded folders: ${options.excludedFolders.join(', ')}');
    buffer.writeln('Excluded files: ${options.excludedFiles.join(', ')}');
    buffer.writeln('Excluded extensions: ${options.excludedExtensions.join(', ')}');
    buffer.writeln('===================================================\n');
    
    final directory = Directory(directoryPath);
    await _processDirectoryRecursively(directory, buffer, '', options);
    
    return buffer.toString();
  }
  
  Future<void> _processDirectoryRecursively(
    Directory directory, 
    StringBuffer buffer,
    String relativePath,
    SummaryOptions options,
  ) async {
    final entities = await directory.list().toList();
    
    // Process all files first (more readable in summary)
    for (final entity in entities) {
      if (entity is File) {
        final basename = path.basename(entity.path);
        final extension = path.extension(basename).isNotEmpty 
            ? path.extension(basename).substring(1)
            : null;
            
        // Skip excluded files and extensions
        if (options.excludedFiles.contains(basename)) continue;
        if (extension != null && options.excludedExtensions.contains(extension)) continue;
        
        // Add file to summary
        await _processFile(entity, buffer, path.join(relativePath, basename), options);
      }
    }
    
    // Then process subdirectories
    for (final entity in entities) {
      if (entity is Directory) {
        final dirname = path.basename(entity.path);
        
        // Skip excluded directories
        if (options.excludedFolders.contains(dirname)) continue;
        
        // Process subdirectory
        await _processDirectoryRecursively(
          entity, 
          buffer, 
          path.join(relativePath, dirname),
          options,
        );
      }
    }
  }
  
  Future<void> _processFile(
    File file, 
    StringBuffer buffer, 
    String relativePath,
    SummaryOptions options,
  ) async {
    try {
      final content = await file.readAsString();
      
      buffer.writeln('\n----- $relativePath -----');
      
      final lines = content.split('\n');
      bool lastLineWasEmpty = false;
      
      for (final line in lines) {
        final trimmedLine = line.trim();
        
        // Skip import statements if configured
        if (options.removeImports && trimmedLine.startsWith('import ')) {
          continue;
        }
        
        // Skip comments if configured
        if (options.removeComments && (trimmedLine.startsWith('//') || 
                               trimmedLine.startsWith('/*') || 
                               trimmedLine.startsWith('*'))) {
          continue;
        }
        
        // Handle empty lines
        if (trimmedLine.isEmpty) {
          if (options.removeEmptyLines && lastLineWasEmpty) {
            continue;
          }
          lastLineWasEmpty = true;
        } else {
          lastLineWasEmpty = false;
        }
        
        buffer.writeln(line);
      }
    } catch (e) {
      buffer.writeln('\n/* Error processing file $relativePath: ${e.toString()} */');
    }
  }

  void increaseFontSize() {
    if (state.fontSize < 24) {
      state = state.copyWith(fontSize: state.fontSize + 1);
    }
  }

  void decreaseFontSize() {
    if (state.fontSize > 8) {
      state = state.copyWith(fontSize: state.fontSize - 1);
    }
  }
}

// Providers
final summaryOptionsProvider = StateNotifierProvider<SummaryOptionsNotifier, SummaryOptions>((ref) {
  return SummaryOptionsNotifier();
});

final summaryGeneratorProvider = StateNotifierProvider<SummaryGeneratorNotifier, SummaryState>((ref) {
  return SummaryGeneratorNotifier();
});
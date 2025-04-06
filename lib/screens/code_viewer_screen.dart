import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../../services/file_service.dart';
import '../../utils/file_utils.dart';

final codeProvider = FutureProvider.family<String, String>((ref, filePath) async {
  final fileService = FileService();
  return fileService.readFileAsString(filePath);
});

class CodeViewerScreen extends ConsumerStatefulWidget {
  final String filePath;
  
  const CodeViewerScreen({
    super.key, 
    required this.filePath,
  });

  @override
  ConsumerState createState() => _CodeViewerScreenState();
}

class _CodeViewerScreenState extends ConsumerState<CodeViewerScreen> {
  bool _showLineNumbers = true;
  bool _wordWrap = false;
  double _fontSize = 14.0;
  
  @override
  Widget build(BuildContext context) {
    final codeAsync = ref.watch(codeProvider(widget.filePath));
    final fileName = path.basename(widget.filePath);
    final extension = path.extension(fileName).isNotEmpty
        ? path.extension(fileName).substring(1)
        : null;
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(fileName),
            Text(
              widget.filePath,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          _buildAppBarActions(codeAsync),
        ],
      ),
      body: codeAsync.when(
        data: (code) => _buildCodeViewer(context, code, extension),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error reading file',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(error.toString()),
            ],
          ),
        ),
      ),
    );
  }
  
  // Updated _buildAppBarActions in code_viewer_screen.dart:

Widget _buildAppBarActions(AsyncValue<String> codeAsync) {
  return Row(
    children: [
      IconButton(
        icon: Icon(_wordWrap ? Icons.wrap_text : Icons.wrap_text_outlined),
        tooltip: _wordWrap ? 'Disable word wrap' : 'Enable word wrap',
        onPressed: () {
          setState(() {
            _wordWrap = !_wordWrap;
          });
        },
      ),
      IconButton(
        icon: Icon(_showLineNumbers ? Icons.numbers : Icons.numbers_outlined),
        tooltip: _showLineNumbers ? 'Hide line numbers' : 'Show line numbers',
        onPressed: () {
          setState(() {
            _showLineNumbers = !_showLineNumbers;
          });
        },
      ),
      PopupMenuButton(
        icon: const Icon(Icons.text_fields),
        tooltip: 'Font size',
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 12.0,
            child: Text('Small (12px)'),
          ),
          const PopupMenuItem(
            value: 14.0,
            child: Text('Medium (14px)'),
          ),
          const PopupMenuItem(
            value: 16.0,
            child: Text('Large (16px)'),
          ),
          const PopupMenuItem(
            value: 18.0,
            child: Text('Extra Large (18px)'),
          ),
        ],
        onSelected: (value) {
          setState(() {
            _fontSize = value;
          });
        },
      ),
      // Make the copy button more prominent
      ElevatedButton.icon(
        icon: const Icon(Icons.copy),
        label: const Text('Copy Code'),
        onPressed: () {
          codeAsync.whenData((code) {
            Clipboard.setData(ClipboardData(text: code));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Copied to clipboard')),
            );
          });
        },
      ),
      const SizedBox(width: 8),
      IconButton(
        icon: const Icon(Icons.download),
        tooltip: 'Export with comments',
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Export feature coming soon')),
          );
        },
      ),
    ],
  );
}

  Widget _buildCodeViewer(BuildContext context, String code, String? extension) {
    if (!FileUtils.isCodeFile(extension)) {
      // For non-code files, provide a simple preview
      if (FileUtils.isImageFile(extension)) {
        return _buildImageViewer();
      } else {
        return _buildGenericFileViewer(code);
      }
    }

    // Code viewer
    return Column(
      children: [
        _buildFileInfoBar(code),
        Expanded(
          child: _buildCodeScrollView(context, code),
        ),
      ],
    );
  }

  Widget _buildFileInfoBar(String code) {
    final lineCount = '\n'.allMatches(code).length + 1;
    final charCount = code.length;
    final fileSize = FileUtils.formatFileSize(File(widget.filePath).lengthSync());
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16),
          const SizedBox(width: 8),
          Text('$lineCount lines'),
          const SizedBox(width: 24),
          Text('$charCount characters'),
          const SizedBox(width: 24),
          Text(fileSize),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildCodeScrollView(BuildContext context, String code) {
    final lines = code.split('\n');
    
    // If word wrap is enabled, use a different layout
    if (_wordWrap) {
      return Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line numbers (if enabled)
                if (_showLineNumbers)
                  Container(
                    width: 64,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2D2D2D)
                        : const Color(0xFFF0F0F0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (int i = 0; i < lines.length; i++)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: _fontSize - 2,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                
                // Code content
                Expanded(
                  child: Container(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E1E1E)
                        : Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < lines.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            child: SelectableText(
                              lines[i],
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: _fontSize,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // No word wrap - horizontal scrolling
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E1E1E)
                : Colors.white,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line numbers (if enabled)
                if (_showLineNumbers)
                  Container(
                    width: 64,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2D2D2D)
                        : const Color(0xFFF0F0F0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (int i = 0; i < lines.length; i++)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: _fontSize - 2,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                
                // Code content
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < lines.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        child: SelectableText(
                          lines[i],
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: _fontSize,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageViewer() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
              margin: const EdgeInsets.all(16),
              child: Image.file(
                File(widget.filePath),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(Icons.broken_image, size: 64),
                        SizedBox(height: 16),
                        Text('Unable to load image'),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Image: ${path.basename(widget.filePath)}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenericFileViewer(String content) {
    // Simple preview for non-code files
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This file type may not display correctly in the code viewer.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: SelectableText(
                content,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: _fontSize,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
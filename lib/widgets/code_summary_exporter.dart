// lib/widgets/code_summary_exporter.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:project_summarise/widgets/optimized_text_viewer.dart';
import 'dart:io';
import '../providers/code_summary_provider.dart';

class CodeSummaryExporter extends ConsumerWidget {
  final String directoryPath;

  const CodeSummaryExporter({
    super.key,
    required this.directoryPath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryOptions = ref.watch(summaryOptionsProvider);
    final summaryState = ref.watch(summaryGeneratorProvider);
    
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 800,
          maxHeight: 600,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Code Summary Generator',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: summaryState.summary != null
                    ? _buildSummaryPreview(context, summaryState, ref)
                    : _buildExportForm(context, ref, summaryOptions, summaryState),
              ),
              if (summaryState.summary != null)
                const Divider(),
              if (summaryState.summary != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        ref.read(summaryGeneratorProvider.notifier).reset();
                      },
                      child: const Text('Back to Settings'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy to Clipboard'),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: summaryState.summary!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Summary copied to clipboard')),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text('Save to File'),
                      onPressed: () => _saveToFile(context, summaryState.summary!),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportForm(
    BuildContext context, 
    WidgetRef ref, 
    SummaryOptions options,
    SummaryState summaryState,
  ) {
    final folderController = TextEditingController();
    final fileController = TextEditingController();
    final extensionController = TextEditingController();
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side - Options
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Source Directory:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(directoryPath),
              const SizedBox(height: 16),
              
              Text(
                'Processing Options:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text('Remove import statements'),
                subtitle: const Text('Strip import lines from code'),
                value: options.removeImports,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(summaryOptionsProvider.notifier).setRemoveImports(value);
                  }
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Remove comments'),
                subtitle: const Text('Strip comments from code'),
                value: options.removeComments,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(summaryOptionsProvider.notifier).setRemoveComments(value);
                  }
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Remove empty lines'),
                subtitle: const Text('Strip consecutive empty lines'),
                value: options.removeEmptyLines,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(summaryOptionsProvider.notifier).setRemoveEmptyLines(value);
                  }
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              
              if (summaryState.isGenerating)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
                
              if (summaryState.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    summaryState.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                
              const Spacer(),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: summaryState.isGenerating 
                      ? null 
                      : () => ref.read(summaryGeneratorProvider.notifier)
                          .generateSummary(directoryPath, options),
                    child: const Text('Generate Summary'),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 24),
        
        // Right side - Exclusion lists
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Excluded Folders:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _buildExclusionList(
                  context,
                  ref,
                  options.excludedFolders,
                  folderController,
                  'Add folder name',
                  (text) {
                    ref.read(summaryOptionsProvider.notifier).addExcludedFolder(text);
                    folderController.clear();
                  },
                  (item) {
                    ref.read(summaryOptionsProvider.notifier).removeExcludedFolder(item);
                  },
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Excluded Files:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _buildExclusionList(
                  context,
                  ref,
                  options.excludedFiles,
                  fileController,
                  'Add file name',
                  (text) {
                    ref.read(summaryOptionsProvider.notifier).addExcludedFile(text);
                    fileController.clear();
                  },
                  (item) {
                    ref.read(summaryOptionsProvider.notifier).removeExcludedFile(item);
                  },
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Excluded Extensions:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _buildExclusionList(
                  context,
                  ref,
                  options.excludedExtensions,
                  extensionController,
                  'Add extension',
                  (text) {
                    ref.read(summaryOptionsProvider.notifier).addExcludedExtension(text);
                    extensionController.clear();
                  },
                  (item) {
                    ref.read(summaryOptionsProvider.notifier).removeExcludedExtension(item);
                  },
                ),
                
                // Add padding at the bottom to ensure last items are visible when scrolling
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildExclusionList(
    BuildContext context,
    WidgetRef ref,
    List<String> items, 
    TextEditingController controller, 
    String hint,
    Function(String) onAdd,
    Function(String) onRemove,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 100,
          child: items.isEmpty
              ? const Center(child: Text('No exclusions added'))
              : Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        child: Row(
                          children: [
                            Expanded(child: Text(items[index])),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => onRemove(items[index]),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: hint,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  onAdd(controller.text);
                }
              },
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildSummaryPreview(BuildContext context, SummaryState summaryState,WidgetRef ref) {
    if (summaryState.isGenerating) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (summaryState.error != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          summaryState.error!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
    
    if (summaryState.summary == null) {
      return const Center(child: Text('No summary generated'));
    }
  final summary = summaryState.summary!;
  final fontSize = summaryState.fontSize;
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Generated Summary',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                tooltip: 'Copy all content',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: summary));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.text_decrease, size: 20),
                tooltip: 'Decrease font size',
                onPressed: () {
                  ref.read(summaryGeneratorProvider.notifier).decreaseFontSize();
                },
              ),
              Text(
                '${fontSize.toInt()}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.text_increase, size: 20),
                tooltip: 'Increase font size',
                onPressed: () {
                  ref.read(summaryGeneratorProvider.notifier).increaseFontSize();
                },
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 8),
      Expanded(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(4),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: OptimizedTextViewer(
            text: summary,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: fontSize,
            ),
          ),
        ),
      ),
    ],
  );
}
  
  Future<void> _saveToFile(BuildContext context, String summary) async {
    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Code Summary',
      fileName: 'code_summary_${DateTime.now().millisecondsSinceEpoch}.txt',
      allowedExtensions: ['txt'],
      type: FileType.custom,
    );

    if (outputPath == null) return;

    try {
      final file = File(outputPath);
      await file.writeAsString(summary);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Summary saved to $outputPath')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving file: ${e.toString()}')),
        );
      }
    }
  }
}
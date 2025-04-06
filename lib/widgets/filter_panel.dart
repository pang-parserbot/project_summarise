import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_summarise/models/filter_options.dart';
import '../../providers/filter_provider.dart';

class FilterPanel extends ConsumerStatefulWidget {
  const FilterPanel({super.key});

  @override
  ConsumerState<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends ConsumerState<FilterPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _includeExtController = TextEditingController();
  final TextEditingController _excludeExtController = TextEditingController();
  final TextEditingController _excludeFolderController = TextEditingController();
  DateTime? _modifiedAfter;
  DateTime? _modifiedBefore;
  int? _minSize;
  int? _maxSize;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    final filterOptions = ref.read(filterOptionsProvider);
    _searchController.text = filterOptions.searchText ?? '';
    _modifiedAfter = filterOptions.modifiedAfter;
    _modifiedBefore = filterOptions.modifiedBefore;
    _minSize = filterOptions.minSize;
    _maxSize = filterOptions.maxSize;
    
    // Apply search text changes immediately
    _searchController.addListener(() {
      ref.read(filterOptionsProvider.notifier).updateSearchText(
        _searchController.text.isNotEmpty ? _searchController.text : null,
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _includeExtController.dispose();
    _excludeExtController.dispose();
    _excludeFolderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filterOptions = ref.watch(filterOptionsProvider);

    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset All'),
                  onPressed: () {
                    ref.read(filterOptionsProvider.notifier).resetFilters();
                    setState(() {
                      _searchController.text = '';
                      _modifiedAfter = null;
                      _modifiedBefore = null;
                      _minSize = null;
                      _maxSize = null;
                    });
                  },
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Basic'),
              Tab(text: 'File Types'),
              Tab(text: 'Date'),
              Tab(text: 'Size'),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
            dividerColor: Colors.transparent,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBasicFilterTab(filterOptions),
                _buildTypeFilterTab(filterOptions),
                _buildDateFilterTab(filterOptions),
                _buildSizeFilterTab(filterOptions),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicFilterTab(FilterOptions filterOptions) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search text',
                hintText: 'Enter text to search for',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 24),
          SizedBox(
            width: 250,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fix - Use Row + Checkbox instead of SwitchListTile
                Row(
                  children: [
                    Checkbox(
                      value: filterOptions.showHiddenFiles,
                      onChanged: (value) {
                        ref.read(filterOptionsProvider.notifier).toggleShowHiddenFiles();
                      },
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Show hidden files', style: TextStyle(fontWeight: FontWeight.w500)),
                          Text('Files starting with dot (.)', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: filterOptions.caseSensitive,
                      onChanged: (value) {
                        ref.read(filterOptionsProvider.notifier).toggleCaseSensitive();
                      },
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Case sensitive', style: TextStyle(fontWeight: FontWeight.w500)),
                          Text('Match exact case when searching', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Rest of the FilterPanel code remains the same
  
  Widget _buildTypeFilterTab(FilterOptions filterOptions) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Included extensions
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Include File Extensions', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildExtensionsList(filterOptions.includedExtensions, true),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _includeExtController,
                        decoration: const InputDecoration(
                          labelText: 'Add extension',
                          hintText: 'e.g. dart',
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (_includeExtController.text.isNotEmpty) {
                          final extensions = List<String>.from(filterOptions.includedExtensions);
                          extensions.add(_includeExtController.text.toLowerCase());
                          ref.read(filterOptionsProvider.notifier).updateIncludedExtensions(extensions);
                          _includeExtController.clear();
                        }
                      },
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 24),
          
          // Excluded extensions
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Exclude File Extensions', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildExtensionsList(filterOptions.excludedExtensions, false),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _excludeExtController,
                        decoration: const InputDecoration(
                          labelText: 'Add extension',
                          hintText: 'e.g. tmp',
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (_excludeExtController.text.isNotEmpty) {
                          final extensions = List<String>.from(filterOptions.excludedExtensions);
                          extensions.add(_excludeExtController.text.toLowerCase());
                          ref.read(filterOptionsProvider.notifier).updateExcludedExtensions(extensions);
                          _excludeExtController.clear();
                        }
                      },
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 24),
          
          // Excluded folders
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Exclude Folders', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildExtensionsList(filterOptions.excludedFolders, false, isFolder: true),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _excludeFolderController,
                        decoration: const InputDecoration(
                          labelText: 'Add folder name',
                          hintText: 'e.g. node_modules',
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (_excludeFolderController.text.isNotEmpty) {
                          final folders = List<String>.from(filterOptions.excludedFolders);
                          folders.add(_excludeFolderController.text);
                          ref.read(filterOptionsProvider.notifier).updateExcludedFolders(folders);
                          _excludeFolderController.clear();
                        }
                      },
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtensionsList(List<String> items, bool isIncluded, {bool isFolder = false}) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(
          isFolder 
              ? 'No excluded folders' 
              : isIncluded ? 'No included extensions' : 'No excluded extensions',
          style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: items.map((item) {
        return Chip(
          label: Text(item),
          deleteIcon: const Icon(Icons.close, size: 16),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          labelStyle: const TextStyle(fontSize: 12),
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          onDeleted: () {
            final updatedList = List<String>.from(items)..remove(item);
            if (isFolder) {
              ref.read(filterOptionsProvider.notifier).updateExcludedFolders(updatedList);
            } else if (isIncluded) {
              ref.read(filterOptionsProvider.notifier).updateIncludedExtensions(updatedList);
            } else {
              ref.read(filterOptionsProvider.notifier).updateExcludedExtensions(updatedList);
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildDateFilterTab(FilterOptions filterOptions) {
    final afterDateText = _modifiedAfter != null
        ? '${_modifiedAfter!.year}-${_modifiedAfter!.month.toString().padLeft(2, '0')}-${_modifiedAfter!.day.toString().padLeft(2, '0')}'
        : 'Not set';
    
    final beforeDateText = _modifiedBefore != null
        ? '${_modifiedBefore!.year}-${_modifiedBefore!.month.toString().padLeft(2, '0')}-${_modifiedBefore!.day.toString().padLeft(2, '0')}'
        : 'Not set';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filter by Modification Date', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Modified after:'),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                afterDateText,
                                style: TextStyle(
                                  color: _modifiedAfter != null
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).disabledColor,
                                  fontWeight: _modifiedAfter != null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              const Spacer(),
                              if (_modifiedAfter != null)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _modifiedAfter = null;
                                    });
                                    ref.read(filterOptionsProvider.notifier).updateModifiedDateRange(
                                      null,
                                      _modifiedBefore,
                                    );
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.calendar_today, size: 18),
                                onPressed: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _modifiedAfter ?? DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime.now(),
                                  );
                                  if (date != null) {
                                    setState(() {
                                      _modifiedAfter = date;
                                    });
                                    ref.read(filterOptionsProvider.notifier).updateModifiedDateRange(
                                      date,
                                      _modifiedBefore,
                                    );
                                  }
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Modified before:'),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                beforeDateText,
                                style: TextStyle(
                                  color: _modifiedBefore != null
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).disabledColor,
                                  fontWeight: _modifiedBefore != null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              const Spacer(),
                              if (_modifiedBefore != null)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _modifiedBefore = null;
                                    });
                                    ref.read(filterOptionsProvider.notifier).updateModifiedDateRange(
                                      _modifiedAfter,
                                      null,
                                    );
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.calendar_today, size: 18),
                                onPressed: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _modifiedBefore ?? DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime.now(),
                                  );
                                  if (date != null) {
                                    setState(() {
                                      _modifiedBefore = date;
                                    });
                                    ref.read(filterOptionsProvider.notifier).updateModifiedDateRange(
                                      _modifiedAfter,
                                      date,
                                    );
                                  }
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeFilterTab(FilterOptions filterOptions) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filter by File Size', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Minimum size:'),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                _minSize != null ? _formatSize(_minSize!) : 'Not set',
                                style: TextStyle(
                                  color: _minSize != null
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).disabledColor,
                                  fontWeight: _minSize != null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              const Spacer(),
                              if (_minSize != null)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _minSize = null;
                                    });
                                    ref.read(filterOptionsProvider.notifier).updateSizeRange(
                                      null,
                                      _maxSize,
                                    );
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () {
                                  _showSizeInputDialog(
                                    context,
                                    'Set minimum file size',
                                    _minSize != null ? (_minSize! / 1024).round() : null,
                                    (value) {
                                      setState(() {
                                        _minSize = value * 1024;
                                      });
                                      ref.read(filterOptionsProvider.notifier).updateSizeRange(
                                        value * 1024,
                                        _maxSize,
                                      );
                                    },
                                  );
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Maximum size:'),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                _maxSize != null ? _formatSize(_maxSize!) : 'Not set',
                                style: TextStyle(
                                  color: _maxSize != null
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).disabledColor,
                                  fontWeight: _maxSize != null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              const Spacer(),
                              if (_maxSize != null)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _maxSize = null;
                                    });
                                    ref.read(filterOptionsProvider.notifier).updateSizeRange(
                                      _minSize,
                                      null,
                                    );
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () {
                                  _showSizeInputDialog(
                                    context,
                                    'Set maximum file size',
                                    _maxSize != null ? (_maxSize! / 1024).round() : null,
                                    (value) {
                                      setState(() {
                                        _maxSize = value * 1024;
                                      });
                                      ref.read(filterOptionsProvider.notifier).updateSizeRange(
                                        _minSize,
                                        value * 1024,
                                      );
                                    },
                                  );
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSizeInputDialog(
    BuildContext context,
    String title,
    int? initialValue,
    Function(int) onSaved,
  ) async {
    final controller = TextEditingController(
      text: initialValue != null ? initialValue.toString() : '',
    );

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'File size (KB)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                if (value != null && value > 0) {
                  onSaved(value);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
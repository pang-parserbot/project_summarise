import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

import '../providers/settings_provider.dart';
import '../providers/filter_provider.dart';
import '../providers/recent_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _selectedCategoryIndex = 0;
  String _cacheSize = "Calculating...";
  bool _isProcessing = false;
  String _selectedDensity = 'Standard';
  String _selectedViewMode = 'list';
  double _textSizeValue = 1.0;
  
  static const List<String> _categories = [
    'Appearance',
    'File Browser',
    'Editor',
    'Keyboard Shortcuts',
    'Data & Storage',
    'About',
  ];
  
  @override
  void initState() {
    super.initState();
    _calculateCacheSize();
  }
  
  Future<void> _calculateCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheFiles = await _dirSize(tempDir);
      
      if (mounted) {
        setState(() {
          _cacheSize = _formatBytes(cacheFiles);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cacheSize = "Unable to calculate";
        });
      }
    }
  }
  
  Future<int> _dirSize(Directory dir) async {
    int total = 0;
    try {
      final List<FileSystemEntity> entities = await dir.list().toList();
      for (final FileSystemEntity entity in entities) {
        if (entity is File) {
          total += await entity.length();
        } else if (entity is Directory) {
          total += await _dirSize(entity);
        }
      }
    } catch (e) {
      // Skip directories we don't have permission to access
    }
    return total;
  }
  
  String _formatBytes(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1048576) return "${(bytes / 1024).toStringAsFixed(2)} KB";
    if (bytes < 1073741824) return "${(bytes / 1048576).toStringAsFixed(2)} MB";
    return "${(bytes / 1073741824).toStringAsFixed(2)} GB";
  }
  
  Future<void> _clearCache() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      final tempDir = await getTemporaryDirectory();
      await _deleteDirectoryContents(tempDir);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache cleared successfully')),
        );
      }
      
      // Recalculate cache size
      await _calculateCacheSize();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing cache: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
  
  Future<void> _deleteDirectoryContents(Directory directory) async {
    try {
      final List<FileSystemEntity> entities = await directory.list().toList();
      for (final FileSystemEntity entity in entities) {
        if (entity is File) {
          await entity.delete();
        } else if (entity is Directory) {
          await _deleteDirectoryContents(entity);
          // We don't delete the directory itself, just its contents
        }
      }
    } catch (e) {
      // Skip files or directories we don't have permission to delete
    }
  }
  
  Future<void> _clearRecentHistory() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Recent History'),
        content: const Text('Are you sure you want to clear all recent history? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(recentPathsProvider.notifier).clearRecentPaths();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recent history cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _resetFilters() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Filters'),
        content: const Text('Are you sure you want to reset all filters to default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(filterOptionsProvider.notifier).resetFilters();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filters reset to default')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _resetAllSettings() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Settings'),
        content: const Text('Are you sure you want to reset all settings to their default values? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ref.read(settingsProvider.notifier).resetAllSettings();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All settings have been reset to defaults')),
              );
            },
            child: const Text('Reset All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.restore),
            label: const Text('Reset All'),
            onPressed: _resetAllSettings,
          ),
        ],
      ),
      body: Row(
        children: [
          // Settings categories sidebar
          Container(
            width: 200,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                return _buildCategoryTile(
                  icon: _getCategoryIcon(index),
                  title: _categories[index],
                  isSelected: _selectedCategoryIndex == index,
                  onTap: () {
                    setState(() {
                      _selectedCategoryIndex = index;
                    });
                  },
                );
              },
            ),
          ),
          
          // Settings content area
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                // Display the selected category settings
                if (_selectedCategoryIndex == 0) _buildAppearanceSettings(settings),
                if (_selectedCategoryIndex == 1) _buildFileBrowserSettings(settings),
                if (_selectedCategoryIndex == 2) _buildEditorSettings(settings),
                if (_selectedCategoryIndex == 3) _buildKeyboardShortcutsSettings(settings),
                if (_selectedCategoryIndex == 4) _buildDataAndStorageSettings(),
                if (_selectedCategoryIndex == 5) _buildAboutSettings(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getCategoryIcon(int index) {
    switch(index) {
      case 0: return Icons.palette_outlined;
      case 1: return Icons.folder_outlined;
      case 2: return Icons.text_fields;
      case 3: return Icons.keyboard;
      case 4: return Icons.storage_outlined;
      case 5: return Icons.info_outline;
      default: return Icons.settings;
    }
  }
  
  Widget _buildCategoryTile({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
      selected: isSelected,
      onTap: onTap,
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
  
  // 外观设置
  Widget _buildAppearanceSettings(AppSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('THEME'),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Use dark theme throughout the app'),
                value: settings.useDarkMode,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setDarkMode(value);
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('Theme Color'),
                subtitle: const Text('Choose the main color for the app'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildColorButton(Colors.blue, isSelected: true),
                    _buildColorButton(Colors.purple),
                    _buildColorButton(Colors.green),
                    _buildColorButton(Colors.orange),
                    _buildColorButton(Colors.red),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        _buildSectionHeader('UI CUSTOMIZATION'),
        Card(
          child: Column(
            children: [
              // Replace problematic ListTile with custom widget
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Text Size',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Adjust the size of text in the app interface',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _textSizeValue,
                      min: 0.8,
                      max: 1.2,
                      divisions: 4,
                      label: '${(_textSizeValue * 100).toInt()}%',
                      onChanged: (value) {
                        setState(() {
                          _textSizeValue = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Density selection
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Density',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Adjust the spacing between UI elements',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildDensityButton('Compact'),
                        _buildDensityButton('Standard'),
                        _buildDensityButton('Comfortable'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildDensityButton(String density) {
    final isSelected = _selectedDensity == density;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedDensity = density;
        });
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary 
                : Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
        ),
        child: Text(
          density,
          style: TextStyle(
            color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
  
  Widget _buildColorButton(Color color, {bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Change theme color (not implemented)
        },
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: color.withOpacity(0.6),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: isSelected 
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : null,
        ),
      ),
    );
  }
  
  // 文件浏览器设置
  Widget _buildFileBrowserSettings(AppSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('BROWSING BEHAVIOR'),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Show Hidden Files'),
                subtitle: const Text('Display files and folders that start with a dot (.)'),
                value: settings.showHiddenFiles,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setShowHiddenFiles(value);
                  // 同时更新过滤器设置
                  ref.read(filterOptionsProvider.notifier).toggleShowHiddenFiles();
                },
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Navigate with Single Click'),
                subtitle: const Text('Open folders with a single click instead of double-click'),
                value: settings.navigateWithSingleClick,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setNavigateWithSingleClick(value);
                },
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Confirm Before Delete'),
                subtitle: const Text('Show confirmation dialog before deleting files or folders'),
                value: settings.confirmBeforeDelete,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setConfirmBeforeDelete(value);
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('Default Sort Order'),
                subtitle: const Text('Choose how files and folders are sorted by default'),
                trailing: DropdownButton<String>(
                  value: settings.defaultSort,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(settingsProvider.notifier).setDefaultSort(value);
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: 'Type', child: Text('Type (folders first)')),
                    DropdownMenuItem(value: 'Name', child: Text('Name')),
                    DropdownMenuItem(value: 'Size', child: Text('Size')),
                    DropdownMenuItem(value: 'Date', child: Text('Modified date')),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        _buildSectionHeader('DEFAULT VIEW'),
        Card(
          child: Column(
            children: [
              // Replace problematic ListTile with custom widget
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'View Mode',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Choose the default view for file browser',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildViewModeButton('list', Icons.list),
                        const SizedBox(width: 12),
                        _buildViewModeButton('grid', Icons.grid_view),
                        const SizedBox(width: 12),
                        _buildViewModeButton('details', Icons.view_list),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Show File Extensions'),
                subtitle: const Text('Display file extensions in the browser'),
                value: true,
                onChanged: (value) {
                  // Placeholder, not implemented
                },
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Show File Icons'),
                subtitle: const Text('Display icons based on file type'),
                value: true,
                onChanged: (value) {
                  // Placeholder, not implemented
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildViewModeButton(String mode, IconData icon) {
    final isSelected = _selectedViewMode == mode;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedViewMode = mode;
        });
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary 
                : Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
        ),
        child: Icon(
          icon,
          color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
          size: 24,
        ),
      ),
    );
  }
  
  // 编辑器设置
  Widget _buildEditorSettings(AppSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('TEXT & DISPLAY'),
        Card(
          child: Column(
            children: [
              ListTile(
                title: const Text('Font Size'),
                subtitle: Text('${settings.editorFontSize.toInt()} px'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: settings.editorFontSize > 10 
                          ? () => ref.read(settingsProvider.notifier).setEditorFontSize(settings.editorFontSize - 1)
                          : null,
                    ),
                    Text(
                      settings.editorFontSize.toInt().toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: settings.editorFontSize < 24 
                          ? () => ref.read(settingsProvider.notifier).setEditorFontSize(settings.editorFontSize + 1)
                          : null,
                    ),
                  ],
                ),
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Word Wrap'),
                subtitle: const Text('Wrap long lines of text to fit the window'),
                value: false,
                onChanged: (value) {
                  // Placeholder, not implemented
                },
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Show Line Numbers'),
                subtitle: const Text('Display line numbers in the code editor'),
                value: true,
                onChanged: (value) {
                  // Placeholder, not implemented
                },
              ),
            ],
          ),
        ),
        
        _buildSectionHeader('CODE SYNTAX'),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Syntax Highlighting'),
                subtitle: const Text('Color code syntax for supported languages'),
                value: true,
                onChanged: (value) {
                  // Placeholder, not implemented
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('Color Theme'),
                subtitle: const Text('Choose syntax highlighting theme'),
                trailing: DropdownButton<String>(
                  value: 'default',
                  onChanged: (value) {
                    // Placeholder, not implemented
                  },
                  items: const [
                    DropdownMenuItem(value: 'default', child: Text('Default')),
                    DropdownMenuItem(value: 'monokai', child: Text('Monokai')),
                    DropdownMenuItem(value: 'solarized', child: Text('Solarized')),
                    DropdownMenuItem(value: 'dracula', child: Text('Dracula')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // 键盘快捷键设置
  Widget _buildKeyboardShortcutsSettings(AppSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('KEYBOARD SHORTCUTS'),
        Card(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Customize keyboard shortcuts for common actions. Click on a shortcut to change it.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
              const Divider(),
              ...settings.keyboardShortcuts.entries.map((entry) => _buildShortcutItem(entry.key, entry.value)),
            ],
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.restore),
              label: const Text('Reset to Defaults'),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Reset Keyboard Shortcuts'),
                    content: const Text('Are you sure you want to reset all keyboard shortcuts to their default values?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ) ?? false;
                
                if (confirmed) {
                  // Reset all shortcuts
                  for (final shortcutId in settings.keyboardShortcuts.keys) {
                    ref.read(settingsProvider.notifier).resetKeyboardShortcut(shortcutId);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All shortcuts have been reset to defaults')),
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildShortcutItem(String id, KeyboardShortcut shortcut) {
    return ListTile(
      title: Text(shortcut.name),
      subtitle: Text(shortcut.description),
      trailing: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onPressed: () => _showShortcutEditor(id, shortcut),
        child: Text(shortcut.displayString),
      ),
      onTap: () => _showShortcutEditor(id, shortcut),
    );
  }
  
  Future<void> _showShortcutEditor(String id, KeyboardShortcut shortcut) async {
    String keyPressed = 'Press a key combination...';
    LogicalKeyboardKey? capturedKey;
    Set<LogicalKeyboardKey> capturedModifiers = {};
    bool hasUserInput = false;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Edit Shortcut: ${shortcut.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shortcut.description),
                const SizedBox(height: 16),
                const Text(
                  'Current shortcut:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(shortcut.displayString),
                const SizedBox(height: 24),
                const Text(
                  'New shortcut:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: RawKeyboardListener(
                    focusNode: FocusNode()..requestFocus(),
                    onKey: (event) {
                      // Capture key combo
                      if (event is RawKeyDownEvent) {
                        // Skip modifier-only key events
                        if (event.logicalKey == LogicalKeyboardKey.control ||
                            event.logicalKey == LogicalKeyboardKey.alt ||
                            event.logicalKey == LogicalKeyboardKey.shift ||
                            event.logicalKey == LogicalKeyboardKey.meta) {
                          return;
                        }
                        
                        hasUserInput = true;
                        capturedKey = event.logicalKey;
                        capturedModifiers = <LogicalKeyboardKey>{};
                        
                        // Add modifiers
                        if (event.isControlPressed) {
                          capturedModifiers.add(LogicalKeyboardKey.control);
                        }
                        if (event.isAltPressed) {
                          capturedModifiers.add(LogicalKeyboardKey.alt);
                        }
                        if (event.isShiftPressed) {
                          capturedModifiers.add(LogicalKeyboardKey.shift);
                        }
                        if (event.isMetaPressed) {
                          capturedModifiers.add(LogicalKeyboardKey.meta);
                        }
                        
                        // Create display string
                        keyPressed = '';
                        if (capturedModifiers.contains(LogicalKeyboardKey.control)) {
                          keyPressed += 'Ctrl+';
                        }
                        if (capturedModifiers.contains(LogicalKeyboardKey.alt)) {
                          keyPressed += 'Alt+';
                        }
                        if (capturedModifiers.contains(LogicalKeyboardKey.shift)) {
                          keyPressed += 'Shift+';
                        }
                        if (capturedModifiers.contains(LogicalKeyboardKey.meta)) {
                          keyPressed += 'Meta+';
                        }
                        
                        // Add main key
                        final keyLabel = capturedKey!.keyLabel;
                        keyPressed += keyLabel.isNotEmpty ? keyLabel : 'Key ${capturedKey!.keyId}';
                        
                        setState(() {});
                      }
                    },
                    child: Text(
                      keyPressed,
                      style: TextStyle(
                        fontWeight: hasUserInput ? FontWeight.bold : FontWeight.normal,
                        fontFamily: 'monospace',
                        color: hasUserInput 
                            ? Theme.of(context).colorScheme.primary 
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Press the key combination you want to use',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: hasUserInput && capturedKey != null 
                    ? () {
                        ref.read(settingsProvider.notifier).resetKeyboardShortcut(id);
                        Navigator.of(context).pop();
                      }
                    : null,
                child: const Text('Reset to Default'),
              ),
              ElevatedButton(
                onPressed: hasUserInput && capturedKey != null 
                    ? () {
                        ref.read(settingsProvider.notifier).updateKeyboardShortcut(
                          id, 
                          capturedKey!, 
                          capturedModifiers,
                        );
                        Navigator.of(context).pop();
                      }
                    : null,
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  // 数据和存储设置
  Widget _buildDataAndStorageSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('HISTORY & CACHE'),
        Card(
          child: Column(
            children: [
              ListTile(
                title: const Text('Clear Recent History'),
                subtitle: const Text('Remove all recently visited folders'),
                trailing: ElevatedButton(
                  onPressed: _clearRecentHistory,
                  child: const Text('Clear'),
                ),
              ),
              const Divider(),
              ListTile(
                title: const Text('Reset All Filters'),
                subtitle: const Text('Restore default filter settings'),
                trailing: ElevatedButton(
                  onPressed: _resetFilters,
                  child: const Text('Reset'),
                ),
              ),
              const Divider(),
              ListTile(
                title: const Text('Clear Cache'),
                subtitle: Text('Current cache size: $_cacheSize'),
                trailing: ElevatedButton(
                  onPressed: _isProcessing ? null : _clearCache,
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Clear'),
                ),
              ),
            ],
          ),
        ),
        
        _buildSectionHeader('BACKUP & SYNC'),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.cloud_off),
                title: const Text('Cloud Sync'),
                subtitle: const Text('Sync settings across devices using cloud storage'),
                trailing: Switch(
                  value: false, 
                  onChanged: (value) {
                    // Placeholder, not implemented
                  }
                ),
              ),
              const Divider(),
              const ListTile(
                leading: Icon(Icons.download),
                title: Text('Export Settings'),
                subtitle: Text('Save all settings to a file'),
                trailing: Icon(Icons.chevron_right),
              ),
              const Divider(),
              const ListTile(
                leading: Icon(Icons.upload),
                title: Text('Import Settings'),
                subtitle: Text('Load settings from a file'),
                trailing: Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // 关于设置
  Widget _buildAboutSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('APPLICATION INFO'),
        Card(
          child: Column(
            children: [
              const ListTile(
                title: Text('Version'),
                trailing: Text('1.0.0'),
              ),
              const Divider(),
              ListTile(
                title: const Text('Source Code'),
                subtitle: const Text('View the source code on GitHub'),
                trailing: ElevatedButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Open'),
                  onPressed: () async {
                    const url = 'https://github.com/pang-parserbot/project_summarise';
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    } else {
                      // Handle error - show a snackbar or dialog
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not open the GitHub page')),
                        );
                      }
                    }
                  },
                ),
              ),
              const Divider(),
              const ListTile(
                title: Text('License'),
                trailing: Text('MIT'),
              ),
            ],
          ),
        ),
        
        _buildSectionHeader('DEVELOPERS'),
        Card(
          child: Column(
            children: const [
              ListTile(
                title: Text('Created by Pang'),
                subtitle: Text('pang@parserbot.com'),
              ),
              Divider(),
              ListTile(
                title: Text('Contributors'),
                subtitle: Text('Thanks to all who contributed to this project'),
              ),
            ],
          ),
        ),
        
        _buildSectionHeader('SUPPORT & FEEDBACK'),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.report_problem),
                title: const Text('Report an Issue'),
                subtitle: const Text('Submit a bug report or feature request'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  const url = 'https://github.com/pang-parserbot/project_summarise/issues';
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                  }
                },
              ),
              const Divider(),
              const ListTile(
                leading: Icon(Icons.star),
                title: Text('Rate the App'),
                subtitle: Text('Leave a review or rating'),
                trailing: Icon(Icons.chevron_right),
              ),
              const Divider(),
              const ListTile(
                leading: Icon(Icons.mail),
                title: Text('Contact Us'),
                subtitle: Text('Get in touch with the team'),
                trailing: Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
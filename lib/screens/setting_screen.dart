import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/recent_provider.dart';
import '../../providers/filter_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _useDarkMode = false;
  bool _showHiddenFiles = false;
  bool _confirmBeforeDelete = true;
  String _cacheSize = "Calculating...";
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
    _calculateCacheSize();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _useDarkMode = prefs.getBool('use_dark_mode') ?? false;
      _showHiddenFiles = prefs.getBool('show_hidden_files') ?? false;
      _confirmBeforeDelete = prefs.getBool('confirm_before_delete') ?? true;
    });
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool('use_dark_mode', _useDarkMode);
    await prefs.setBool('show_hidden_files', _showHiddenFiles);
    await prefs.setBool('confirm_before_delete', _confirmBeforeDelete);
  }
  
  Future<void> _calculateCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheFiles = await _dirSize(tempDir);
      
      setState(() {
        _cacheSize = _formatBytes(cacheFiles);
      });
    } catch (e) {
      setState(() {
        _cacheSize = "Unable to calculate";
      });
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
    try {
      final tempDir = await getTemporaryDirectory();
      await _deleteDirectoryContents(tempDir);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache cleared successfully')),
      );
      
      // Recalculate cache size
      await _calculateCacheSize();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing cache: ${e.toString()}')),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            // Save settings before navigating back
            await _saveSettings();
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
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
            child: ListView(
              children: [
                _buildCategoryTile(
                  icon: Icons.palette_outlined,
                  title: 'Appearance',
                  isSelected: true,
                ),
                _buildCategoryTile(
                  icon: Icons.folder_outlined,
                  title: 'File Browser',
                ),
                _buildCategoryTile(
                  icon: Icons.storage_outlined,
                  title: 'Data & Storage',
                ),
                _buildCategoryTile(
                  icon: Icons.info_outline,
                  title: 'About',
                ),
              ],
            ),
          ),
          
          // Settings content area
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                // Appearance section
                _buildSectionHeader('Appearance'),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Use Dark Mode'),
                        subtitle: const Text('Enable dark theme throughout the app'),
                        value: _useDarkMode,
                        onChanged: (value) {
                          setState(() {
                            _useDarkMode = value;
                          });
                        },
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('Editor Font Size'),
                        subtitle: const Text('Choose the font size for code viewing'),
                        trailing: DropdownButton<String>(
                          value: '14',
                          onChanged: (value) {
                            // Font size setting
                          },
                          items: const [
                            DropdownMenuItem(value: '12', child: Text('Small (12px)')),
                            DropdownMenuItem(value: '14', child: Text('Medium (14px)')),
                            DropdownMenuItem(value: '16', child: Text('Large (16px)')),
                            DropdownMenuItem(value: '18', child: Text('Extra Large (18px)')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // File Browser settings
                _buildSectionHeader('File Browser'),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Show Hidden Files'),
                        subtitle: const Text('Display files and folders that start with a dot (.)'),
                        value: _showHiddenFiles,
                        onChanged: (value) {
                          setState(() {
                            _showHiddenFiles = value;
                            ref.read(filterOptionsProvider.notifier).toggleShowHiddenFiles();
                          });
                        },
                      ),
                      const Divider(),
                      SwitchListTile(
                        title: const Text('Confirm Before Deleting'),
                        subtitle: const Text('Ask for confirmation before deleting files or folders'),
                        value: _confirmBeforeDelete,
                        onChanged: (value) {
                          setState(() {
                            _confirmBeforeDelete = value;
                          });
                        },
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('Default Sort Order'),
                        subtitle: const Text('Choose how files and folders are sorted by default'),
                        trailing: DropdownButton<String>(
                          value: 'Type',
                          onChanged: (value) {
                            // Sort setting
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
                
                // Data & Storage
                _buildSectionHeader('Data & Storage'),
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
                          onPressed: _clearCache,
                          child: const Text('Clear'),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // About section
                _buildSectionHeader('About'),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryTile({
    required IconData icon,
    required String title,
    bool isSelected = false,
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
      onTap: () {
        // Category navigation would go here
      },
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
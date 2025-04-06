import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:project_summarise/models/recent_path.dart';
import 'package:project_summarise/providers/code_summary_provider.dart';
import 'package:project_summarise/providers/settings_provider.dart';
import 'package:project_summarise/screens/setting_screen.dart';
import 'package:project_summarise/widgets/code_summary_exporter.dart';
import '../widgets/file_browser.dart';
import '../widgets/filter_panel.dart';
import '../../providers/file_system_provider.dart';
import '../../providers/recent_provider.dart';
import '../../providers/favorites_provider.dart';

// 导航意图定义
class NavigateBackIntent extends Intent {
  const NavigateBackIntent();
}

class NavigateUpIntent extends Intent {
  const NavigateUpIntent();
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showFilterPanel = false;
  int _selectedIndex = 0;
  
  // 处理导航回退
  void _handleNavigateBack() {
    if (ref.read(currentPathProvider) != null) {
      ref.read(fileSystemProvider.notifier).navigateBack();
    }
  }
  
  // 处理向上导航
  void _handleNavigateUp() {
    if (ref.read(currentPathProvider) != null) {
      ref.read(fileSystemProvider.notifier).navigateUp();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final currentPath = ref.watch(currentPathProvider);
    final recentPaths = ref.watch(recentPathsProvider);
    final favorites = ref.watch(favoritesProvider);
    final canNavigateBack = currentPath != null && 
                           ref.watch(fileSystemProvider.notifier).canGoBack;
    
  final settings = ref.watch(settingsProvider);
  
  // 使用来自设置的键盘快捷键
  final backShortcut = settings.keyboardShortcuts['navigateBack'];
  final upShortcut = settings.keyboardShortcuts['navigateUp'];
    return Shortcuts(
      
    shortcuts: <LogicalKeySet, Intent>{
      // 基于设置的回退快捷键
      LogicalKeySet.fromSet({
        ...backShortcut?.currentModifiers ?? {},
        backShortcut?.currentKey ?? LogicalKeyboardKey.keyZ,
      }): const NavigateBackIntent(),
      
      // 基于设置的向上导航快捷键
      LogicalKeySet.fromSet({
        ...upShortcut?.currentModifiers ?? {},
        upShortcut?.currentKey ?? LogicalKeyboardKey.arrowUp,
      }): const NavigateUpIntent(),
      
      // 额外的备选快捷键
      LogicalKeySet(LogicalKeyboardKey.backspace): const NavigateUpIntent(),
    },
      
      child: Actions(
        actions: <Type, Action<Intent>>{
          NavigateBackIntent: CallbackAction<NavigateBackIntent>(
            onInvoke: (NavigateBackIntent intent) {
              _handleNavigateBack();
              return null;
            },
          ),
          NavigateUpIntent: CallbackAction<NavigateUpIntent>(
            onInvoke: (NavigateUpIntent intent) {
              _handleNavigateUp();
              return null;
            },
          ),
        },
        child: Scaffold(
          
          body: Row(
            children: [
              // Custom sidebar instead of NavigationRail
              _buildSidebar(canNavigateBack),
              
              // Main content area with optional filter panel
              Expanded(
                child: Column(
                  children: [
                    // App bar with path and actions
                    _buildAppBar(currentPath),
                    
                    // Filter panel (collapsible)
                    if (_showFilterPanel)
                      const FilterPanel(),
                      
                    // Main content (file browser or landing)
                    Expanded(
                      child: _selectedIndex == 0
                        ? (currentPath != null 
                            ? const FileBrowser() 
                            : _buildWelcomeScreen(recentPaths, favorites))
                        : _selectedIndex == 1
                          ? _buildRecentScreen(recentPaths)
                          : _selectedIndex == 2
                            ? _buildFavoritesScreen(favorites)
                            : const SizedBox(), // Should never reach here as settings opens a new screen
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          bottomNavigationBar: currentPath != null ? Container(
            height: 28, // 增加高度使其更明显
            color: Theme.of(context).colorScheme.surfaceVariant,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Current path: $currentPath',
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
              ],
            ),
          ) : null,
        ),
      ),
    );
  }

  Widget _buildSidebar(bool canNavigateBack) {
    final isWide = MediaQuery.of(context).size.width > 1200;
    
    return Container(
      width: isWide ? 200 : 72,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Column(
        children: [
          // Navigation items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 8),
                _buildNavItem(
                  icon: Icons.folder, 
                  label: 'Explorer',
                  isSelected: _selectedIndex == 0,
                  onTap: () => setState(() => _selectedIndex = 0),
                  isWide: isWide,
                ),
                _buildNavItem(
                  icon: Icons.history, 
                  label: 'Recent',
                  isSelected: _selectedIndex == 1,
                  onTap: () => setState(() => _selectedIndex = 1),
                  isWide: isWide,
                ),
                _buildNavItem(
                  icon: Icons.star, 
                  label: 'Favorites',
                  isSelected: _selectedIndex == 2,
                  onTap: () => setState(() => _selectedIndex = 2),
                  isWide: isWide,
                ),
                _buildNavItem(
                  icon: Icons.settings, 
                  label: 'Settings',
                  isSelected: _selectedIndex == 3,
                  onTap: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                  isWide: isWide,
                ),
              ],
            ),
          ),
          
          // 显示快捷键信息
          if (canNavigateBack)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isWide) ...[
                    const Text('Back: ', style: TextStyle(fontSize: 12)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Ctrl+Z', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ] else
                    Tooltip(
                      message: 'Navigate back (Ctrl+Z)',
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.keyboard_return, size: 16),
                      ),
                    ),
                ],
              ),
            ),
          
          // 改进后的Open folder按钮设计
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            margin: const EdgeInsets.all(8),
            child: ElevatedButton(
              onPressed: _openDirectory,
              style: ElevatedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_open, size: 20),
                  if (isWide) const SizedBox(width: 8),
                  if (isWide) const Text(
                    'Open Folder',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isWide,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
          borderRadius: BorderRadius.circular(4),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : null,
            ),
            if (isWide) const SizedBox(width: 16),
            if (isWide)
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Theme.of(context).colorScheme.primary : null,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAppBar(String? currentPath) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Row(
        children: [
          // 移除回退按钮，因为FileBrowser中已有
        
          // Current path display with breadcrumbs
          if (currentPath != null)
            Expanded(
              child: Text(
                'Location: ${_getDisplayPath(currentPath)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            const Expanded(
              child: Text(
                'Code Browser',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          
          // Action buttons
          IconButton(
            icon: Icon(
              _showFilterPanel ? Icons.filter_list_off : Icons.filter_list,
            ),
            tooltip: _showFilterPanel ? 'Hide Filters' : 'Show Filters',
            onPressed: () {
              setState(() {
                _showFilterPanel = !_showFilterPanel;
              });
            },
          ),
          const SizedBox(width: 8),
          if (currentPath != null) ...[
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () {
                ref.read(fileSystemProvider.notifier).refresh();
              },
            ),
            const SizedBox(width: 8),
            // Code summary button
            ElevatedButton.icon(
              icon: const Icon(Icons.summarize),
              label: const Text('Code Summary'),
              onPressed: () {
                // Reset the summary state before showing the dialog
                ref.read(summaryGeneratorProvider.notifier).reset();
                
                showDialog(
                  context: context,
                  builder: (context) => CodeSummaryExporter(
                    directoryPath: currentPath!,
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                  break;
                case 'clearRecent':
                  ref.read(recentPathsProvider.notifier).clearRecentPaths();
                  break;
                case 'keyboardShortcuts':
                  _showKeyboardShortcutsDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'clearRecent',
                child: ListTile(
                  leading: Icon(Icons.delete_sweep),
                  title: Text('Clear Recent'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'keyboardShortcuts',
                child: ListTile(
                  leading: Icon(Icons.keyboard),
                  title: Text('Keyboard Shortcuts'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // 添加一个显示键盘快捷键对话框的方法
  void _showKeyboardShortcutsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keyboard Shortcuts'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _ShortcutItem(shortcut: 'Ctrl+Z', description: 'Navigate back to previous folder'),
            _ShortcutItem(shortcut: 'Alt+Left', description: 'Navigate back to previous folder'),
            _ShortcutItem(shortcut: 'Alt+Up', description: 'Navigate to parent folder'),
            _ShortcutItem(shortcut: 'Backspace', description: 'Navigate to parent folder'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWelcomeScreen(List<RecentPath> recentPaths, List<RecentPath> favorites) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome message and quick actions
          Expanded(
            flex: 3,
            child: Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome to Code Browser',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'A powerful tool for browsing and managing your code projects.',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Getting Started:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    _buildActionButton(
                      icon: Icons.folder_open,
                      label: 'Open a folder to start browsing',
                      onPressed: _openDirectory,
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      icon: Icons.filter_list,
                      label: 'Use filters to manage large projects',
                      onPressed: () {
                        setState(() {
                          _showFilterPanel = true;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      icon: Icons.star,
                      label: 'Add favorites for quick access',
                      onPressed: null,
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      icon: Icons.keyboard,
                      label: 'View keyboard shortcuts',
                      onPressed: _showKeyboardShortcutsDialog,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 24),
          
          // Recent and favorites
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recent folders
                Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.history),
                            SizedBox(width: 8),
                            Text(
                              'Recent Folders',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (recentPaths.isEmpty)
                          const Text('No recent folders')
                        else
                          ...recentPaths.take(5).map((path) => _buildPathItem(
                            path.path,
                            onTap: () {
                              ref.read(fileSystemProvider.notifier).navigateToPath(path.path);
                              ref.read(recentPathsProvider.notifier).addRecentPath(path.path);
                            },
                          )),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Favorites
                Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber),
                            SizedBox(width: 8),
                            Text(
                              'Favorites',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (favorites.isEmpty)
                          const Text('No favorite folders')
                        else
                          ...favorites.take(5).map((path) => _buildPathItem(
                            path.path,
                            isFavorite: true,
                            onTap: () {
                              ref.read(fileSystemProvider.notifier).navigateToPath(path.path);
                              ref.read(recentPathsProvider.notifier).addRecentPath(path.path);
                            },
                          )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecentScreen(List<RecentPath> recentPaths) {
    if (recentPaths.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 24),
            Text(
              'No Recent Folders',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Folders you open will appear here',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    // Sort by most recent first
    final sortedPaths = List<RecentPath>.from(recentPaths)
      ..sort((a, b) => b.accessTime.compareTo(a.accessTime));
      
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedPaths.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Recent Folders',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          );
        }
        
        final path = sortedPaths[index - 1];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.folder),
            title: Text(_getDisplayPath(path.path)),
            subtitle: Text('Last accessed: ${_formatDate(path.accessTime)}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    path.isFavorite ? Icons.star : Icons.star_border,
                    color: path.isFavorite ? Colors.amber : null,
                  ),
                  onPressed: () {
                    if (path.isFavorite) {
                      ref.read(favoritesProvider.notifier).removeFavorite(path.path);
                    } else {
                      ref.read(favoritesProvider.notifier).addFavorite(path.path);
                    }
                  },
                  tooltip: path.isFavorite ? 'Remove from favorites' : 'Add to favorites',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    ref.read(recentPathsProvider.notifier).removeRecentPath(path.path);
                  },
                  tooltip: 'Remove from history',
                ),
              ],
            ),
            onTap: () {
              ref.read(fileSystemProvider.notifier).navigateToPath(path.path);
              ref.read(recentPathsProvider.notifier).addRecentPath(path.path);
              setState(() => _selectedIndex = 0); // Switch to explorer
            },
          ),
        );
      },
    );
  }
  
  Widget _buildFavoritesScreen(List<RecentPath> favorites) {
    if (favorites.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star, size: 64, color: Colors.grey),
            SizedBox(height: 24),
            Text(
              'No Favorite Folders',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Add folders to favorites for quick access',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    // Sort alphabetically
    final sortedFavorites = List<RecentPath>.from(favorites)
      ..sort((a, b) => a.path.compareTo(b.path));
      
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedFavorites.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Favorite Folders',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          );
        }
        
        final path = sortedFavorites[index - 1];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.folder, color: Colors.amber),
            title: Text(_getDisplayPath(path.path)),
            subtitle: Text('Added: ${_formatDate(path.accessTime)}'),
            trailing: IconButton(
              icon: const Icon(Icons.star, color: Colors.amber),
              onPressed: () {
                ref.read(favoritesProvider.notifier).removeFavorite(path.path);
              },
              tooltip: 'Remove from favorites',
            ),
            onTap: () {
              ref.read(fileSystemProvider.notifier).navigateToPath(path.path);
              ref.read(recentPathsProvider.notifier).addRecentPath(path.path);
              setState(() => _selectedIndex = 0); // Switch to explorer
            },
          ),
        );
      },
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            Icon(
              Icons.arrow_forward,
              color: onPressed == null
                  ? Theme.of(context).disabledColor
                  : Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPathItem(
    String path, {
    bool isFavorite = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        Icons.folder,
        color: isFavorite ? Colors.amber : null,
      ),
      title: Text(
        _getDisplayPath(path),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      dense: true,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
  
  String _getDisplayPath(String path) {
    if (path.length > 60) {
      return '...${path.substring(path.length - 60)}';
    }
    return path;
  }
  
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  Future<void> _openDirectory() async {
    final selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      ref.read(fileSystemProvider.notifier).navigateToPath(selectedDirectory);
      ref.read(recentPathsProvider.notifier).addRecentPath(selectedDirectory);
      setState(() => _selectedIndex = 0); // Switch to explorer
    }
  }
}

// 添加一个快捷键显示的组件
class _ShortcutItem extends StatelessWidget {
  final String shortcut;
  final String description;
  
  const _ShortcutItem({
    required this.shortcut,
    required this.description,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
            ),
            child: Text(
              shortcut,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(description),
          ),
        ],
      ),
    );
  }
}
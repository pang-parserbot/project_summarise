// lib/providers/settings_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AppSettings {
  // 应用设置
  final bool useDarkMode;
  final bool showHiddenFiles;
  final bool confirmBeforeDelete;
  final bool navigateWithSingleClick;
  final String defaultSort;
  final double editorFontSize;

  // 键盘快捷键
  final Map<String, KeyboardShortcut> keyboardShortcuts;

  AppSettings({
    this.useDarkMode = false,
    this.showHiddenFiles = false,
    this.confirmBeforeDelete = true,
    this.navigateWithSingleClick = true,
    this.defaultSort = 'Type',
    this.editorFontSize = 14.0,
    Map<String, KeyboardShortcut>? keyboardShortcuts,
  }) : keyboardShortcuts = keyboardShortcuts ?? defaultKeyboardShortcuts();

  static Map<String, KeyboardShortcut> defaultKeyboardShortcuts() {
    return {
      'navigateBack': KeyboardShortcut(
        name: 'Navigate Back',
        description: 'Navigate to previously visited folder',
        defaultKey: LogicalKeyboardKey.keyZ,
        modifiers: {LogicalKeyboardKey.control},
        currentKey: LogicalKeyboardKey.keyZ,
        currentModifiers: {LogicalKeyboardKey.control},
      ),
      'navigateUp': KeyboardShortcut(
        name: 'Navigate Up',
        description: 'Navigate to parent folder',
        defaultKey: LogicalKeyboardKey.arrowUp,
        modifiers: {LogicalKeyboardKey.alt},
        currentKey: LogicalKeyboardKey.arrowUp,
        currentModifiers: {LogicalKeyboardKey.alt},
      ),
      'search': KeyboardShortcut(
        name: 'Quick Search',
        description: 'Focus the search field',
        defaultKey: LogicalKeyboardKey.keyF,
        modifiers: {LogicalKeyboardKey.control},
        currentKey: LogicalKeyboardKey.keyF,
        currentModifiers: {LogicalKeyboardKey.control},
      ),
      'refresh': KeyboardShortcut(
        name: 'Refresh',
        description: 'Refresh current folder contents',
        defaultKey: LogicalKeyboardKey.f5,
        modifiers: {},
        currentKey: LogicalKeyboardKey.f5,
        currentModifiers: {},
      ),
      'newFolder': KeyboardShortcut(
        name: 'New Folder',
        description: 'Create a new folder',
        defaultKey: LogicalKeyboardKey.keyN,
        modifiers: {LogicalKeyboardKey.control, LogicalKeyboardKey.shift},
        currentKey: LogicalKeyboardKey.keyN,
        currentModifiers: {LogicalKeyboardKey.control, LogicalKeyboardKey.shift},
      ),
    };
  }

  AppSettings copyWith({
    bool? useDarkMode,
    bool? showHiddenFiles,
    bool? confirmBeforeDelete,
    bool? navigateWithSingleClick,
    String? defaultSort,
    double? editorFontSize,
    Map<String, KeyboardShortcut>? keyboardShortcuts,
  }) {
    return AppSettings(
      useDarkMode: useDarkMode ?? this.useDarkMode,
      showHiddenFiles: showHiddenFiles ?? this.showHiddenFiles,
      confirmBeforeDelete: confirmBeforeDelete ?? this.confirmBeforeDelete,
      navigateWithSingleClick: navigateWithSingleClick ?? this.navigateWithSingleClick,
      defaultSort: defaultSort ?? this.defaultSort,
      editorFontSize: editorFontSize ?? this.editorFontSize,
      keyboardShortcuts: keyboardShortcuts ?? Map.from(this.keyboardShortcuts),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'useDarkMode': useDarkMode,
      'showHiddenFiles': showHiddenFiles,
      'confirmBeforeDelete': confirmBeforeDelete,
      'navigateWithSingleClick': navigateWithSingleClick,
      'defaultSort': defaultSort,
      'editorFontSize': editorFontSize,
      'keyboardShortcuts': keyboardShortcuts.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final keyboardShortcutsJson = json['keyboardShortcuts'] as Map<String, dynamic>?;
    final keyboardShortcuts = keyboardShortcutsJson != null
        ? keyboardShortcutsJson.map(
            (key, value) => MapEntry(key, KeyboardShortcut.fromJson(value)),
          )
        : defaultKeyboardShortcuts();

    return AppSettings(
      useDarkMode: json['useDarkMode'] ?? false,
      showHiddenFiles: json['showHiddenFiles'] ?? false,
      confirmBeforeDelete: json['confirmBeforeDelete'] ?? true,
      navigateWithSingleClick: json['navigateWithSingleClick'] ?? true,
      defaultSort: json['defaultSort'] ?? 'Type',
      editorFontSize: json['editorFontSize'] ?? 14.0,
      keyboardShortcuts: keyboardShortcuts,
    );
  }
}

class KeyboardShortcut {
  final String name;
  final String description;
  final LogicalKeyboardKey defaultKey;
  final Set<LogicalKeyboardKey> modifiers;
  final LogicalKeyboardKey currentKey;
  final Set<LogicalKeyboardKey> currentModifiers;

  KeyboardShortcut({
    required this.name,
    required this.description,
    required this.defaultKey,
    required this.modifiers,
    required this.currentKey,
    required this.currentModifiers,
  });

  KeyboardShortcut copyWith({
    String? name,
    String? description,
    LogicalKeyboardKey? defaultKey,
    Set<LogicalKeyboardKey>? modifiers,
    LogicalKeyboardKey? currentKey,
    Set<LogicalKeyboardKey>? currentModifiers,
  }) {
    return KeyboardShortcut(
      name: name ?? this.name,
      description: description ?? this.description,
      defaultKey: defaultKey ?? this.defaultKey,
      modifiers: modifiers ?? this.modifiers,
      currentKey: currentKey ?? this.currentKey,
      currentModifiers: currentModifiers ?? this.currentModifiers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'defaultKeyId': defaultKey.keyId,
      'modifierIds': modifiers.map((key) => key.keyId).toList(),
      'currentKeyId': currentKey.keyId,
      'currentModifierIds': currentModifiers.map((key) => key.keyId).toList(),
    };
  }

  factory KeyboardShortcut.fromJson(Map<String, dynamic> json) {
    final defaultKeyId = json['defaultKeyId'];
    final currentKeyId = json['currentKeyId'];
    final modifierIds = (json['modifierIds'] as List<dynamic>).cast<int>();
    final currentModifierIds = (json['currentModifierIds'] as List<dynamic>).cast<int>();

    return KeyboardShortcut(
      name: json['name'],
      description: json['description'],
      defaultKey: LogicalKeyboardKey(defaultKeyId),
      modifiers: modifierIds.map((id) => LogicalKeyboardKey(id)).toSet(),
      currentKey: LogicalKeyboardKey(currentKeyId),
      currentModifiers: currentModifierIds.map((id) => LogicalKeyboardKey(id)).toSet(),
    );
  }

  // 获取可读的快捷键字符串（如 "Ctrl+Z"）
  String get displayString {
    String result = '';
    
    // 添加修饰键
    for (final modifier in currentModifiers) {
      if (modifier == LogicalKeyboardKey.control || modifier == LogicalKeyboardKey.controlLeft || modifier == LogicalKeyboardKey.controlRight) {
        result += 'Ctrl+';
      } else if (modifier == LogicalKeyboardKey.alt || modifier == LogicalKeyboardKey.altLeft || modifier == LogicalKeyboardKey.altRight) {
        result += 'Alt+';
      } else if (modifier == LogicalKeyboardKey.shift || modifier == LogicalKeyboardKey.shiftLeft || modifier == LogicalKeyboardKey.shiftRight) {
        result += 'Shift+';
      } else if (modifier == LogicalKeyboardKey.meta || modifier == LogicalKeyboardKey.metaLeft || modifier == LogicalKeyboardKey.metaRight) {
        result += 'Meta+';
      }
    }
    
    // 添加主键
    if (currentKey == LogicalKeyboardKey.keyZ) {
      result += 'Z';
    } else if (currentKey == LogicalKeyboardKey.arrowUp) {
      result += '↑';
    } else if (currentKey == LogicalKeyboardKey.arrowDown) {
      result += '↓';
    } else if (currentKey == LogicalKeyboardKey.arrowLeft) {
      result += '←';
    } else if (currentKey == LogicalKeyboardKey.arrowRight) {
      result += '→';
    } else if (currentKey == LogicalKeyboardKey.keyF) {
      result += 'F';
    } else if (currentKey == LogicalKeyboardKey.keyN) {
      result += 'N';
    } else if (currentKey == LogicalKeyboardKey.f5) {
      result += 'F5';
    } else if (currentKey == LogicalKeyboardKey.escape) {
      result += 'Esc';
    } else if (currentKey == LogicalKeyboardKey.tab) {
      result += 'Tab';
    } else if (currentKey == LogicalKeyboardKey.backspace) {
      result += 'Backspace';
    } else {
      // 尝试获取可读名称
      final keyLabel = currentKey.keyLabel;
      result += keyLabel.isNotEmpty ? keyLabel : 'Key ${currentKey.keyId}';
    }
    
    return result;
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  static const String _settingsKey = 'app_settings';
  
  SettingsNotifier() : super(AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      
      if (settingsJson != null) {
        final Map<String, dynamic> json = jsonDecode(settingsJson);
        state = AppSettings.fromJson(json);
      }
    } catch (e) {
      // 加载失败时使用默认设置
      state = AppSettings();
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(state.toJson());
      await prefs.setString(_settingsKey, json);
    } catch (e) {
      // 保存失败，可以添加错误处理
      debugPrint('Failed to save settings: $e');
    }
  }

  // 界面主题设置
  void setDarkMode(bool value) {
    state = state.copyWith(useDarkMode: value);
    _saveSettings();
  }

  // 文件浏览设置
  void setShowHiddenFiles(bool value) {
    state = state.copyWith(showHiddenFiles: value);
    _saveSettings();
  }

  void setConfirmBeforeDelete(bool value) {
    state = state.copyWith(confirmBeforeDelete: value);
    _saveSettings();
  }

  void setNavigateWithSingleClick(bool value) {
    state = state.copyWith(navigateWithSingleClick: value);
    _saveSettings();
  }

  void setDefaultSort(String value) {
    state = state.copyWith(defaultSort: value);
    _saveSettings();
  }

  // 编辑器设置
  void setEditorFontSize(double value) {
    state = state.copyWith(editorFontSize: value);
    _saveSettings();
  }

  // 键盘快捷键设置
  void updateKeyboardShortcut(String id, LogicalKeyboardKey key, Set<LogicalKeyboardKey> modifiers) {
    final shortcuts = Map<String, KeyboardShortcut>.from(state.keyboardShortcuts);
    final oldShortcut = shortcuts[id];
    
    if (oldShortcut != null) {
      shortcuts[id] = oldShortcut.copyWith(
        currentKey: key,
        currentModifiers: modifiers,
      );
      
      state = state.copyWith(keyboardShortcuts: shortcuts);
      _saveSettings();
    }
  }

  void resetKeyboardShortcut(String id) {
    final shortcuts = Map<String, KeyboardShortcut>.from(state.keyboardShortcuts);
    final oldShortcut = shortcuts[id];
    
    if (oldShortcut != null) {
      shortcuts[id] = oldShortcut.copyWith(
        currentKey: oldShortcut.defaultKey,
        currentModifiers: oldShortcut.modifiers,
      );
      
      state = state.copyWith(keyboardShortcuts: shortcuts);
      _saveSettings();
    }
  }

  void resetAllSettings() {
    state = AppSettings();
    _saveSettings();
  }
}

// 全局设置提供器
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});
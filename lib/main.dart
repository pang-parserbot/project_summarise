import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_summarise/providers/file_system_provider.dart';
import 'package:project_summarise/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: CodeBrowserApp()));
}

class CodeBrowserApp extends StatelessWidget {
  const CodeBrowserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Code Summariser',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const BrowserWithBackHandler(),
    );
  }
}

// 新增这个组件处理返回键
class BrowserWithBackHandler extends ConsumerWidget {
  const BrowserWithBackHandler({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: !ref.watch(fileSystemProvider.notifier).canGoBack,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        // 当物理回退键被按下时尝试导航回上一个文件夹
        final success = await ref.read(fileSystemProvider.notifier).navigateBack();
        
        // 如果没有上一级文件夹，则正常退出应用
        if (!success) {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: const HomeScreen(),
    );
  }
}
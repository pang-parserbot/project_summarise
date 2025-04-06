// lib/widgets/optimized_text_viewer.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OptimizedTextViewer extends StatefulWidget {
  final String text;
  final TextStyle style;
  
  const OptimizedTextViewer({
    super.key, 
    required this.text, 
    required this.style,
  });

  @override
  State<OptimizedTextViewer> createState() => _OptimizedTextViewerState();
}

class _OptimizedTextViewerState extends State<OptimizedTextViewer> {
  late List<String> _lines;
  late ScrollController _scrollController;
  bool _isSelecting = false;
  int? _selectionStart;
  int? _selectionEnd;
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _lines = widget.text.split('\n');
  }
  
  @override
  void didUpdateWidget(OptimizedTextViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _lines = widget.text.split('\n');
      // Reset selection when text changes
      _isSelecting = false;
      _selectionStart = null;
      _selectionEnd = null;
    }
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _copySelectedText(BuildContext context) {
    if (_selectionStart != null && _selectionEnd != null) {
      // Convert line indexes to actual character ranges
      final startLine = _selectionStart!;
      final endLine = _selectionEnd!;
      
      final selectedLines = _lines.sublist(
        startLine < endLine ? startLine : endLine,
        startLine < endLine ? endLine + 1 : startLine + 1,
      );
      
      final selectedText = selectedLines.join('\n');
      Clipboard.setData(ClipboardData(text: selectedText));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected text copied to clipboard')),
      );
      
      setState(() {
        _isSelecting = false;
        _selectionStart = null;
        _selectionEnd = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) {
        setState(() {
          _isSelecting = true;
        });
      },
      onLongPressEnd: (_) {
        if (_isSelecting && _selectionStart != null && _selectionEnd != null) {
          _copySelectedText(context);
        }
      },
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _lines.length,
              itemBuilder: (context, index) {
                final isSelected = _isSelecting && 
                    _selectionStart != null && 
                    _selectionEnd != null &&
                    ((index >= _selectionStart! && index <= _selectionEnd!) ||
                     (index >= _selectionEnd! && index <= _selectionStart!));
                
                return GestureDetector(
                  onTapDown: (_) {
                    if (_isSelecting) {
                      if (_selectionStart == null) {
                        setState(() {
                          _selectionStart = index;
                          _selectionEnd = index;
                        });
                      } else {
                        setState(() {
                          _selectionEnd = index;
                        });
                      }
                    }
                  },
                  onPanUpdate: (details) {
                    if (_isSelecting) {
                      // Calculate the line at the current position
                      final RenderBox box = context.findRenderObject() as RenderBox;
                      final position = box.globalToLocal(details.globalPosition);
                      final lineHeight = box.size.height / (_lines.length.toDouble());
                      final line = (position.dy / lineHeight).floor();
                      
                      if (line >= 0 && line < _lines.length) {
                        if (_selectionStart == null) {
                          setState(() {
                            _selectionStart = line;
                            _selectionEnd = line;
                          });
                        } else {
                          setState(() {
                            _selectionEnd = line;
                          });
                        }
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primaryContainer 
                        : Colors.transparent,
                    child: Text(
                      _lines[index],
                      style: widget.style,
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isSelecting)
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.small(
                onPressed: () => _copySelectedText(context),
                tooltip: 'Copy selected',
                child: const Icon(Icons.copy),
              ),
            ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/diary_provider.dart';

import '../models/diary_entry.dart';
import '../models/visual_element.dart';
import '../utils/canvas_element_factory.dart';
import '../widgets/glass_back_button.dart';
import '../widgets/journal_canvas_view.dart';
import 'create_entry_screen.dart';

class DetailScreen extends StatefulWidget {
  final DiaryEntry? entry;
  final List<VisualElement>? elements;
  final String? moodEmoji;
  final DateTime? entryDate;

  const DetailScreen({super.key, required this.entry})
      : elements = null,
        moodEmoji = null,
        entryDate = null;

  const DetailScreen.fromCanvas({
    super.key,
    required this.elements,
    this.moodEmoji,
    this.entryDate,
  }) : entry = null;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  List<VisualElement>? _canvas;
  late DateTime _when;
  late String _mood;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    if (widget.elements != null) {
      _canvas = CanvasElementFactory.cloneList(widget.elements!);
    } else if (e?.canvasElements != null && e!.canvasElements!.isNotEmpty) {
      _canvas = CanvasElementFactory.cloneList(e.canvasElements!);
    }
    _when = widget.entryDate ?? e?.entryDate ?? DateTime.now();
    _mood = widget.moodEmoji ?? e?.moodEmoji ?? '☀️';
  }

  @override
  void dispose() {
    if (_canvas != null) {
      for (final el in _canvas!) {
        el.dispose();
      }
    }
    super.dispose();
  }

  bool get _hasCanvas => _canvas != null && _canvas!.isNotEmpty;

  String _headerLine() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[_when.month - 1]} ${_when.day}  |  ${days[_when.weekday - 1]}  |  $_mood  |  22°C';
  }

  DiaryEntry? get _entryForEdit => widget.entry;

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Memory'),
          content: const Text('Are you sure you want to delete this memory? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && widget.entry != null && mounted) {
      await context.read<DiaryProvider>().deleteEntry(widget.entry!);
      if (!mounted) return;
      Navigator.of(context).pop(); // Go back to Home Screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Memory deleted successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasCanvas) {
      return _legacyFallback(context);
    }

    final canvasW = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 56),
              _headerStrip(),
              Expanded(
                child: JournalCanvasView(
                  elements: _canvas!,
                  readOnly: true,
                  canvasWidth: canvasW,
                ),
              ),
            ],
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 12,
            child: const GlassBackButton(),
          ),
          if (widget.entry != null)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              right: 12,
              child: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.black87),
                onPressed: _confirmDelete,
              ),
            ),
          Positioned(
            left: 16,
            bottom: MediaQuery.paddingOf(context).bottom + 16,
            child: FloatingActionButton.small(
              heroTag: 'detail_edit',
              backgroundColor: const Color(0xFF3D3D3D),
              onPressed: _openEditor,
              child: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerStrip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        _headerLine(),
        textAlign: TextAlign.center,
        style: GoogleFonts.cormorantGaramond(
          fontSize: 13,
          color: const Color(0xFF7A5C4A),
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  void _openEditor() {
    final e = _entryForEdit;
    if (e != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CreateEntryScreen(editEntry: e)),
      );
      return;
    }
    if (_canvas != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreateEntryScreen(
            editEntry: DiaryEntry.fromCanvas(
              _canvas!,
              moodEmoji: _mood,
              entryDate: _when,
            ),
          ),
        ),
      );
    }
  }

  Widget _legacyFallback(BuildContext context) {
    final e = widget.entry!;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 80, 24, 80),
            child: Column(
              children: [
                Text(
                  e.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dancingScript(fontSize: 36, color: const Color(0xFF5C4A3D)),
                ),
                const SizedBox(height: 24),
                Text(
                  e.content,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, height: 1.8, color: Colors.black87),
                ),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 12,
            child: const GlassBackButton(),
          ),
          if (widget.entry != null)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              right: 12,
              child: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.black87),
                onPressed: _confirmDelete,
              ),
            ),
          Positioned(
            left: 16,
            bottom: MediaQuery.paddingOf(context).bottom + 16,
            child: FloatingActionButton.small(
              heroTag: 'detail_edit_legacy',
              backgroundColor: const Color(0xFF3D3D3D),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CreateEntryScreen(editEntry: e)),
                );
              },
              child: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/diary_provider.dart';
import '../models/diary_entry.dart';
import '../models/visual_element.dart';
import '../widgets/journal_canvas_view.dart';
import '../utils/canvas_element_factory.dart';
import '../widgets/glass_back_button.dart';
import '../widgets/kilonotes_color_palette.dart';
import 'detail_screen.dart';

class CreateEntryScreen extends StatefulWidget {
  final DiaryEntry? editEntry;

  const CreateEntryScreen({super.key, this.editEntry});

  @override
  State<CreateEntryScreen> createState() => _CreateEntryScreenState();
}

class _CreateEntryScreenState extends State<CreateEntryScreen> {
  static const _paper = Color(0xFFFDFBF7);
  static const _noteCard = Color(0xFFF0F0F0);
  static const _accent = Color(0xFF6B5B7A);
  static const _minElementSize = 24.0;

  static const _moodEmojis = ['☀️', '☁️', '🌧️', '🥰', '😭', '😊', '🌙', '⭐', '😢', '🔥'];

  final List<VisualElement> _elements = [];
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scroll = ScrollController();

  int? _selectedIndex;
  int? _editingIndex;
  String _moodEmoji = '☀️';
  bool _showEmojiBar = false;
  DateTime _entryDate = DateTime.now();
  /// While true, canvas scroll is disabled so image frame drags are not stolen by [SingleChildScrollView].
  bool _lockCanvasScroll = false;

  @override
  void initState() {
    super.initState();
    final edit = widget.editEntry;
    if (edit != null) {
      _moodEmoji = edit.moodEmoji;
      _entryDate = edit.entryDate;
      if (edit.canvasElements != null) {
        _elements.addAll(edit.canvasElements!);
        for (var i = 0; i < _elements.length; i++) {
          final fn = _elements[i].focusNode;
          if (fn != null) _attachFocusListener(i, fn);
        }
      }
    }
  }

  @override
  void dispose() {
    if (widget.editEntry == null) {
      for (final e in _elements) {
        e.dispose();
      }
    }
    _scroll.dispose();
    super.dispose();
  }

  VisualElement? get _selected =>
      _selectedIndex != null && _selectedIndex! < _elements.length
          ? _elements[_selectedIndex!]
          : null;

  bool get _selectedIsText => _selected?.type == ElementType.text;
  QuillController? get _quill => _selected?.quillController;

  double _canvasWidth(BuildContext context) => MediaQuery.sizeOf(context).width;

  double _canvasHeight(BuildContext context) {
    final minH = MediaQuery.sizeOf(context).height * 0.55;
    if (_elements.isEmpty) return minH;
    var bottom = minH;
    for (final e in _elements) {
      final b = e.yPosition + e.height + 160;
      if (b > bottom) bottom = b;
    }
    return bottom;
  }

  String get _headerPlaceholder => 'Header — add text / image';

  bool _isEditing(int index) =>
      _editingIndex == index &&
      _elements[index].type == ElementType.text &&
      (_elements[index].focusNode?.hasFocus ?? false);

  void _attachFocusListener(int index, FocusNode focus) {
    focus.addListener(() {
      if (!mounted) return;
      setState(() {
        if (focus.hasFocus) {
          _editingIndex = index;
          _selectedIndex = index;
        } else if (_editingIndex == index) {
          _editingIndex = null;
        }
      });
    });
  }

  void _deselect() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _selectedIndex = null;
      _editingIndex = null;
    });
  }

  void _select(int index) => setState(() => _selectedIndex = index);

  void _moveElement(VisualElement el, int index, DragUpdateDetails d) {
    setState(() {
      el.position += d.delta;
      el.syncCoordinatesFromPosition();
      _selectedIndex = index;
    });
  }

  void _moveImageElement(VisualElement el, int index, DragUpdateDetails d) {
    setState(() {
      el.xPosition += d.delta.dx;
      el.yPosition += d.delta.dy;
      el.syncPositionFromCoordinates();
      _selectedIndex = index;
    });
  }

  void _persistCanvasImageState() {
    for (final el in _elements) {
      if (el.type != ElementType.image) continue;
      el.syncCoordinatesFromPosition();
    }
  }

  void _zoomImage(VisualElement el, double delta) {
    setState(() {
      el.scale = (el.scale + delta).clamp(0.5, 5.0);
    });
  }

  void _reassignHeader() {
    for (var i = 0; i < _elements.length; i++) {
      _elements[i].isHeader = i == 0;
    }
  }

  void _deleteAt(int index) {
    if (widget.editEntry == null) {
      _elements[index].dispose();
    }
    setState(() {
      _elements.removeAt(index);
      if (_selectedIndex == index) {
        _selectedIndex = null;
      } else if (_selectedIndex != null && _selectedIndex! > index) {
        _selectedIndex = _selectedIndex! - 1;
      }
      if (_editingIndex == index) {
        _editingIndex = null;
      } else if (_editingIndex != null && _editingIndex! > index) {
        _editingIndex = _editingIndex! - 1;
      }
      _reassignHeader();
    });
  }

  void _addText() {
    final c = QuillController.basic();
    final focus = FocusNode();
    final scroll = ScrollController();
    final index = _elements.length;
    _attachFocusListener(index, focus);

    setState(() {
      _elements.add(VisualElement(
        position: Offset(20, _elements.isEmpty ? 20 : 90 + _elements.length * 28),
        type: ElementType.text,
        width: 300,
        height: 120,
        isHeader: _elements.isEmpty,
        quillController: c,
        focusNode: focus,
        scrollController: scroll,
      ));
      _selectedIndex = index;
      _editingIndex = index;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => focus.requestFocus());
  }

  Future<void> _pickImage() async {
    final img = await _picker.pickImage(source: ImageSource.gallery);
    if (img == null) return;
    setState(() {
      _elements.add(VisualElement(
        position: Offset(30, _elements.isEmpty ? 20 : 110),
        type: ElementType.image,
        content: img.path,
        width: 220,
        height: 180,
        isHeader: _elements.isEmpty,
      ));
      _selectedIndex = _elements.length - 1;
    });
  }

  void _applySize(String key) {
    final c = _quill;
    if (c == null) return;
    c.formatSelection(switch (key) {
      'small' => const SizeAttribute('small'),
      'medium' => const SizeAttribute('medium'),
      _ => const SizeAttribute('large'),
    });
    setState(() {});
  }

  void _toggleBold() {
    final c = _quill;
    if (c == null) return;
    final on = c.getSelectionStyle().attributes.containsKey(Attribute.bold.key);
    c.formatSelection(on ? Attribute.clone(Attribute.bold, null) : Attribute.bold);
    setState(() {});
  }

  void _toggleItalic() {
    final c = _quill;
    if (c == null) return;
    final on = c.getSelectionStyle().attributes.containsKey(Attribute.italic.key);
    c.formatSelection(on ? Attribute.clone(Attribute.italic, null) : Attribute.italic);
    setState(() {});
  }

  void _applyColor(Color color) {
    final c = _quill;
    if (c == null) return;
    final hex = '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
    c.formatSelection(ColorAttribute(hex));
    setState(() {});
  }

  void _openPalette() {
    if (!_selectedIsText) return;
    KilonotesColorPaletteSheet.show(context, onColorSelected: _applyColor);
  }

  bool _hasAttr(Attribute a) =>
      _quill?.getSelectionStyle().attributes.containsKey(a.key) ?? false;

  String _sizeLabel() {
    final s = _quill?.getSelectionStyle().attributes[Attribute.size.key]?.value;
    return switch (s) {
      'small' => 'Small',
      'large' => 'Large',
      _ => 'Medium',
    };
  }

  String _headerLine() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[_entryDate.month - 1]} ${_entryDate.day}  |  ${days[_entryDate.weekday - 1]}  |  $_moodEmoji  |  22°C';
  }

  Future<void> _pickEntryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _entryDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Center(
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300, maxHeight: 360),
              child: child,
            ),
          ),
        );
      },
    );
    if (picked != null) {
      setState(() {
        _entryDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _entryDate.hour,
          _entryDate.minute,
        );
      });
    }
  }

  Future<void> _save() async {
    if (_elements.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Canvas Empty'),
          content: const Text('Your diary entry is empty. Please add some text or an image before saving.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    
    _persistCanvasImageState();
    final provider = context.read<DiaryProvider>();
    if (widget.editEntry != null) {
      provider.updateEntryFromCanvas(
        widget.editEntry!,
        List.from(_elements),
        moodEmoji: _moodEmoji,
        entryDate: _entryDate,
      );
      if (!context.mounted) return;
      Navigator.pop(context);
      Navigator.pop(context);
    } else {
      await provider.addFromCanvas(
        List.from(_elements),
        moodEmoji: _moodEmoji,
        entryDate: _entryDate,
      );
      if (!context.mounted) return;
      Navigator.pop(context);
    }
  }

  void _preview() {
    if (_elements.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen.fromCanvas(
          elements: CanvasElementFactory.cloneList(_elements),
          moodEmoji: _moodEmoji,
          entryDate: _entryDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: MediaQuery.paddingOf(context).top + 48),
              Expanded(child: _unifiedScrollContent(context)),
              if (_showEmojiBar) _emojiBar(),
              _toolbar(),
            ],
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 12,
            child: GlassBackButton(
              icon: Icons.close,
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: _elements.isEmpty ? null : _preview,
                  child: const Text('Preview'),
                ),
                IconButton(
                  icon: const Icon(Icons.check, color: Color(0xFF6D28D9)),
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerStrip() {
    return GestureDetector(
      onTap: _pickEntryDate,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        color: _paper,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _headerLine(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cormorant Garamond',
                fontSize: 13,
                color: Color(0xFF7A5C4A),
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }

  Widget _emojiBar() {
    return Container(
      height: 44,
      color: const Color(0xFFF5F5F5),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _moodEmojis.length,
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        itemBuilder: (_, i) {
          final e = _moodEmojis[i];
          final sel = e == _moodEmoji;
          return GestureDetector(
            onTap: () => setState(() => _moodEmoji = e),
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: sel ? Colors.white : Colors.transparent,
                shape: BoxShape.circle,
                border: sel ? Border.all(color: _accent.withValues(alpha: 0.4)) : null,
              ),
              child: Text(e, style: const TextStyle(fontSize: 20)),
            ),
          );
        },
      ),
    );
  }

  /// Date banner + canvas share one scroll viewport so text never overlaps the header.
  Widget _unifiedScrollContent(BuildContext context) {
    final canvasW = _canvasWidth(context);
    final canvasH = _canvasHeight(context);

    return GestureDetector(
      onTap: _deselect,
      behavior: HitTestBehavior.opaque,
      child: SingleChildScrollView(
        controller: _scroll,
        clipBehavior: Clip.none,
        physics: _lockCanvasScroll
            ? const NeverScrollableScrollPhysics()
            : const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _headerStrip(),
            SizedBox(
              height: canvasH + 48,
              width: canvasW + 48,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (_elements.isEmpty)
                    Center(
                      child: Text(
                        _headerPlaceholder,
                        style: TextStyle(
                          fontFamily: 'La Belle Aurore',
                          fontSize: 26,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ..._elements.asMap().entries.map((e) => _element(e.key, e.value)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _element(int index, VisualElement el) {
    if (el.type == ElementType.image) {
      return _imageElement(index, el);
    }

    final selected = index == _selectedIndex;
    final editing = _isEditing(index);

    return Positioned(
      left: el.xPosition,
      top: el.yPosition,
      child: GestureDetector(
        onTap: () => _select(index),
        onPanUpdate: (d) => _moveElement(el, index, d),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _dragEdge(index, el),
            _body(el, selected, editing),
            if (selected) ...[
              _deleteBtn(index),
              _resizeHandle(el),
            ],
          ],
        ),
      ),
    );
  }

  Widget _imageElement(int index, VisualElement el) {
    final selected = index == _selectedIndex;

    return Positioned(
      left: el.xPosition,
      top: el.yPosition,
      child: GestureDetector(
        onTap: () => _select(index),
        onPanStart: (_) {
          if (!_lockCanvasScroll) setState(() => _lockCanvasScroll = true);
        },
        onPanEnd: (_) {
          if (_lockCanvasScroll) setState(() => _lockCanvasScroll = false);
        },
        onPanCancel: () {
          if (_lockCanvasScroll) setState(() => _lockCanvasScroll = false);
        },
        onPanUpdate: (d) => _moveImageElement(el, index, d),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _imageCanvasBody(el, selected: selected),
            Positioned(
              top: -8,
              left: -8,
              child: _imageZoomControls(el),
            ),
            Positioned(
              top: -8,
              right: -8,
              child: _imageDeleteControl(index),
            ),
            if (selected) _resizeHandle(el),
          ],
        ),
      ),
    );
  }

  Widget _imageZoomControls(VisualElement el) => Material(
        color: Colors.white,
        elevation: 2,
        borderRadius: BorderRadius.circular(20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove, size: 18),
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () => _zoomImage(el, -0.15),
            ),
            IconButton(
              icon: const Icon(Icons.add, size: 18),
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () => _zoomImage(el, 0.15),
            ),
          ],
        ),
      );

  Widget _imageDeleteControl(int index) => Material(
        color: const Color(0xFF424242),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _deleteAt(index),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.delete_outline, size: 18, color: Colors.white),
          ),
        ),
      );

  /// Left-edge drag rail — always receives pan, even while typing in Quill.
  Widget _dragEdge(
    int index,
    VisualElement el, {
    void Function(DragUpdateDetails details)? onPan,
  }) =>
      Positioned(
        left: 0,
        top: 0,
        bottom: 0,
        width: 16,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: onPan ?? (d) => _moveElement(el, index, d),
          child: const ColoredBox(color: Colors.transparent),
        ),
      );

  Widget _body(VisualElement el, bool selected, bool editing) {
    final isText = el.type == ElementType.text;
    final showFill = isText && editing;

    return Container(
      width: el.width,
      height: el.height,
      decoration: BoxDecoration(
        color: showFill ? _noteCard : Colors.transparent,
        borderRadius: BorderRadius.circular(isText ? 8 : 0),
        border: selected
            ? Border.all(color: _accent.withValues(alpha: 0.55), width: 1.5)
            : null,
        boxShadow: showFill
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: isText ? _quillBox(el) : const SizedBox.shrink(),
    );
  }

  Widget _imageCanvasBody(VisualElement el, {required bool selected}) {
    return Container(
      width: el.width,
      height: el.height,
      decoration: BoxDecoration(
        border: Border.all(
          color: selected
              ? _accent.withValues(alpha: 0.55)
              : Colors.black.withValues(alpha: 0.1),
          width: selected ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.hardEdge,
        child: Transform.scale(
          scale: el.scale,
          alignment: Alignment.center,
          child: _img(el.content, el.width, el.height),
        ),
      ),
    );
  }

  Widget _quillBox(VisualElement el) {
    final placeholder = el.isHeader ? _headerPlaceholder : 'Write here…';
    final style = JournalCanvasView.journalTextStyle(isHeader: el.isHeader).copyWith(
      fontFamilyFallback: CanvasElementFactory.emojiFallback,
    );
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: QuillEditor(
        controller: el.quillController!,
        focusNode: el.focusNode!,
        scrollController: el.scrollController!,
        config: QuillEditorConfig(
          padding: const EdgeInsets.all(8),
          placeholder: placeholder,
          scrollable: true,
          expands: true,
          customStyles: DefaultStyles(
            paragraph: DefaultTextBlockStyle(
              style,
              const HorizontalSpacing(0, 0),
              const VerticalSpacing(0, 0),
              const VerticalSpacing(0, 0),
              null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _img(String path, double w, double h) {
    if (kIsWeb) return Image.network(path, width: w, height: h, fit: BoxFit.cover);
    return Image.file(File(path), width: w, height: h, fit: BoxFit.cover);
  }

  Widget _deleteBtn(int index) => Positioned(
        top: -10,
        right: -10,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _deleteAt(index),
          child: Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(color: Color(0xFF424242), shape: BoxShape.circle),
            child: const Icon(Icons.delete_outline, size: 16, color: Colors.white),
          ),
        ),
      );

  Widget _resizeHandle(VisualElement el) => Positioned(
        right: -14,
        bottom: -14,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (d) => setState(() {
            el.width = math.max(_minElementSize, el.width + d.delta.dx);
            el.height = math.max(_minElementSize, el.height + d.delta.dy);
          }),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4)],
              ),
              child: const Icon(Icons.open_in_full, size: 14, color: Colors.white),
            ),
          ),
        ),
      );

  Widget _toolbar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedIsText)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _tb(Icons.format_bold, 'Bold', _hasAttr(Attribute.bold), _toggleBold),
                    _tb(Icons.format_italic, 'Italic', _hasAttr(Attribute.italic), _toggleItalic),
                    _tb(Icons.palette_outlined, 'Color', false, _openPalette),
                  ],
                ),
              ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _tb(
                    Icons.emoji_emotions_outlined,
                    'Mood',
                    _showEmojiBar,
                    () => setState(() => _showEmojiBar = !_showEmojiBar),
                  ),
                  _chip(Icons.notes, 'Add Text', _addText),
                  _chip(Icons.image_outlined, 'Add Image', _pickImage),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tb(IconData icon, String label, bool on, VoidCallback tap) => InkWell(
        onTap: tap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: on ? _accent : Colors.grey.shade800),
              Text(label, style: TextStyle(fontSize: 10, color: on ? _accent : Colors.grey.shade600)),
            ],
          ),
        ),
      );


  Widget _chip(IconData icon, String label, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: Colors.grey.shade800),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
            ],
          ),
        ),
      );
}

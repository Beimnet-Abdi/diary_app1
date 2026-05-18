import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/visual_element.dart';
import '../utils/canvas_element_factory.dart';

/// Read-only or editable canvas stack matching the create-screen layout.
class JournalCanvasView extends StatelessWidget {
  final List<VisualElement> elements;
  final bool readOnly;
  final double canvasWidth;
  final Color paperColor;

  const JournalCanvasView({
    super.key,
    required this.elements,
    this.readOnly = true,
    required this.canvasWidth,
    this.paperColor = const Color(0xFFFDFBF7),
  });

  static double canvasHeightFor(List<VisualElement> elements, double minH) {
    if (elements.isEmpty) return minH;
    var bottom = minH;
    for (final e in elements) {
      final b = e.position.dy + e.height + 160;
      if (b > bottom) bottom = b;
    }
    return bottom;
  }

  static TextStyle journalTextStyle({double fontSize = 20, bool isHeader = false}) {
    return GoogleFonts.laBelleAurore(
      fontSize: isHeader ? 24 : fontSize,
      color: const Color(0xFF4A4A4A),
      height: 1.45,
      fontWeight: FontWeight.w400,
    ).copyWith(fontFamilyFallback: CanvasElementFactory.emojiFallback);
  }

  @override
  Widget build(BuildContext context) {
    final minH = MediaQuery.sizeOf(context).height * 0.45;
    final canvasH = canvasHeightFor(elements, minH);

    return Container(
      color: paperColor,
      child: SingleChildScrollView(
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(),
        child: SizedBox(
          height: canvasH + 48,
          width: canvasWidth + 48,
          child: Stack(
            clipBehavior: Clip.none,
            children: elements.map(_positionedElement).toList(),
          ),
        ),
      ),
    );
  }

  Widget _positionedElement(VisualElement el) {
    return Positioned(
      left: el.position.dx,
      top: el.position.dy,
      child: el.type == ElementType.text ? _textBox(el) : _imageBox(el),
    );
  }

  Widget _textBox(VisualElement el) {
    final controller = el.quillController;
    if (controller == null) {
      return SizedBox(
        width: el.width,
        height: el.height,
        child: Text(el.plainText, style: journalTextStyle(isHeader: el.isHeader)),
      );
    }

    if (readOnly) {
      return SizedBox(
        width: el.width,
        height: el.height,
        child: QuillEditor.basic(
          controller: QuillController(
            document: Document.fromDelta(controller.document.toDelta()),
            selection: const TextSelection.collapsed(offset: 0),
            readOnly: true,
          ),
          config: QuillEditorConfig(
            showCursor: false,
            padding: const EdgeInsets.all(10),
            scrollable: false,
            expands: false,
            customStyles: DefaultStyles(
              paragraph: DefaultTextBlockStyle(
                journalTextStyle(isHeader: el.isHeader).copyWith(
                  fontFamilyFallback: CanvasElementFactory.emojiFallback,
                ),
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

    return SizedBox(
      width: el.width,
      height: el.height,
      child: QuillEditor(
        controller: controller,
        focusNode: el.focusNode!,
        scrollController: el.scrollController!,
        config: QuillEditorConfig(
          padding: const EdgeInsets.all(10),
          scrollable: false,
          expands: false,
          customStyles: DefaultStyles(
            paragraph: DefaultTextBlockStyle(
              journalTextStyle(isHeader: el.isHeader),
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

  Widget _imageBox(VisualElement el) {
    return SizedBox(
      width: el.width,
      height: el.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _loadImage(el.content, el.width, el.height),
      ),
    );
  }

  Widget _loadImage(String path, double w, double h) {
    if (path.isEmpty) {
      return Container(color: Colors.grey.shade200);
    }
    if (kIsWeb) {
      return Image.network(path, width: w, height: h, fit: BoxFit.cover);
    }
    return Image.file(File(path), width: w, height: h, fit: BoxFit.cover);
  }
}

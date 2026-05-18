import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../models/visual_element.dart';

/// Clones canvas elements so saved entries keep independent controllers & layout.
class CanvasElementFactory {
  CanvasElementFactory._();

  static const emojiFallback = [
    'Noto Color Emoji',
    'Apple Color Emoji',
    'Segoe UI Emoji',
  ];

  static List<VisualElement> cloneList(List<VisualElement> source) =>
      source.map(clone).toList();

  static VisualElement clone(VisualElement e) {
    if (e.type == ElementType.text) {
      Document doc;
      if (e.quillController != null) {
        doc = Document.fromDelta(e.quillController!.document.toDelta());
      } else {
        doc = Document();
      }
      return VisualElement(
        position: e.position,
        width: e.width,
        height: e.height,
        type: ElementType.text,
        isHeader: e.isHeader,
        quillController: QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        ),
        focusNode: FocusNode(),
        scrollController: ScrollController(),
      );
    }
    return VisualElement(
      position: e.position,
      xPosition: e.xPosition,
      yPosition: e.yPosition,
      width: e.width,
      height: e.height,
      type: ElementType.image,
      content: e.content,
      isHeader: e.isHeader,
      scale: e.scale,
    );
  }
}

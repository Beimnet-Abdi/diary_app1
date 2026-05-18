import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

enum ElementType { text, image }

class VisualElement {
  Offset position;
  double xPosition;
  double yPosition;
  double width;
  double height;
  ElementType type;
  /// Image file path, or unused for text (content lives in [quillController]).
  String content;
  bool isHeader;

  QuillController? quillController;
  FocusNode? focusNode;
  ScrollController? scrollController;
  TransformationController? transformController;

  /// Serialized 4×4 transformation matrix for pinch-to-zoom state.
  List<double>? transformMatrix;

  double scale;
  Offset focalOffset;

  VisualElement({
    required this.position,
    double? xPosition,
    double? yPosition,
    this.width = 220,
    this.height = 120,
    required this.type,
    this.content = '',
    this.isHeader = false,
    this.quillController,
    this.focusNode,
    this.scrollController,
    this.transformController,
    this.transformMatrix,
    this.scale = 1.0,
    this.focalOffset = Offset.zero,
  })  : xPosition = xPosition ?? position.dx,
        yPosition = yPosition ?? position.dy;

  void syncPositionFromCoordinates() {
    position = Offset(xPosition, yPosition);
  }

  void syncCoordinatesFromPosition() {
    xPosition = position.dx;
    yPosition = position.dy;
  }

  void dispose() {
    quillController?.dispose();
    focusNode?.dispose();
    scrollController?.dispose();
    transformController?.dispose();
  }

  Document? get document => quillController?.document;

  String get plainText {
    if (type != ElementType.text || quillController == null) return content;
    return quillController!.document.toPlainText().trim();
  }
}

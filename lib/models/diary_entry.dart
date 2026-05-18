import 'visual_element.dart';

class DiaryEntry {
  final int id;
  final String title;
  final String content;
  final String date;
  final DateTime entryDate;
  final String? imageUrl;
  final String? localImagePath;
  final bool isImageHeader;
  final List<VisualElement>? canvasElements;
  final String moodEmoji;
  final List<double>? headerMatrix;

  DiaryEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.entryDate,
    this.imageUrl,
    this.localImagePath,
    this.isImageHeader = false,
    this.canvasElements,
    this.moodEmoji = '☀️',
    this.headerMatrix,
  });

  String? get displayImage => localImagePath ?? imageUrl;

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return DiaryEntry(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      title: json['title']?.toString() ?? 'Memory',
      content: json['body']?.toString() ?? '',
      date: '14\nMON',
      entryDate: now,
      imageUrl: null,
      isImageHeader: false,
    );
  }

  factory DiaryEntry.fromCanvas(
    List<VisualElement> elements, {
    String moodEmoji = '☀️',
    DateTime? entryDate,
  }) {
    VisualElement header = elements.first;
    for (final e in elements) {
      if (e.isHeader) {
        header = e;
        break;
      }
    }

    final isImage = header.type == ElementType.image;
    final when = entryDate ?? DateTime.now();
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final dateStr = '${when.day}\n${days[when.weekday - 1]}';

    final texts = elements.where((e) => e != header && e.type == ElementType.text).toList();
    final body = texts.map((e) => e.plainText).where((t) => t.isNotEmpty).join('\n\n');

    String title;
    if (isImage) {
      title = texts.isNotEmpty ? texts.first.plainText : 'Untitled';
    } else {
      title = header.plainText.isNotEmpty ? header.plainText : 'My Diary';
    }

    return DiaryEntry(
      id: when.millisecondsSinceEpoch,
      title: title,
      content: body.isNotEmpty ? body : 'A beautiful memory.',
      date: dateStr,
      entryDate: when,
      localImagePath: isImage ? header.content : null,
      isImageHeader: isImage,
      canvasElements: elements,
      moodEmoji: moodEmoji,
    );
  }
}

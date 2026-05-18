import 'package:flutter/material.dart';
import '../models/diary_entry.dart';
import '../models/visual_element.dart';
import '../services/api_service.dart';
import '../utils/canvas_element_factory.dart';

class DiaryProvider with ChangeNotifier {
  final List<DiaryEntry> _local = [];
  List<DiaryEntry> _remote = [];
  bool isLoading = false;
  String? errorMessage;
  bool hasInitiallyLoaded = false;

  /// Home cards are canvas-created entries; API sync runs in the background.
  List<DiaryEntry> get items {
    final all = List<DiaryEntry>.from(_local);
    all.sort((a, b) => b.entryDate.compareTo(a.entryDate));
    return all;
  }

  List<DiaryEntry> filteredItems({String query = ''}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return items;

    return items.where((e) {
      final monthNames = [
        'january', 'february', 'march', 'april', 'may', 'june',
        'july', 'august', 'september', 'october', 'november', 'december',
      ];
      final monthShort = [
        'jan', 'feb', 'mar', 'apr', 'may', 'jun',
        'jul', 'aug', 'sep', 'oct', 'nov', 'dec',
      ];
      final m = e.entryDate.month;
      final monthName = monthNames[m - 1];
      final monthAbbr = monthShort[m - 1];
      final yearStr = '${e.entryDate.year}';

      if (yearStr.contains(q)) return true;
      if (monthName.contains(q) || monthAbbr.contains(q)) return true;
      if ('$monthName $yearStr'.contains(q)) return true;
      if ('$monthAbbr $yearStr'.contains(q)) return true;
      if (e.title.toLowerCase().contains(q)) return true;
      if (e.content.toLowerCase().contains(q)) return true;
      return false;
    }).toList();
  }

  /// Month/year label for the home AppBar from visible entries or filter.
  String headerMonthYear({String query = ''}) {
    final list = filteredItems(query: query);
    if (list.isEmpty) {
      final n = DateTime.now();
      const months = [
        'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
        'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER',
      ];
      return '${months[n.month - 1]} / ${n.year}';
    }
    final d = list.first.entryDate;
    const months = [
      'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
      'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER',
    ];
    if (query.trim().isNotEmpty) {
      return '${months[d.month - 1]} / ${d.year}';
    }
    final distinct = <String>{};
    for (final e in list.take(12)) {
      distinct.add('${months[e.entryDate.month - 1]} / ${e.entryDate.year}');
    }
    if (distinct.length == 1) return distinct.first;
    return '${months[d.month - 1]} / ${d.year}';
  }

  Future<void> loadDiary({bool showLoading = true}) async {
    if (showLoading) {
      isLoading = true;
      notifyListeners();
    }
    try {
      final data = await ApiService().fetchEntries();
      _remote = data.map((e) => DiaryEntry.fromJson(e as Map<String, dynamic>)).toList();
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
      debugPrint(errorMessage!);
    } finally {
      isLoading = false;
      hasInitiallyLoaded = true;
      notifyListeners();
    }
  }

  Future<void> addFromCanvas(
    List<VisualElement> elements, {
    String moodEmoji = '☀️',
    DateTime? entryDate,
  }) async {
    final cloned = CanvasElementFactory.cloneList(elements);
    final entry = DiaryEntry.fromCanvas(
      cloned,
      moodEmoji: moodEmoji,
      entryDate: entryDate,
    );
    _local.insert(0, entry);
    errorMessage = null;
    notifyListeners();

    final header = _headerElement(cloned);
    try {
      await ApiService().createEntry({
        'id': entry.id,
        'title': entry.title,
        'bodyText': entry.content,
        'date': entry.entryDate.toIso8601String(),
        'imageUrl': entry.localImagePath ?? entry.imageUrl ?? '',
        'xPosition': header?.xPosition ?? 0,
        'yPosition': header?.yPosition ?? 0,
        'scale': header?.scale ?? 1.0,
        'width': header?.width ?? 0,
        'height': header?.height ?? 0,
      });
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
      debugPrint(errorMessage!);
    }
    notifyListeners();
  }

  VisualElement? _headerElement(List<VisualElement> elements) {
    for (final e in elements) {
      if (e.isHeader) return e;
    }
    return elements.isNotEmpty ? elements.first : null;
  }

  void updateEntryFromCanvas(
    DiaryEntry oldEntry,
    List<VisualElement> elements, {
    String moodEmoji = '☀️',
    DateTime? entryDate,
  }) {
    final cloned = CanvasElementFactory.cloneList(elements);
    final updatedEntry = DiaryEntry.fromCanvas(
      cloned,
      moodEmoji: moodEmoji,
      entryDate: entryDate,
    );

    final finalEntry = DiaryEntry(
      id: oldEntry.id,
      title: updatedEntry.title,
      content: updatedEntry.content,
      date: updatedEntry.date,
      entryDate: updatedEntry.entryDate,
      imageUrl: updatedEntry.imageUrl,
      localImagePath: updatedEntry.localImagePath,
      isImageHeader: updatedEntry.isImageHeader,
      canvasElements: updatedEntry.canvasElements,
      moodEmoji: updatedEntry.moodEmoji,
      headerMatrix: updatedEntry.headerMatrix,
    );

    final localIndex = _local.indexWhere((e) => e.id == oldEntry.id);
    if (localIndex != -1) {
      _local[localIndex] = finalEntry;
    } else {
      _local.insert(0, finalEntry);
    }
    notifyListeners();
  }

  Future<void> deleteEntry(DiaryEntry entry) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await ApiService().deleteEntry(entry.id);
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
      debugPrint(errorMessage!);
    } finally {
      _local.remove(entry);
      _remote.remove(entry);
      isLoading = false;
      notifyListeners();
    }
  }
}

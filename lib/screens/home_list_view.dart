import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/diary_provider.dart';
import '../models/diary_entry.dart';
import '../models/visual_element.dart';
import 'detail_screen.dart';

class HomeListView extends StatefulWidget {
  const HomeListView({super.key});

  @override
  State<HomeListView> createState() => _HomeListViewState();
}

class _HomeListViewState extends State<HomeListView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _searchBar(),
            Expanded(child: _entryList()),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              autofillHints: const [AutofillHints.name],
              decoration: InputDecoration(
                hintText: 'Search month or year…',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF3F3F3),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black, size: 28),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _entryList() {
    return Consumer<DiaryProvider>(
      builder: (context, provider, child) {
        final entries = provider.filteredItems(query: _searchController.text);

        if (provider.isLoading && !provider.hasInitiallyLoaded) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        if (entries.isEmpty) {
          return Center(
            child: Text(
              'No entries found.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: entries.length,
          itemBuilder: (_, i) => _DiaryCard(
            entry: entries[i],
            onTap: () => _openDetail(context, entries[i]),
          ),
        );
      },
    );
  }

  void _openDetail(BuildContext context, DiaryEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(entry: entry)),
    );
  }
}

class _DiaryCard extends StatelessWidget {
  final DiaryEntry entry;
  final VoidCallback onTap;

  const _DiaryCard({required this.entry, required this.onTap});

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  @override
  Widget build(BuildContext context) {
    final d = entry.entryDate;
    final time = TimeOfDay.fromDateTime(d).format(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              // FIX: Replaced deprecated withOpacity with withValues
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: SizedBox(
                width: 70,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Text(
                          '${d.day}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                            height: 1.1,
                          ),
                        ),
                        Text(
                          '${_months[d.month - 1].toUpperCase()} ${d.year}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          entry.moodEmoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(15),
                ),
                child: entry.isImageHeader && entry.displayImage != null
                    ? _coverImage(entry.displayImage!)
                    : Container(
                        color: Colors.grey.shade50,
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          entry.title,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dancingScript(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2D2D2D),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coverImage(String path) {
    Widget img;
    if (entry.localImagePath != null && !kIsWeb) {
      img = Image.file(
        File(path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else {
      img = Image.network(
        path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    final scale = _headerImageScale();
    if (scale != 1.0) {
      return Transform.scale(
        scale: scale,
        alignment: Alignment.center,
        child: img,
      );
    }
    return img;
  }

  double _headerImageScale() {
    final elements = entry.canvasElements;
    if (elements == null) return 1.0;
    for (final e in elements) {
      if (e.isHeader && e.type == ElementType.image) return e.scale;
    }
    return 1.0;
  }
}

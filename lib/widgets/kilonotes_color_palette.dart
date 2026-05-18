import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KilonotesColorPalette {
  KilonotesColorPalette._();

  static const simpleLight = [
    Color(0xFF000000),
    Color(0xFFFFFFFF),
    Color(0xFF4A4A4A),
    Color(0xFFBDBDBD),
    Color(0xFF5B7DB1),
    Color(0xFF3D3D3D),
    Color(0xFF6B7B8C),
    Color(0xFFE07A5F),
    Color(0xFF4A9B8E),
    Color(0xFFFFD54F),
  ];

  static List<Color> get fullGrid {
    final grid = <Color>[];
    for (var i = 0; i < 10; i++) {
      final v = (255 * i / 9).round().clamp(0, 255);
      grid.add(Color.fromARGB(255, v, v, v));
    }
    const hues = [0.0, 0.02, 0.08, 0.15, 0.22, 0.45, 0.55, 0.62, 0.72, 0.85];
    for (final h in hues) {
      grid.add(_hsl(h, 0.75, 0.48));
    }
    for (var row = 2; row < 8; row++) {
      final lightness = 0.42 - (row - 2) * 0.055;
      final saturation = 0.55 + (row - 2) * 0.04;
      for (var col = 0; col < 10; col++) {
        if (col == 0) {
          final v = (200 - (row - 2) * 28).clamp(30, 200);
          grid.add(Color.fromARGB(255, v, (v * 0.35).round(), (v * 0.35).round()));
        } else {
          grid.add(_hsl(hues[col], saturation.clamp(0.3, 0.9), lightness.clamp(0.15, 0.55)));
        }
      }
    }
    return grid;
  }

  static Color _hsl(double h, double s, double l) =>
      HSLColor.fromAHSL(1, h * 360, s, l).toColor();
}

class KilonotesColorPaletteSheet extends StatefulWidget {
  final Color? selectedColor;
  final ValueChanged<Color> onColorSelected;

  const KilonotesColorPaletteSheet({
    super.key,
    this.selectedColor,
    required this.onColorSelected,
  });

  static Future<void> show(
    BuildContext context, {
    Color? selectedColor,
    required ValueChanged<Color> onColorSelected,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => Center(
        child: Material(
          color: Colors.white,
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280, maxHeight: 320),
            child: KilonotesColorPaletteSheet(
              selectedColor: selectedColor,
              onColorSelected: onColorSelected,
            ),
          ),
        ),
      ),
    );
  }

  @override
  State<KilonotesColorPaletteSheet> createState() =>
      _KilonotesColorPaletteSheetState();
}

class _KilonotesColorPaletteSheetState extends State<KilonotesColorPaletteSheet> {
  Color? _picked;
  final List<Color> _custom = [];

  Color? get _active => _picked ?? widget.selectedColor;

  void _pick(Color c) {
    widget.onColorSelected(c);
    Navigator.pop(context);
  }

  Future<void> _addHexColor() async {
    final controller = TextEditingController(text: '#FFFFFF');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom color', style: TextStyle(fontSize: 15)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '#FFFFFF',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[#0-9A-Fa-f]')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    var hex = result.startsWith('#') ? result : '#$result';
    if (hex.length == 7) {
      try {
        final color = Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
        setState(() => _custom.add(color));
        _pick(color);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    const dotSize = 14.0;
    const gridSpacing = 4.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text(
                'Color',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          _label('SIMPLE LIGHT'),
          const SizedBox(height: 6),
          _row(KilonotesColorPalette.simpleLight, dotSize),
          const Divider(height: 12, color: Color(0xFFE8E8E8)),
          Row(
            children: [
              _label('CUSTOM'),
              const Spacer(),
              _plusBtn(_addHexColor),
            ],
          ),
          if (_custom.isNotEmpty) ...[
            const SizedBox(height: 6),
            _row(_custom, dotSize),
          ],
          const Divider(height: 10, color: Color(0xFFE8E8E8)),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 10,
              mainAxisSpacing: gridSpacing,
              crossAxisSpacing: gridSpacing,
            ),
            itemCount: KilonotesColorPalette.fullGrid.length,
            itemBuilder: (_, i) => _dot(KilonotesColorPalette.fullGrid[i], dotSize),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Text(
        t,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6),
      );

  Widget _row(List<Color> colors, double size) =>
      Row(children: colors.map((c) => _dot(c, size)).toList());

  Widget _dot(Color color, double size) {
    final sel = _active != null && _active!.toARGB32() == color.toARGB32();
    return GestureDetector(
      onTap: () => _pick(color),
      child: Container(
        width: size,
        height: size,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: color.computeLuminance() > 0.85
              ? Border.all(color: Colors.grey.shade300, width: 0.5)
              : null,
        ),
        child: sel
            ? Icon(
                Icons.check,
                size: size * 0.55,
                color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
              )
            : null,
      ),
    );
  }

  Widget _plusBtn(VoidCallback onTap) => InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: Icon(Icons.add, size: 16, color: Colors.grey.shade700),
        ),
      );
}

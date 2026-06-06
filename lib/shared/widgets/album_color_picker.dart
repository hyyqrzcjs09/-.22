import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/profile/application/user_settings.dart';

const albumBackgroundPresets = [
  Color(0xFFD5D7DA),
  Color(0xFFEADBC8),
  Color(0xFFD8E8D3),
  Color(0xFFD9E8F5),
  Color(0xFFE8D8EF),
];

class AlbumColorPicker extends ConsumerWidget {
  const AlbumColorPicker({
    required this.selected,
    super.key,
  });

  final Color selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final color in albumBackgroundPresets)
              _PresetColorDot(
                color: color,
                selected: selected == color,
                onTap: () => ref
                    .read(userSettingsProvider.notifier)
                    .setAlbumBackgroundColor(color),
              ),
          ],
        ),
        const SizedBox(height: 12),
        AlbumRgbColorEditor(selected: selected),
      ],
    );
  }
}

class _PresetColorDot extends StatelessWidget {
  const _PresetColorDot({
    required this.color,
    required this.onTap,
    required this.selected,
  });

  final Color color;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '选择相册背景色',
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white,
              width: 3,
            ),
          ),
          child: const SizedBox(width: 42, height: 42),
        ),
      ),
    );
  }
}

class AlbumRgbColorEditor extends ConsumerWidget {
  const AlbumRgbColorEditor({
    required this.selected,
    super.key,
  });

  final Color selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final argb = selected.toARGB32();
    final red = (argb >> 16) & 0xFF;
    final green = (argb >> 8) & 0xFF;
    final blue = argb & 0xFF;

    return Column(
      children: [
        _ColorSlider(
          label: 'R',
          value: red,
          onChanged: (value) => _setColor(ref, value, green, blue),
        ),
        _ColorSlider(
          label: 'G',
          value: green,
          onChanged: (value) => _setColor(ref, red, value, blue),
        ),
        _ColorSlider(
          label: 'B',
          value: blue,
          onChanged: (value) => _setColor(ref, red, green, value),
        ),
      ],
    );
  }

  void _setColor(WidgetRef ref, int red, int green, int blue) {
    ref
        .read(userSettingsProvider.notifier)
        .setAlbumBackgroundColor(Color.fromARGB(255, red, green, blue));
  }
}

class _ColorSlider extends StatelessWidget {
  const _ColorSlider({
    required this.label,
    required this.onChanged,
    required this.value,
  });

  final String label;
  final ValueChanged<int> onChanged;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        Expanded(
          child: Slider(
            max: 255,
            value: value.toDouble(),
            onChanged: (next) => onChanged(next.round()),
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(
            '$value',
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
      ],
    );
  }
}

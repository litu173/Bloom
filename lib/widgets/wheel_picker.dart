import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

class WheelPicker extends StatelessWidget {
  final List<String> items;
  final String value;
  final ValueChanged<String> onChanged;
  final AppColors colors;
  final double width;

  const WheelPicker({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    required this.colors,
    this.width = 70,
  });

  @override
  Widget build(BuildContext context) {
    final index = items.indexOf(value).clamp(0, items.length - 1);
    return SizedBox(
      width: width,
      height: 44 * 5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: colors.wheelBand,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          CupertinoPicker(
            itemExtent: 44,
            scrollController: FixedExtentScrollController(initialItem: index),
            selectionOverlay: const SizedBox.shrink(),
            onSelectedItemChanged: (i) => onChanged(items[i]),
            children: items
                .map((it) => Center(
                      child: Text(
                        it,
                        style: AppText.body(
                          colors,
                          size: it == value ? 24 : 18,
                          weight: it == value ? FontWeight.w600 : FontWeight.w400,
                          color: it == value ? colors.foreground : colors.mutedForeground,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

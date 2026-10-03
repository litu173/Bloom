import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

class SheetAction {
  final String label;
  final VoidCallback onTap;
  const SheetAction(this.label, this.onTap);
}

/// Shows an iOS-style modal bottom sheet with a grabber and a
/// Cancel · title · (action) nav bar, matching the web app's BottomSheet.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required AppColors colors,
  required String title,
  required Widget Function(BuildContext) builder,
  SheetAction? rightAction,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.92,
        expand: false,
        builder: (ctx, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 48,
                  height: 6,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(ctx).pop(),
                        child: Text('Cancel', style: AppText.body(colors, size: 16, color: colors.primary)),
                      ),
                      Text(title, style: AppText.body(colors, size: 16, weight: FontWeight.w600)),
                      GestureDetector(
                        onTap: rightAction?.onTap ?? () => Navigator.of(ctx).pop(),
                        child: Text(
                          rightAction?.label ?? 'Done',
                          style: AppText.body(colors, size: 16, weight: FontWeight.w600, color: colors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: builder(ctx),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

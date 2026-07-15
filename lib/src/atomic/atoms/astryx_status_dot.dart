import 'package:flutter/material.dart';

import '../../theme/astryx_palette.dart';

enum AstryxStatus { ready, streaming, warning, error, idle }

class AstryxStatusDot extends StatelessWidget {
  const AstryxStatusDot({required this.status, super.key, this.size = 8});

  final AstryxStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.astryx;
    final color = switch (status) {
      AstryxStatus.ready => palette.success,
      AstryxStatus.streaming => palette.category(AstryxCategory.blue).icon,
      AstryxStatus.warning => palette.warning,
      AstryxStatus.error => palette.error,
      AstryxStatus.idle => palette.textDisabled,
    };
    return Semantics(
      label: status.name,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

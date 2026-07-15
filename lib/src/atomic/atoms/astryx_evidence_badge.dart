import 'package:flutter/material.dart';

import '../../generated/astryx_evidence_contract.g.dart';
import 'astryx_badge.dart';

/// Generated evidence state rendered through Astryx semantic badge tokens.
class AstryxEvidenceBadge extends StatelessWidget {
  const AstryxEvidenceBadge({
    required this.state,
    super.key,
    this.label,
  });

  final AstryxEvidenceState state;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final contract = state.contract;
    return AstryxBadge(
      label ?? contract.label,
      tone: switch (contract.tone) {
        'success' => AstryxBadgeTone.success,
        'info' => AstryxBadgeTone.info,
        'warning' => AstryxBadgeTone.warning,
        'error' => AstryxBadgeTone.error,
        _ => AstryxBadgeTone.neutral,
      },
      icon: switch (state) {
        AstryxEvidenceState.passed => Icons.verified_rounded,
        AstryxEvidenceState.pending => Icons.schedule_rounded,
        AstryxEvidenceState.blocked => Icons.block_rounded,
        AstryxEvidenceState.expired => Icons.timer_off_outlined,
        AstryxEvidenceState.contradicted => Icons.sync_problem_rounded,
      },
    );
  }
}

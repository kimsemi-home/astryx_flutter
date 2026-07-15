import 'package:flutter/material.dart';

import '../../generated/astryx_evidence_contract.g.dart';
import '../../theme/astryx_palette.dart';
import '../atoms/astryx_badge.dart';
import '../atoms/astryx_button.dart';
import '../atoms/astryx_evidence_badge.dart';
import '../atoms/astryx_surface.dart';

/// Evidence-first decision card with no person/editorial approval state.
class AstryxEvidenceGateCard extends StatelessWidget {
  const AstryxEvidenceGateCard({
    required this.title,
    required this.state,
    required this.summary,
    required this.evidenceDigest,
    required this.passedCriteria,
    required this.totalCriteria,
    super.key,
    this.releasedSteps = const [],
    this.onInspect,
  })  : assert(totalCriteria > 0),
        assert(passedCriteria >= 0),
        assert(passedCriteria <= totalCriteria);

  final String title;
  final AstryxEvidenceState state;
  final String summary;
  final String evidenceDigest;
  final int passedCriteria;
  final int totalCriteria;
  final List<String> releasedSteps;
  final VoidCallback? onInspect;

  @override
  Widget build(BuildContext context) {
    final palette = context.astryx;
    final contract = state.contract;
    final progress = passedCriteria / totalCriteria;
    final openLoopReleased =
        contract.permitsOpenLoop && releasedSteps.isNotEmpty;
    return Semantics(
      container: true,
      label: '$title. ${contract.label}. '
          '$passedCriteria of $totalCriteria criteria passed. '
          '${openLoopReleased ? '${releasedSteps.length} declared steps released.' : 'Open loop closed.'} '
          'Evidence digest $evidenceDigest.',
      child: AstryxSurface(
        elevation: AstryxSurfaceElevation.low,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: palette.muted,
                    border: Border.all(color: palette.border),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.fact_check_outlined,
                    size: 21,
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        summary,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AstryxEvidenceBadge(state: state),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Evidence criteria',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                Text(
                  '$passedCriteria / $totalCriteria',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: palette.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: palette.muted,
                color: contract.permitsOpenLoop
                    ? palette.success
                    : state == AstryxEvidenceState.pending
                        ? palette.category(AstryxCategory.blue).icon
                        : palette.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              openLoopReleased
                  ? 'Released open-loop steps'
                  : 'Execution boundary',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            if (openLoopReleased)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final step in releasedSteps)
                    AstryxBadge(
                      step,
                      tone: AstryxBadgeTone.categorical,
                      category: AstryxCategory.teal,
                      icon: Icons.play_arrow_rounded,
                    ),
                ],
              )
            else
              Row(
                children: [
                  Icon(Icons.lock_outline_rounded,
                      size: 17, color: palette.textSecondary),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      contract.permitsOpenLoop
                          ? 'Criteria passed · no open-loop steps declared'
                          : 'Open loop remains closed until evidence passes',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            Divider(height: 28, color: palette.border),
            Row(
              children: [
                Icon(Icons.fingerprint_rounded,
                    size: 17, color: palette.textSecondary),
                const SizedBox(width: 7),
                Expanded(
                  child: SelectableText(
                    _shortDigest(evidenceDigest),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                  ),
                ),
                if (onInspect != null) ...[
                  const SizedBox(width: 12),
                  AstryxButton(
                    label: 'Inspect evidence',
                    variant: AstryxButtonVariant.secondary,
                    icon: Icons.arrow_forward_rounded,
                    onPressed: onInspect,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _shortDigest(String value) {
    if (value.length <= 28) return value;
    return '${value.substring(0, 18)}…${value.substring(value.length - 8)}';
  }
}

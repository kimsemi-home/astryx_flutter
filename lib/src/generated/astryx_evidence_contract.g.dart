// GENERATED CODE - DO NOT MODIFY BY HAND.
// Source: meta/evidence_states.json
// Source SHA-256: d90373229af474cad02584bcc4c79b3deed83336bab1fada9dee52eb41f262be

const astryxEvidenceContractName = "astryx.evidence-state.v1";
const astryxEvidenceContractSourceSha256 =
    'd90373229af474cad02584bcc4c79b3deed83336bab1fada9dee52eb41f262be';

enum AstryxEvidenceState { passed, pending, blocked, expired, contradicted }

class AstryxEvidenceStateContract {
  const AstryxEvidenceStateContract({
    required this.state,
    required this.label,
    required this.summary,
    required this.tone,
    required this.permitsOpenLoop,
    required this.order,
  });

  final AstryxEvidenceState state;
  final String label;
  final String summary;
  final String tone;
  final bool permitsOpenLoop;
  final int order;
}

const astryxEvidenceStateContracts =
    <AstryxEvidenceState, AstryxEvidenceStateContract>{
  AstryxEvidenceState.passed: AstryxEvidenceStateContract(
    state: AstryxEvidenceState.passed,
    label: "Evidence passed",
    summary: "All declared criteria are satisfied.",
    tone: "success",
    permitsOpenLoop: true,
    order: 10,
  ),
  AstryxEvidenceState.pending: AstryxEvidenceStateContract(
    state: AstryxEvidenceState.pending,
    label: "Evidence pending",
    summary: "Required evidence has not arrived yet.",
    tone: "info",
    permitsOpenLoop: false,
    order: 20,
  ),
  AstryxEvidenceState.blocked: AstryxEvidenceStateContract(
    state: AstryxEvidenceState.blocked,
    label: "Evidence blocked",
    summary: "At least one declared criterion failed.",
    tone: "error",
    permitsOpenLoop: false,
    order: 30,
  ),
  AstryxEvidenceState.expired: AstryxEvidenceStateContract(
    state: AstryxEvidenceState.expired,
    label: "Evidence expired",
    summary: "The evidence window or execution lease expired.",
    tone: "warning",
    permitsOpenLoop: false,
    order: 40,
  ),
  AstryxEvidenceState.contradicted: AstryxEvidenceStateContract(
    state: AstryxEvidenceState.contradicted,
    label: "Evidence contradicted",
    summary: "New evidence invalidated the prior decision.",
    tone: "error",
    permitsOpenLoop: false,
    order: 50,
  ),
};

extension AstryxEvidenceStateContractLookup on AstryxEvidenceState {
  AstryxEvidenceStateContract get contract =>
      astryxEvidenceStateContracts[this]!;
}

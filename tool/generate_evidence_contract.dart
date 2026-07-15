import 'dart:convert';
import 'dart:io';

import 'src/sha256.dart';

const _defaultSourcePath = 'meta/evidence_states.json';
const _defaultOutputPath = 'lib/src/generated/astryx_evidence_contract.g.dart';

Future<void> main(List<String> arguments) async {
  final check = arguments.contains('--check');
  final evidencePath = _valueAfter(arguments, '--evidence');
  final sourcePath = _valueAfter(arguments, '--source') ?? _defaultSourcePath;
  final outputPath = _valueAfter(arguments, '--output') ?? _defaultOutputPath;
  final sourceFile = File(sourcePath);
  if (!sourceFile.existsSync()) {
    stderr.writeln('Missing metaprogramming source: $sourcePath');
    exitCode = 2;
    return;
  }

  final sourceBytes = await sourceFile.readAsBytes();
  final source = jsonDecode(utf8.decode(sourceBytes));
  final model = _parse(source);
  final expected = _render(model, sha256Hex(sourceBytes), sourcePath);
  final outputFile = File(outputPath);
  final actual = outputFile.existsSync() ? await outputFile.readAsString() : '';
  final matches = actual == expected;

  if (!check) {
    await outputFile.parent.create(recursive: true);
    await outputFile.writeAsString(expected);
  }

  if (evidencePath != null) {
    final generatorFile = File.fromUri(Platform.script);
    final evidence = <String, Object>{
      'schema_version': 1,
      'contract': model.contract,
      'decision': check && !matches ? 'rejected' : 'passed',
      'mode': check ? 'check' : 'generate',
      'source': _artifact(sourcePath, sourceBytes),
      'generator': _artifact(
        generatorFile.path,
        await generatorFile.readAsBytes(),
      ),
      'output': _artifact(outputPath, utf8.encode(expected)),
      'state_count': model.states.length,
    };
    final evidenceFile = File(evidencePath);
    await evidenceFile.parent.create(recursive: true);
    await evidenceFile.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(evidence)}\n',
    );
  }

  if (check && !matches) {
    stderr.writeln(
      'Generated evidence contract drifted. Run '
      '`dart run tool/generate_evidence_contract.dart`.',
    );
    exitCode = 1;
    return;
  }
  stdout.writeln(
    check ? 'Evidence contract is synchronized.' : 'Generated $outputPath.',
  );
}

Map<String, Object> _artifact(String path, List<int> bytes) => {
      'path': path,
      'sha256': sha256Hex(bytes),
      'bytes': bytes.length,
    };

String? _valueAfter(List<String> arguments, String flag) {
  final index = arguments.indexOf(flag);
  if (index == -1) return null;
  if (index + 1 >= arguments.length) {
    throw FormatException('$flag requires a path');
  }
  return arguments[index + 1];
}

_EvidenceModel _parse(Object? source) {
  if (source is! Map<String, Object?>) {
    throw const FormatException('Evidence source must be a JSON object');
  }
  if (source['schema_version'] != 1) {
    throw const FormatException('Unsupported schema_version');
  }
  final contract = source['contract'];
  final rawStates = source['states'];
  if (contract is! String || contract.isEmpty || rawStates is! List) {
    throw const FormatException('contract and states are required');
  }
  final states = rawStates.map(_EvidenceState.fromJson).toList()
    ..sort((left, right) => left.order.compareTo(right.order));
  if (states.isEmpty) {
    throw const FormatException('At least one evidence state is required');
  }
  final ids = states.map((state) => state.id).toSet();
  if (ids.length != states.length) {
    throw const FormatException('Evidence state ids must be unique');
  }
  final permitting = states.where((state) => state.permitsOpenLoop).toList();
  if (permitting.length != 1 || permitting.single.id != 'passed') {
    throw const FormatException(
      'Only the passed state may permit declared open-loop work',
    );
  }
  return _EvidenceModel(contract, states);
}

String _render(_EvidenceModel model, String sourceHash, String sourcePath) {
  final buffer = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND.')
    ..writeln('// Source: $sourcePath')
    ..writeln('// Source SHA-256: $sourceHash')
    ..writeln()
    ..writeln(
        "const astryxEvidenceContractName = ${jsonEncode(model.contract)};")
    ..writeln('const astryxEvidenceContractSourceSha256 =')
    ..writeln("    '$sourceHash';")
    ..writeln()
    ..writeln(
      'enum AstryxEvidenceState { '
      '${model.states.map((state) => state.id).join(', ')} }',
    )
    ..writeln()
    ..writeln('class AstryxEvidenceStateContract {')
    ..writeln('  const AstryxEvidenceStateContract({')
    ..writeln('    required this.state,')
    ..writeln('    required this.label,')
    ..writeln('    required this.summary,')
    ..writeln('    required this.tone,')
    ..writeln('    required this.permitsOpenLoop,')
    ..writeln('    required this.order,')
    ..writeln('  });')
    ..writeln()
    ..writeln('  final AstryxEvidenceState state;')
    ..writeln('  final String label;')
    ..writeln('  final String summary;')
    ..writeln('  final String tone;')
    ..writeln('  final bool permitsOpenLoop;')
    ..writeln('  final int order;')
    ..writeln('}')
    ..writeln()
    ..writeln('const astryxEvidenceStateContracts =')
    ..writeln('    <AstryxEvidenceState, AstryxEvidenceStateContract>{');
  for (final state in model.states) {
    buffer
      ..writeln('  AstryxEvidenceState.${state.id}: '
          'AstryxEvidenceStateContract(')
      ..writeln('    state: AstryxEvidenceState.${state.id},')
      ..writeln('    label: ${jsonEncode(state.label)},')
      ..writeln('    summary: ${jsonEncode(state.summary)},')
      ..writeln('    tone: ${jsonEncode(state.tone)},')
      ..writeln('    permitsOpenLoop: ${state.permitsOpenLoop},')
      ..writeln('    order: ${state.order},')
      ..writeln('  ),');
  }
  buffer
    ..writeln('};')
    ..writeln()
    ..writeln('extension AstryxEvidenceStateContractLookup '
        'on AstryxEvidenceState {')
    ..writeln('  AstryxEvidenceStateContract get contract =>')
    ..writeln('      astryxEvidenceStateContracts[this]!;')
    ..writeln('}');
  return buffer.toString();
}

final class _EvidenceModel {
  const _EvidenceModel(this.contract, this.states);

  final String contract;
  final List<_EvidenceState> states;
}

final class _EvidenceState {
  const _EvidenceState({
    required this.id,
    required this.label,
    required this.summary,
    required this.tone,
    required this.permitsOpenLoop,
    required this.order,
  });

  factory _EvidenceState.fromJson(Object? value) {
    if (value is! Map<String, Object?>) {
      throw const FormatException('Each evidence state must be an object');
    }
    final id = value['id'];
    final label = value['label'];
    final summary = value['summary'];
    final tone = value['tone'];
    final permits = value['permits_open_loop'];
    final order = value['order'];
    if (id is! String || !RegExp(r'^[a-z][a-z0-9]*$').hasMatch(id)) {
      throw FormatException('Invalid evidence state id: $id');
    }
    if (label is! String || label.isEmpty || summary is! String) {
      throw FormatException('Invalid copy for evidence state $id');
    }
    if (tone is! String ||
        !const {'success', 'info', 'warning', 'error'}.contains(tone)) {
      throw FormatException('Invalid tone for evidence state $id');
    }
    if (permits is! bool || order is! int || order < 0) {
      throw FormatException('Invalid policy for evidence state $id');
    }
    return _EvidenceState(
      id: id,
      label: label,
      summary: summary,
      tone: tone,
      permitsOpenLoop: permits,
      order: order,
    );
  }

  final String id;
  final String label;
  final String summary;
  final String tone;
  final bool permitsOpenLoop;
  final int order;
}

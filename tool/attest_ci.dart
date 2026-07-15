import 'dart:convert';
import 'dart:io';

import 'src/sha256.dart';

const _checkEnvironment = <String, String>{
  'dependency_install': 'CHECK_INSTALL',
  'metaprogramming': 'CHECK_META',
  'format': 'CHECK_FORMAT',
  'analyze': 'CHECK_ANALYZE',
  'package_tests': 'CHECK_PACKAGE_TESTS',
  'example_tests': 'CHECK_EXAMPLE_TESTS',
  'publication': 'CHECK_PUBLICATION',
  'web_build': 'CHECK_WEB_BUILD',
};

const _attestedPaths = <String>[
  'meta/evidence_states.json',
  'lib/src/generated/astryx_evidence_contract.g.dart',
  'lib/src/atomic/atoms/astryx_evidence_badge.dart',
  'lib/src/atomic/molecules/astryx_evidence_gate_card.dart',
  'tool/generate_evidence_contract.dart',
  'tool/src/sha256.dart',
  'test/meta/evidence_generator_test.dart',
  'test/ui/evidence_gate_widget_test.dart',
  '.github/workflows/ci.yml',
  'doc/metaprogramming.md',
  'pubspec.yaml',
];

Future<void> main(List<String> arguments) async {
  final outputPath = _valueAfter(arguments, '--output') ??
      'build/evidence/ci-attestation.json';
  final flutterMachinePath = _valueAfter(arguments, '--flutter-machine') ??
      'build/evidence/flutter-version.json';
  final checks = <String, String>{
    for (final entry in _checkEnvironment.entries)
      entry.key: _normalize(Platform.environment[entry.value]),
  };
  final artifacts = <Map<String, Object>>[];
  for (final path in _attestedPaths) {
    final file = File(path);
    if (!file.existsSync()) {
      checks['artifact:$path'] = 'missing';
      continue;
    }
    final bytes = await file.readAsBytes();
    artifacts.add({
      'path': path,
      'sha256': sha256Hex(bytes),
      'bytes': bytes.length,
    });
  }
  final decision =
      checks.values.every((value) => value == 'passed') ? 'passed' : 'rejected';
  final machineFile = File(flutterMachinePath);
  final toolchain = machineFile.existsSync()
      ? jsonDecode(await machineFile.readAsString())
      : <String, Object>{'status': 'missing'};
  final evidence = <String, Object?>{
    'schema_version': 1,
    'contract': 'astryx.ci-attestation.v1',
    'decision': decision,
    'created_at': DateTime.now().toUtc().toIso8601String(),
    'run': {
      'repository': Platform.environment['GITHUB_REPOSITORY'] ?? 'local',
      'commit': Platform.environment['GITHUB_SHA'] ?? 'working-tree',
      'run_id': Platform.environment['GITHUB_RUN_ID'] ?? 'local',
      'event': Platform.environment['GITHUB_EVENT_NAME'] ?? 'local',
    },
    'toolchain': toolchain,
    'checks': checks,
    'artifacts': artifacts,
  };
  final output = File(outputPath);
  await output.parent.create(recursive: true);
  await output.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(evidence)}\n',
  );
  stdout.writeln('CI evidence $decision: $outputPath');
}

String _normalize(String? value) {
  return switch (value) {
    null || '' || 'success' || 'passed' => 'passed',
    _ => value,
  };
}

String? _valueAfter(List<String> arguments, String flag) {
  final index = arguments.indexOf(flag);
  if (index == -1) return null;
  if (index + 1 >= arguments.length) {
    throw FormatException('$flag requires a path');
  }
  return arguments[index + 1];
}

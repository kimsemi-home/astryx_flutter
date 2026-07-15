import 'dart:convert';
import 'dart:io';

import 'src/sha256.dart';

Future<void> main(List<String> arguments) async {
  final path = arguments.isEmpty
      ? 'build/evidence/ci-attestation.json'
      : arguments.single;
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('Missing CI attestation: $path');
    exitCode = 2;
    return;
  }
  final decoded = jsonDecode(await file.readAsString());
  if (decoded is! Map<String, Object?> ||
      decoded['contract'] != 'astryx.ci-attestation.v1') {
    stderr.writeln('Invalid CI attestation contract');
    exitCode = 2;
    return;
  }
  final failures = <String>[];
  if (decoded['decision'] != 'passed') {
    failures.add('decision=${decoded['decision']}');
  }
  final artifacts = decoded['artifacts'];
  if (artifacts is! List) {
    failures.add('artifacts=invalid');
  } else {
    for (final value in artifacts) {
      if (value is! Map<String, Object?> ||
          value['path'] is! String ||
          value['sha256'] is! String) {
        failures.add('artifact=invalid');
        continue;
      }
      final artifact = File(value['path']! as String);
      if (!artifact.existsSync()) {
        failures.add('${artifact.path}=missing');
        continue;
      }
      final actual = sha256Hex(await artifact.readAsBytes());
      if (actual != value['sha256']) {
        failures.add('${artifact.path}=digest-mismatch');
      }
    }
  }
  if (failures.isNotEmpty) {
    stderr.writeln('Evidence gate rejected: ${failures.join(', ')}');
    exitCode = 1;
    return;
  }
  stdout.writeln('Evidence gate passed: $path');
}

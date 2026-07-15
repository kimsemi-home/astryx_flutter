import 'dart:convert';
import 'dart:io';

import 'package:astryx_flutter/astryx_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/sha256.dart';

void main() {
  test('dependency-free SHA-256 matches the standard vectors', () {
    expect(
      sha256Hex(utf8.encode('')),
      'e3b0c44298fc1c149afbf4c8996fb924'
      '27ae41e4649b934ca495991b7852b855',
    );
    expect(
      sha256Hex(utf8.encode('abc')),
      'ba7816bf8f01cfea414140de5dae2223'
      'b00361a396177a9cb410ff61f20015ad',
    );
  });

  test('generated state contract is bound to the JSON source', () async {
    final source = await File('meta/evidence_states.json').readAsBytes();
    expect(astryxEvidenceContractSourceSha256, sha256Hex(source));
    expect(astryxEvidenceContractName, 'astryx.evidence-state.v1');
    expect(AstryxEvidenceState.values, hasLength(5));
    expect(
      AstryxEvidenceState.values
          .where((state) => state.contract.permitsOpenLoop),
      [AstryxEvidenceState.passed],
    );
  });

  test('metaprogramming check rejects generated drift', () async {
    final temporary = await Directory.systemTemp.createTemp('astryx-meta-');
    addTearDown(() => temporary.delete(recursive: true));
    final source = File('${temporary.path}/evidence_states.json');
    final output = File('${temporary.path}/contract.g.dart');
    await File('meta/evidence_states.json').copy(source.path);

    final generated = await Process.run(
      'dart',
      [
        'run',
        'tool/generate_evidence_contract.dart',
        '--source',
        source.path,
        '--output',
        output.path,
      ],
    );
    expect(
      generated.exitCode,
      0,
      reason: '${generated.stdout}\n${generated.stderr}',
    );
    await output.writeAsString('// drift\n', mode: FileMode.append);

    final checked = await Process.run(
      'dart',
      [
        'run',
        'tool/generate_evidence_contract.dart',
        '--check',
        '--source',
        source.path,
        '--output',
        output.path,
      ],
    );
    expect(checked.exitCode, 1);
    expect(checked.stderr, contains('Generated evidence contract drifted'));
  });
}

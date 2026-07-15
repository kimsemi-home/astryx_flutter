# Contributing

Contributions are welcome through focused pull requests.

## Local setup

```sh
flutter pub get
cd example && flutter pub get && cd ..
dart run tool/generate_evidence_contract.dart --check
flutter analyze
flutter test
```

## Design rules

- Add semantic values to tokens before adding one-off colors to widgets.
- Keep atoms domain-neutral and give molecules one clear product meaning.
- Do not make UI widgets call adapters directly in production examples.
- Preserve protocol semantics; add capabilities instead of forcing unrelated
  operations through one method.
- Accept injectable clients at network boundaries.
- Add tests for parsers, URI handling, error boundaries, and new widgets.
- Change `meta/evidence_states.json`, the generated Dart contract, and its
  tests together. CI rejects source/output drift.
- Never add private account, content, revenue, OAuth, or raw evidence values to
  public fixtures or CI attestations.

## Pull requests

Explain the behavior change, why it belongs at the selected Atomic Design
layer, which protocols are affected, and the checks you ran. Keep generated
platform changes separate from package behavior when possible.

Pull requests are released by the CI evidence gate. A person review is not a
substitute for the generated-contract check, tests, release web build, or
attested artifact hashes.

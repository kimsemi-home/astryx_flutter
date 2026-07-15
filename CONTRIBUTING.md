# Contributing

Contributions are welcome through focused pull requests.

## Local setup

```sh
flutter pub get
cd example && flutter pub get && cd ..
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

## Pull requests

Explain the behavior change, why it belongs at the selected Atomic Design
layer, which protocols are affected, and the checks you ran. Keep generated
platform changes separate from package behavior when possible.

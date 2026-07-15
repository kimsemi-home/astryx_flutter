# Astryx neutral mapping

## Provenance

The Flutter port is pinned so visual changes are reviewable and reproducible:

| Field | Value |
| --- | --- |
| Repository | <https://github.com/facebook/astryx> |
| Package | `@astryxdesign/theme-neutral` |
| Version | `0.1.5` |
| Commit | `c4c1f5b4430b5b83470219bd382465ff1bc7b69e` |
| Upstream source | `packages/themes/neutral/src/neutralTheme.ts` |
| Upstream license | MIT |

## Mapping rules

- CSS light/dark tuples map to `AstryxTokens.light` and
  `AstryxTokens.dark`.
- CSS `#RRGGBBAA` values map to Flutter `Color(0xAARRGGBB)`.
- Core backgrounds, text, overlays, status colors, borders, and all ten
  categorical ramps are preserved.
- Radius `rem` values are converted with a 16px root: 4, 6, 10, 12, and 28
  logical pixels plus the full pill radius.
- Motion values are preserved at 125ms, 300ms, and 700ms.
- Browser-only StyleX, CSS custom properties, icon registry, and syntax
  highlighting are not runtime dependencies of this Flutter package.
- Shadow strings are translated to Flutter `BoxShadow` approximations because
  CSS multi-shadow and Flutter composition models differ.

## Updating upstream

1. Read the new Astryx neutral theme and license.
2. Update the values and `AstryxSource` pin together.
3. Update this mapping and `THIRD_PARTY_NOTICES.md`.
4. Add tests for changed values in `test/ui/theme_widget_test.dart`.
5. Render both showcase themes and run the full validation suite.

Do not silently follow Astryx `main`: a pinned port gives consumers a stable
theme contract and makes upstream drift visible in review.

# Roam2World B2B Branding Assets

## Product identity

- Display name: `Roam2World B2B`
- Android application ID: `com.roam2world.b2b`
- iOS bundle ID: `com.roam2world.b2b`
- Primary color: `#2563EB`
- Launch background: `#0F172A`

## Required source assets

Keep editable master artwork outside the generated platform folders.

- `assets/branding/app_icon.png`
  - 1024 × 1024 px
  - PNG
  - Square canvas
  - No rounded corners
  - No transparency for the iOS master icon
- `assets/branding/app_icon_foreground.png`
  - 1024 × 1024 px
  - Transparent PNG
  - Android adaptive-icon foreground
  - Keep important artwork inside the center safe zone
- `assets/branding/app_icon_monochrome.png`
  - 432 × 432 px or larger
  - Single-color transparent PNG
  - Android themed icon source
- `assets/branding/store_feature_graphic.png`
  - 1024 × 500 px
  - Google Play feature graphic

## Platform output

After the final logo is approved, generated assets should replace the default Flutter launcher icons in:

- `android/app/src/main/res/mipmap-*`
- `android/app/src/main/res/mipmap-anydpi-v26`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset`

Do not manually stretch one small icon into every platform size. Always regenerate from the 1024 × 1024 master.

## Splash behavior

The native splash intentionally uses the product name on a solid navy background. It does not depend on the final logo, so app startup remains branded before launcher artwork is approved.

## Approval checklist

- Verify the icon at 48 px and 1024 px.
- Verify Android adaptive-icon masking with circle, squircle and rounded-square masks.
- Verify the iOS icon has no alpha channel.
- Verify the logo remains readable in light and dark launcher environments.
- Confirm trademark and brand approval before store submission.

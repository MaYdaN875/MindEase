# Stripe + Jitsi on Android

## Startup failure

With `stripe_android 14.1.0` and `jitsi_meet_flutter_sdk 13.1.1`, the
application failed before Flutter started:

```text
NoSuchFieldError: ReactBuildConfig.UNSTABLE_ENABLE_FUSEBOX_RELEASE
Unable to get provider androidx.startup.InitializationProvider
```

Jitsi resolves React Native `0.85.2`. Stripe ships compatibility shims in
`com.facebook.react` (and `com.facebook.proguard`), which must not shadow
Jitsi's real React Native classes.

## Project-local workaround

`build.gradle.kts` applies `stripe-react-isolation.gradle` only to
`stripe_android`. The task copies Java/Kotlin sources into that module's
generated build directory and relocates the shim package declarations and
references to `com.mindease.stripecompat`. Both compilers use the generated
sources. Resources, the Stripe SDK, and Jitsi's React Native remain unchanged.

The pub cache is not edited. Generated sources are not committed. A normal
`flutter build apk --debug` recreates them after cleaning. Keep the Gradle
script in version control; recheck it when upgrading either plugin, especially
if Stripe changes its source directory or introduces other shim packages.

## Optional Stripe Issuing dependency

Release lint can resolve Stripe's compile-only Issuing dependency transitively
and fail to find `com.google.android.gms:play-services-tapandpay:18.8.0`.
That SDK is distributed privately for card provisioning, not required to accept
consultation payments. `build.gradle.kts` excludes only this module within
`stripe_android`; lint remains enabled and the public payments SDK is retained.
Revisit this exclusion if MindEase ever implements Stripe Issuing.

Reference: https://github.com/flutter-stripe/flutter_stripe/issues/2252

## Validation on 2026-09-24

### Ongoing conference notification

After JaaS authentication succeeded, both devices failed in
`JitsiMeetOngoingConferenceService.onStartCommand` with
`Invalid notification (no valid small icon)`. The release shrinker marked
`drawable:ic_notification` unreachable. Jitsi's `OngoingNotification` uses
`getIdentifier` to resolve it. The resource keep XML now retains that icon too;
notification permissions and the foreground service remain enabled.

The professional's ongoing appointment now has a direct `Volver a la llamada`
button. The dismissal action in the completion dialog also requests a new
authorized video session instead of merely closing the dialog. Completion
remains a separate explicit action under consultation details.

### Joining a conference: mismatched OkHttp modules

Samsung crash traces on joining showed `NoClassDefFoundError:
okhttp3.internal.Util` from `okhttp3.JavaNetCookieJar`. Dependency insight
confirmed Stripe selected OkHttp 5.3.2 while React Native contributed
`okhttp-urlconnection:4.9.2`. The app now imports `okhttp-bom:5.3.2` to align
the public modules (including the URLConnection/cookie adapters), rather than
adding a fake internal class or downgrading Stripe's HTTP client.

Upstream alignment guidance: https://github.com/square/okhttp/blob/master/README.md

The professional agenda now opens with `Todas`; display filtering and counts
share `appointmentMatchesFilter`, so a CONFIRMED appointment whose consultation
is IN_PROGRESS appears in `En curso`, including after restarting the app.
This does not alter server states, time restrictions, appointments or payments.

### Release-only Jitsi resource crash

The first release APK compiled but crashed on both the API 35 emulator and
Samsung SM-S938B (Android 16). The exception was
`Resources$NotFoundException: String resource ID #0x0` in `DropboxModule`.
The shrinker report marked `string:dropbox_app_key` as unreachable.
`app/src/main/res/raw/mindease_keep.xml` now preserves that SDK resource,
which is resolved dynamically during initialization even with Dropbox disabled.
No Dropbox credentials or integration are required. Resource shrinking stays on.

### Build and runtime checks

- Release rebuilt with the resource keep rule: passed (180.5 seconds).
  Shrinker report confirms `dropbox_app_key` is reachable from the keep XML.
- Corrected release installed with `adb install -r` on Samsung Galaxy S25 Ultra
  (SM-S938B, Android 16): cold start passed, process remained alive,
  MainActivity resumed, and the new process crash log was empty.

- `flutter build apk --debug`: passed.
- `flutter build apk --release`: passed after the optional Issuing exclusion
  (231.8 seconds, 143.9 MB). Release lint was not disabled.
- Compiled Stripe `classes.jar`: zero classes in the original conflicting
  packages; 103 classes under `com/mindease/stripecompat/`.
- `adb install -r`: passed, preserving application data.
- Cold launch on Android API 35 x86_64: `Status: ok`; MainActivity resumed,
  process remained alive, and its crash log was empty.

This verifies installation and startup only. Before release, still test the
Stripe payment sheet in test mode and a JaaS call between two authorized users.
The release build currently uses
the project's debug signing key; configure distribution signing before publishing.
No payment or real consultation was
created as part of this fix. iOS is outside this Android workaround.

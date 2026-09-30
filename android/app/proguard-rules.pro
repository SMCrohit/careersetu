# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.auth.** { *; }
-keep class com.google.firebase.FirebaseApp { *; }
-keep class com.google.firebase.FirebaseOptions { *; }
-keep class com.google.firebase.provider.FirebaseInitProvider { *; }

# Firebase Phone Auth / reCAPTCHA / Play Integrity
-keep class com.google.android.recaptcha.** { *; }
-keep class com.google.android.play.core.integrity.** { *; }

# Custom App Classes / Data Models
-keep class com.orho.careersetu.careersetu.** { *; }

# Preserve generic signatures and annotations
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod

# Ignore missing Play Core classes referenced by Flutter deferred components
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-keepattributes InnerClasses

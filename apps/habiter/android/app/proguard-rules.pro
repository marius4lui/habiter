# Gson rules
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }

# Flutter Local Notifications rules
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }

# Prevent obfuscation of generic types which causes TypeToken errors
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep our own data classes if they are used with Gson
-keep class com.habiter.app.** { *; }

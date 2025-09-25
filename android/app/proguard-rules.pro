# Keep parcelize (hindari error kotlinx.parcelize.Parcelize)
-keep class kotlinx.parcelize.** { *; }
-dontwarn kotlinx.parcelize.**

# Keep Giphy SDK (dipakai oleh Jitsi SDK)
-keep class com.giphy.** { *; }
-dontwarn com.giphy.**

# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Flutter 相关规则
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# 保留 Flutter 引擎相关的类
-dontwarn io.flutter.embedding.**
-keep class io.flutter.embedding.** { *; }

# 第三方库相关规则
-keep class androidx.annotation.** { *; }
-keep class androidx.lifecycle.** { *; }
-keep class androidx.core.** { *; }

# SQLite 相关
-keep class org.sqlite.** { *; }
-keepclassmembers class * extends org.sqlite.database.** {
    public *;
}

# 相机相关
-keep class androidx.camera.** { *; }
-keep class androidx.exifinterface.** { *; }

# 网络相关 (Dio)
-keep class com.bumptech.glide.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# JSON 相关
-keepattributes *Annotation*,InnerClasses
-dontnote com.fasterxml.jackson.**
-keep class com.fasterxml.jackson.** { *; }

# 保留枚举类
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# 保留 Parcelable 实现
-keep class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# 保留序列化相关的类
-keepnames class * implements java.io.Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# 移除日志
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# 保留调试信息（可选，发布版本可以移除）
-keepattributes SourceFile,LineNumberTable
-keepattributes RuntimeVisibleAnnotations,RuntimeVisibleParameterAnnotations

# 不优化测试类
-keep class **.test.** { *; }
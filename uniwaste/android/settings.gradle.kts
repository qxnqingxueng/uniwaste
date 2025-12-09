pluginManagement {
    val flutterSdkPath = try {
        val properties = java.util.Properties()
        java.io.File("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    } catch (e: java.io.FileNotFoundException) {
        throw java.io.FileNotFoundException("local.properties not found. Please run 'flutter pub get' to generate it.")
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // UPGRADED to 8.2.1 to match Gradle 8.x
    id("com.android.application") version "8.2.1" apply false
    // UPGRADED to 2.0.20 to fix the Firebase metadata conflict
    id("org.jetbrains.kotlin.android") version "2.0.20" apply false
}

include(":app")
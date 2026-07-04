import java.util.Properties
import java.io.FileInputStream

val isNoGmsBuild = gradle.startParameter.taskNames.any { taskName ->
    taskName.contains("NoGms", ignoreCase = true)
}

// Generate dummy google-services.json if not present (for OSS builds without Firebase config).
// The app will build and run but push notifications will not work.
val googleServicesFile = file("google-services.json")
if (!isNoGmsBuild && !googleServicesFile.exists()) {
    googleServicesFile.writeText("""
{
  "project_info": {
    "project_number": "000000000000",
    "project_id": "dummy-project",
    "storage_bucket": "dummy-project.appspot.com"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:000000000000:android:0000000000000000",
        "android_client_info": {
          "package_name": "com.k9i.ccpocket"
        }
      },
      "api_key": [
        {
          "current_key": "AIzaSyDummy0000000000000000000000000000"
        }
      ]
    }
  ],
  "configuration_version": "1"
}
""".trimIndent())
    logger.warn("google-services.json not found. A dummy was generated. Push notifications will not work.")
}

plugins {
    id("com.android.application")
    id("com.google.gms.google-services") apply false
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

if (!isNoGmsBuild) {
    apply(plugin = "com.google.gms.google-services")
}

val keystorePropertiesFile = rootProject.file("keystore.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.k9i.ccpocket"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "29.0.13846066"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.k9i.ccpocket"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        resourceConfigurations += listOf("en", "ja", "zh-rCN")
    }

    flavorDimensions += "store"
    productFlavors {
        create("play") {
            dimension = "store"
        }
        create("noGms") {
            dimension = "store"
            applicationIdSuffix = ".nogms"
            versionNameSuffix = "-nogms"
            // Side-loaded noGMS builds keep legacy window resize behavior while
            // the chat input keyboard path is validated on Android 15+.
            targetSdk = 35
        }
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

androidComponents {
    beforeVariants(selector().all()) { variant ->
        val isNoGmsVariant = variant.productFlavors.any { it.second == "noGms" }
        variant.enable = if (isNoGmsBuild) isNoGmsVariant else !isNoGmsVariant
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.core:core-ktx:1.17.0")
}

flutter {
    source = "../.."
}

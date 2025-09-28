import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.project"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }
    kotlinOptions { jvmTarget = JavaVersion.VERSION_17.toString() }

    val kakaoNativeKeyFromEnv = providers.environmentVariable("KAKAO_NATIVE_APP_KEY")
    val kakaoNativeKeyFromGradleProp = providers.gradleProperty("KAKAO_NATIVE_APP_KEY")
    val localPropsProvider = providers.provider {
        val props = Properties()
        val file = rootProject.file("local.properties")
        if (file.exists()) file.inputStream().use { props.load(it) }
        props.getProperty("KAKAO_NATIVE_APP_KEY") ?: ""
    }
    val kakaoNativeKey: String = kakaoNativeKeyFromEnv
        .orElse(kakaoNativeKeyFromGradleProp)
        .orElse(localPropsProvider)
        .getOrElse("")

    defaultConfig {
        applicationId = "com.example.project"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        val kakaoScheme = if (kakaoNativeKey.isNotBlank()) "kakao$kakaoNativeKey" else "kakao_missing_key"
        manifestPlaceholders.putAll(mapOf("KAKAO_SCHEME" to kakaoScheme))
        resValue("string", "kakao_native_app_key", kakaoNativeKey)
    }

    buildTypes {
        getByName("release") { signingConfig = signingConfigs.getByName("debug") }
        getByName("debug") {
            println("KAKAO_SCHEME (debug): ${defaultConfig.manifestPlaceholders["KAKAO_SCHEME"]}")
        }
    }
}

kotlin {
    jvmToolchain(17)
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    implementation("com.google.android.gms:play-services-wearable:18.2.0")
}

flutter { source = "../.." }

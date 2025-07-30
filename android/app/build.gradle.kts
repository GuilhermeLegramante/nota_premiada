plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.hardsoft.notaPremiada"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.hardsoft.notaPremiada"
        minSdk = 21
        targetSdk = 35
        versionCode = 4
        versionName = "1.1.0"
    }

    signingConfigs {
        create("release") {
            storeFile = file("C:/Users/Public/nota_premiada_key.jks")
            storePassword = "#Gibson1959"
            keyAlias = "meu_alias"
            keyPassword = "#Gibson1959"
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.appcompat:appcompat:1.3.1")
    implementation("androidx.constraintlayout:constraintlayout:2.1.0")
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.5.21")
    implementation("com.android.tools:desugar_jdk_libs:1.1.5")
}

repositories {
    google()
    mavenCentral()
}

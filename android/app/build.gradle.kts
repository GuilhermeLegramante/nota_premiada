plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.hardsoft.notapremiada" // Defina seu namespace aqui
    compileSdk = 35 // Defina seu SDK de compilação mais recente
    compileSdk = 35
    defaultConfig {
        applicationId = "com.hardsoft.notapremiada" // Seu ID de aplicação único
        minSdk = 21 // Defina o SDK mínimo de acordo com a necessidade do seu app
        targetSdk = 35 // O SDK de destino que você está usando
        versionCode = 1 // Versão do código (geralmente é incrementado a cada nova versão)
        versionName = "1.0.0" // Versão da aplicação (mude conforme necessário)
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
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
    source = "../.." // Caminho para o diretório Flutter
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

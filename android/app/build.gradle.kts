plugins {
    id("com.android.application")
    // El complemento de Flutter se aplica después de los complementos de Android y Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.proyecto_chifacentro"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Definir el identificador único de la aplicación (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.proyecto_chifacentro"
        // Ajusta estos valores según los requisitos de la aplicación.
        // Más información: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Usa la versión de pubspec.yaml. Al separar los APK por arquitectura, 1000 * ABI_VERSION
        // se añade automáticamente por Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // Puedes conservar el valor de versionCode con la opción `-P force-version-code-ignoring-abi=true`
        // durante la compilación.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Configurar la firma de producción para publicar la aplicación.
            // Se usa la firma de prueba para permitir `flutter run --release` durante el desarrollo.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

import java.io.FileInputStream
import java.security.KeyStore
import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.cinetrekker.android"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    defaultConfig {
        applicationId = "com.cinetrekker.android"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties()
    var hasValidReleaseKeystore = false
    var releaseStoreFile: java.io.File? = null

    if (keystorePropertiesFile.exists()) {
        try {
            FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
            val storeFilePath = keystoreProperties.getProperty("storeFile")
            val storePassword = keystoreProperties.getProperty("storePassword")
            val keyAlias = keystoreProperties.getProperty("keyAlias")
            val keyPassword = keystoreProperties.getProperty("keyPassword")

            if (!storeFilePath.isNullOrBlank() &&
                !storePassword.isNullOrBlank() &&
                !keyAlias.isNullOrBlank() &&
                !keyPassword.isNullOrBlank()
            ) {
                val candidateFile = if (rootProject.file(storeFilePath).exists()) {
                    rootProject.file(storeFilePath)
                } else {
                    project.file(storeFilePath)
                }

                if (candidateFile.exists() && candidateFile.length() > 0L) {
                    var loaded = false
                    try {
                        val ks = KeyStore.getInstance(KeyStore.getDefaultType())
                        FileInputStream(candidateFile).use { fis ->
                            ks.load(fis, storePassword.toCharArray())
                        }
                        if (ks.containsAlias(keyAlias)) {
                            loaded = true
                        }
                    } catch (_: Exception) {
                        try {
                            val ks = KeyStore.getInstance("JKS")
                            FileInputStream(candidateFile).use { fis ->
                                ks.load(fis, storePassword.toCharArray())
                            }
                            if (ks.containsAlias(keyAlias)) {
                                loaded = true
                            }
                        } catch (_: Exception) {
                            loaded = false
                        }
                    }

                    if (loaded) {
                        hasValidReleaseKeystore = true
                        releaseStoreFile = candidateFile
                    }
                }
            }
        } catch (_: Exception) {
            hasValidReleaseKeystore = false
        }
    }

    signingConfigs {
        create("release") {
            if (hasValidReleaseKeystore && releaseStoreFile != null) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = releaseStoreFile
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        getByName("debug") {
            isMinifyEnabled = false
        }
        getByName("release") {
            signingConfig = if (hasValidReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
        languageVersion = "1.9"
    }

    packaging {
        resources {
            excludes += setOf("META-INF/AL2.0", "META-INF/LGPL2.1")
        }
    }
}

flutter {
    source = "../.."
}

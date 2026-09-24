allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Stripe 14 on AGP 9 can inherit the host JDK target instead of its Java 17 target.
// Keep this compatibility override scoped to the Stripe plugin.
subprojects {
    if (name == "stripe_android") {
        apply(from = rootProject.file("stripe-react-isolation.gradle"))
        // Stripe Issuing uses Google's private provisioning SDK. MindEase only
        // accepts payments; keep release lint enabled without this optional SDK.
        configurations.configureEach {
            exclude(group = "com.google.android.gms", module = "play-services-tapandpay")
        }
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Jitsi Flutter 13.1.1 declares compileSdk 34 while its Media3 dependencies require 35.
subprojects {
    if (name == "jitsi_meet_flutter_sdk") {
        plugins.withId("com.android.library") {
            extensions.getByType<com.android.build.api.variant.LibraryAndroidComponentsExtension>()
                .finalizeDsl { it.compileSdk = 35 }
        }
    }
}

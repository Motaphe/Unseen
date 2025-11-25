allprojects {
    repositories {
        google()
        mavenCentral()
    }
    
    // Ensure compatible androidx.core version for Flutter text input
    // The setStylusHandwritingEnabled method requires core 1.13.0+
    configurations.all {
        resolutionStrategy {
            // Use version compatible with Flutter and Android 16 (API 36)
            // This method was added in androidx.core:core:1.13.0
            force("androidx.core:core:1.13.1")
            force("androidx.core:core-ktx:1.13.1")
        }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Plugins are declared (not applied) in settings.gradle.kts; the app module applies them.
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

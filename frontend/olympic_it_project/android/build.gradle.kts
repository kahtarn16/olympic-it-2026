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

// Đoạn mã sửa lỗi: Ép SDK 36 an toàn cho cả project cũ lẫn mới
subprojects {
    val configureAndroid: Project.() -> Unit = {
        if (hasProperty("android")) {
            val android = extensions.findByName("android") as? com.android.build.gradle.BaseExtension
            android?.apply {
                if (compileSdkVersion == "android-34" || compileSdkVersion == "34") {
                    compileSdkVersion(36)
                }
            }
        }
    }

    // Nếu project đã chạy qua bước evaluate rồi thì thực thi luôn, ngược lại thì đợi sau evaluate
    if (state.executed) {
        configureAndroid()
    } else {
        afterEvaluate {
            configureAndroid()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
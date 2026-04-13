# Windows环境配置指南

本指南详细说明在Windows系统中配置Android开发环境的步骤，特别是在VSCode中开发这个智能鱼缸控制应用。

## 1. 系统环境变量配置

### 必需的环境变量

在系统环境变量中添加以下配置：

1. **JAVA_HOME**（如果使用自定义JDK）:
   ```
   JAVA_HOME=E:\Tools\OpenJDK 17.0.2
   ```

2. **ANDROID_HOME**:
   ```
   ANDROID_HOME=C:\Users\ChengCheng\AppData\Local\Android\Sdk
   ```

3. **Path**变量中添加:
   ```
   %JAVA_HOME%\bin
   %ANDROID_HOME%\platform-tools
   %ANDROID_HOME%\tools
   %ANDROID_HOME%\tools\bin
   ```

### 快速配置脚本（管理员权限运行）
```batch
@echo off
setx JAVA_HOME "E:\Tools\OpenJDK 17.0.2" /M
setx ANDROID_HOME "C:\Users\ChengCheng\AppData\Local\Android\Sdk" /M
setx PATH "%PATH%;%JAVA_HOME%\bin;%ANDROID_HOME%\platform-tools;%ANDROID_HOME%\tools;%ANDROID_HOME%\tools\bin" /M
echo Environment variables set. Please restart command prompt.
pause
```

## 2. 验证环境配置

打开新的命令提示符，运行以下命令验证：

```batch
# 验证Java
java -version
javac -version

# 验证ADB
adb --version

# 验证Android SDK
echo %ANDROID_HOME%
```

## 3. VSCode插件安装

安装以下VSCode插件（按`Ctrl+Shift+X`打开扩展商店）：

### 核心插件（必需）:
1. **Extension Pack for Java** (Microsoft) - Java开发支持包
2. **Android for VS Code** (adelphes) - Android项目支持
3. **Gradle for Java** (Microsoft) - Gradle任务管理
4. **XML** (Red Hat) - XML文件支持

### 可选插件:
- **Android ADB** (Amu) - ADB命令集成
- **Android Emulator** (adelphes) - 模拟器管理
- **Android SDK Manager** (adelphes) - SDK版本管理

## 4. 设备连接配置

### 连接真实Android设备
1. 手机开启"开发者选项":
   - 进入"设置" → "关于手机" → 连续点击"版本号"7次
2. 启用"USB调试":
   - "开发者选项" → "USB调试" → 启用
3. 连接电脑:
   - 使用USB线连接手机和电脑
   - 手机上授权USB调试
4. 验证连接:
   ```batch
   adb devices
   ```
   应显示设备序列号，状态为"device"

### 使用Android模拟器
#### 方法1: 通过Android Studio启动
1. 打开Android Studio
2. 点击工具栏"Device Manager"
3. 选择已有模拟器，点击"启动"

#### 方法2: 命令行启动
```batch
# 列出所有模拟器
emulator -list-avds

# 启动模拟器（替换YourAVDName）
emulator -avd YourAVDName -netdelay none -netspeed full
```

## 5. 项目特定配置

### 项目已包含的配置
1. **`gradle.properties`** - 指定Java Home路径
2. **`local.properties`** - 指定Android SDK路径
3. **`.vscode/`目录** - VSCode工作区配置
4. **批处理脚本** - 快速构建命令

### 自定义配置检查
如果环境路径不同，更新以下文件：

1. **`gradle.properties`**:
   ```properties
   org.gradle.java.home=你的JDK路径
   ```

2. **`local.properties`**:
   ```properties
   sdk.dir=你的Android SDK路径
   ```

3. **`.vscode/settings.json`**:
   ```json
   {
       "android-sdk.path": "你的Android SDK路径"
   }
   ```

## 6. 常见问题解决

### 问题1: "adb: command not found"
**原因**: ADB未添加到系统PATH
**解决**:
```batch
# 临时解决方案（当前会话）
set PATH=%PATH%;C:\Users\ChengCheng\AppData\Local\Android\Sdk\platform-tools

# 永久解决方案
# 按照第1节配置系统环境变量
```

### 问题2: Gradle构建失败，Java版本不兼容
**原因**: Gradle 8.0需要Java 11+
**解决**:
1. 确保`gradle.properties`中正确设置了Java Home
2. 或降级Gradle版本（本项目已配置为使用JDK 17）

### 问题3: 模拟器无法启动
**原因**: 缺少系统镜像或HAXM未安装
**解决**:
1. 打开Android Studio → SDK Manager
2. 安装"Intel x86 Emulator Accelerator (HAXM)"
3. 安装相应的系统镜像

### 问题4: VSCode无法识别Android项目
**原因**: 插件未正确加载
**解决**:
1. 按`Ctrl+Shift+P` → "Developer: Reload Window"
2. 或重启VSCode

## 7. 开发工作流程

### 日常开发流程
```batch
# 1. 启动模拟器或连接设备
emulator -avd Pixel_5_API_33

# 2. 在VSCode中打开项目
code .

# 3. 编写代码后构建
build.bat

# 4. 安装到设备
run.bat

# 5. 调试
# 在VSCode中设置断点 → 按F5启动调试
```

### 快速命令参考
```batch
# 清理项目
clean.bat

# 构建APK
build.bat

# 安装到设备
run.bat

# 手动ADB命令
adb install app\build\outputs\apk\debug\app-debug.apk
adb uninstall cacom.example.smarthome
adb logcat | findstr "cacom.example.smarthome"
```

## 8. 性能优化建议

### VSCode设置优化
在`settings.json`中添加:
```json
{
    "java.jdt.ls.vmargs": "-Xmx4G",
    "java.import.gradle.java.home": "E:\\Tools\\OpenJDK 17.0.2",
    "files.exclude": {
        "**/.gradle": true,
        "**/build": true,
        "**/.idea": true
    }
}
```

### Gradle优化
在`gradle.properties`中添加:
```properties
org.gradle.daemon=true
org.gradle.parallel=true
org.gradle.caching=true
org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=1024m
```

## 9. 项目结构说明

```
项目根目录/
├── .vscode/                    # VSCode配置
│   ├── settings.json          # 编辑器设置
│   ├── tasks.json             # 构建任务
│   ├── launch.json            # 调试配置
│   └── java-formatter.xml     # 代码格式化
├── app/                       # Android应用模块
│   ├── src/main/java/         # Java源代码
│   ├── src/main/res/          # 资源文件
│   └── libs/                  # 第三方库
├── gradle/                    # Gradle配置
├── 批处理脚本/                # 快速命令
│   ├── build.bat             # 构建脚本
│   ├── run.bat               # 运行脚本
│   └── clean.bat             # 清理脚本
└── 文档/
    ├── README-VSCODE.md      # VSCode开发指南
    └── WINDOWS-ENV-SETUP.md  # 本指南
```

## 10. 获取帮助

### 在线资源
- [Android开发者文档](https://developer.android.com)
- [VSCode Java文档](https://code.visualstudio.com/docs/languages/java)
- [Gradle用户手册](https://docs.gradle.org)

### 项目问题
1. 检查控制台错误信息
2. 查看`app/build/reports/`中的构建报告
3. 使用`--stacktrace`参数获取详细错误:
   ```batch
   gradlew.bat assembleDebug --stacktrace
   ```

### 联系支持
如有本项目特定问题，请检查代码注释或查阅相关文档。
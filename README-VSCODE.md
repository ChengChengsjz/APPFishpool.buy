# VSCode Android开发指南

本指南介绍如何在VSCode中开发、构建和调试这个Android智能鱼缸控制应用。

## 环境要求

1. **Java Development Kit (JDK) 8+** - 已随Android Studio安装
2. **Android SDK** - 路径：`C\:\\Users\\ChengCheng\\AppData\\Local\\Android\\Sdk`（已配置在`local.properties`中）
3. **Gradle 8.0** - 项目已包含Gradle Wrapper
4. **VSCode** + 必要插件

## 安装VSCode插件

在VSCode扩展商店中搜索并安装以下插件：

### 必需插件：
- **Extension Pack for Java** (Microsoft) - Java开发支持
- **Android for VS Code** (adelphes) - Android项目支持
- **Gradle for Java** (Microsoft) - Gradle任务管理
- **XML** (Red Hat) - XML文件支持

### 可选插件：
- **Android ADB** (Amu) - ADB命令集成
- **Android Emulator** (adelphes) - 模拟器管理
- **Android SDK Manager** (adelphes) - SDK版本管理

## 项目配置

### 1. 打开项目
```bash
# 在VSCode中打开项目目录
code e:\Project\Programming\Project\Android APP\fishtank12
```

### 2. 等待Java项目导入
首次打开时，VSCode会自动检测Gradle项目并导入。底部状态栏会显示"Loading Java projects..."，完成后会显示项目结构。

### 3. 配置SDK路径（如果未自动检测）
如果Android SDK路径不同，修改`.vscode/settings.json`中的：
```json
"android-sdk.path": "你的SDK路径"
```

## 常用命令

### 通过VSCode终端
```bash
# 清理项目
./gradlew clean

# 构建Debug版本
./gradlew assembleDebug

# 构建Release版本
./gradlew assembleRelease

# 安装到设备
./gradlew installDebug

# 运行单元测试
./gradlew test

# 运行Android测试
./gradlew connectedAndroidTest
```

### 通过VSCode任务系统
按`Ctrl+Shift+P` → 输入"Tasks: Run Task" → 选择任务：
- **Gradle: Clean** - 清理项目
- **Gradle: Build Debug** - 构建Debug APK
- **Gradle: Build Release** - 构建Release APK
- **Gradle: Install Debug** - 安装到设备
- **Gradle: Run Tests** - 运行单元测试

## 调试应用

### 方法1：使用ADB安装后调试
1. 构建并安装应用：运行任务 **Gradle: Install Debug**
2. 在手机上启动应用
3. 在VSCode中打开`MainActivity.java`
4. 设置断点（点击行号左侧）
5. 按`F5`启动调试，选择"Attach to Android Process"

### 方法2：直接运行调试
1. 确保设备已连接（`adb devices`显示设备）
2. 按`F5` → 选择"Run Android App"
3. VSCode会自动构建并安装应用到设备

## 布局预览

VSCode对Android布局文件的预览支持有限，但有以下方式：

### 1. XML语法高亮和格式化
- 打开`activity_main.xml`或`dialog_login.xml`
- 右键选择"Format Document" (`Shift+Alt+F`) 格式化XML
- 使用`Ctrl+Space`获取代码补全

### 2. 使用外部工具预览
- 保持Android Studio打开，在Android Studio中查看布局预览
- 使用在线XML预览工具

### 3. 快速查看组件ID
在Java代码中`Ctrl+点击`XML中定义的ID（如`R.id.Sensor1`）可跳转到XML定义。

## 设备管理

### 连接真实设备
1. 手机开启"开发者选项"和"USB调试"
2. 通过USB连接电脑
3. 在终端运行：`adb devices` 确认设备连接

### 使用模拟器
1. 启动Android Studio中的模拟器
2. 或在命令行启动：`emulator -avd 模拟器名称`
3. VSCode会自动检测到运行中的模拟器

## 常见问题解决

### 1. Java项目未正确导入
- 按`Ctrl+Shift+P` → "Java: Clean Java Language Server Workspace"
- 重启VSCode

### 2. Gradle构建失败
```bash
# 清理Gradle缓存
./gradlew cleanBuildCache

# 重新同步项目
./gradlew --refresh-dependencies
```

### 3. ADB设备未识别
```bash
# 重启ADB服务
adb kill-server
adb start-server

# 检查设备连接
adb devices
```

### 4. 插件功能不完整
某些Android Studio专有功能（如布局实时预览、性能分析器）在VSCode中不可用。对于这些需求，建议使用Android Studio。

## 项目结构说明

```
fishtank12/
├── .vscode/                    # VSCode配置
│   ├── settings.json          # 工作区设置
│   ├── tasks.json             # 任务定义
│   ├── launch.json            # 调试配置
│   └── java-formatter.xml     # Java代码格式化配置
├── app/
│   ├── src/main/java/cacom/example/smarthome/
│   │   └── MainActivity.java  # 主程序逻辑
│   ├── src/main/res/layout/
│   │   ├── activity_main.xml  # 主界面布局
│   │   └── dialog_login.xml   # 登录对话框布局
│   └── libs/                  # 第三方库
│       └── org.eclipse.paho.client.mqttv3-1.2.0.jar
├── build.gradle               # 项目构建配置
├── app/build.gradle           # 模块构建配置
└── local.properties           # SDK路径配置
```

## MQTT配置说明

应用使用MQTT协议与硬件通信。关键配置在`MainActivity.java`中：

```java
private String host = "tcp://47.109.89.8:1883";  // MQTT服务器地址
private String userName = "root23";               // MQTT用户名
private String passWord = "root34";               // MQTT密码
```

如需更改服务器地址或认证信息，修改上述变量。

## 开发建议

1. **双IDE工作流**：在VSCode中编写代码，在Android Studio中预览布局和调试复杂问题
2. **版本控制**：使用Git管理代码变更
3. **定期构建**：频繁运行`./gradlew assembleDebug`确保代码无编译错误
4. **设备测试**：在真实设备上测试应用，特别是MQTT网络功能

## 下一步

- 尝试修改界面布局（`activity_main.xml`）
- 调整MQTT配置以连接你的硬件设备
- 添加新功能（如数据记录、图表显示）
- 生成发布版APK（`./gradlew assembleRelease`）

## 更多资源

- [Windows环境配置指南](WINDOWS-ENV-SETUP.md) - 详细的Windows系统环境设置
- 项目中的批处理脚本：`build.bat`, `run.bat`, `clean.bat`
- [Android开发者文档](https://developer.android.com)

如需帮助，请参考项目中的代码注释或Android官方文档。
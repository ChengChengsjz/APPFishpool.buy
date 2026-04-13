@echo off
echo 正在启动Android模拟器管理器...
echo 如果窗口关闭太快，请查看下面的错误信息
echo.
echo 按Ctrl+C可取消运行
pause

REM 运行主脚本
call android-emulator.bat

REM 如果主脚本正常退出，这里会执行
echo.
echo 模拟器管理器已退出。
echo 按任意键关闭窗口...
pause >nul
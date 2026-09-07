@echo off
set "JAVA_HOME=D:\Android\jbr"
set "ANDROID_HOME=D:\Android\Sdk"
set "PATH=D:\Dev\flutter\bin;D:\Android\jbr\bin;D:\Android\Sdk\platform-tools;D:\Android\Sdk\emulator;%PATH%"
cd /d "d:\tai nguyen\DuAn\agricare-ai\apps\mobile_flutter"
title AgriCare AI - Flutter Hot Reload
flutter run --flavor dev --dart-define=API_BASE_URL=http://10.0.2.2:8000 --dart-define=DEV_AUTH_ENABLED=true
pause


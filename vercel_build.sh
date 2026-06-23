#!/bin/bash

# Flutter가 없으면 다운로드
if cd flutter; then 
  git pull 
  cd ..
else 
  git clone https://github.com/flutter/flutter.git -b stable
fi

# Flutter 환경변수 등록 및 빌드
export PATH="$PATH:`pwd`/flutter/bin"

flutter doctor
flutter config --enable-web
flutter pub get
flutter build web --release

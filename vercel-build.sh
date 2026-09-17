#!/bin/bash

# 1. Install Flutter
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable
fi

# 2. Add Flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# 3. Enable Web
flutter config --enable-web

# 4. Get Packages
flutter pub get

# 5. Build Web using HTML renderer for better compatibility
flutter build web --release --web-renderer html

# 6. Vercel expects output in 'public' or root usually,
# but we will tell it to look at build/web in vercel.json

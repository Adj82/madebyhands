#!/bin/bash

# 1. Download Flutter
git clone https://github.com/flutter/flutter.git -b stable --depth 1

# 2. Add to PATH (PREPEND to ensure we use this version)
export PATH="`pwd`/flutter/bin:$PATH"

# 3. Build for Web
flutter config --enable-web
flutter pub get
flutter build web --release

# 4. Move build to a folder Vercel can see easily if needed
# (Optional, but helps if you set output directory to 'build/web')

여기에 앱 아이콘 이미지를 넣으세요.

필요한 파일: icon-1024.png  (정확히 1024 x 1024 px, PNG, 투명도 없음)

iOS 앱 아이콘은 알파(투명) 채널이 있으면 안 됩니다. 흰 배경으로 채워주세요.
한 장(1024)만 넣으면 Xcode가 나머지 크기를 자동 생성합니다.

Mac에서 만드는 법 (도들 로고 원본을 logo.png 로 저장했다고 가정):
  # 1024 정사각형 + 흰 배경 합성 (ImageMagick)
  magick logo.png -resize 1024x1024 -background white -gravity center \
    -extent 1024x1024 -alpha remove -alpha off \
    App/Assets.xcassets/AppIcon.appiconset/icon-1024.png

ImageMagick이 없으면: brew install imagemagick
또는 macOS '미리보기'에서 1024x1024로 맞춰 PNG로 내보내기.

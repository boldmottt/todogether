# Mac에서 앱 실행하기

이 프로젝트는 `.xcodeproj` 파일을 git에 넣지 않고, **XcodeGen**으로 `project.yml`에서
생성합니다. (팀원 간 충돌 방지 + 설정을 텍스트로 관리)

## 1. 최초 1회: XcodeGen 설치

```bash
brew install xcodegen
```

## 2. Xcode 프로젝트 생성

```bash
cd ~/todogether
xcodegen generate
```

→ `Todogether.xcodeproj` 가 생성됩니다.

## 3. 열고 실행

```bash
open Todogether.xcodeproj
```

- 상단에서 시뮬레이터(예: `iPhone 16`) 선택
- `⌘ + R` 로 빌드 & 실행

## 빌드 에러가 나면

Linux 환경에서 작성된 코드라 첫 빌드에서 컴파일 에러가 있을 수 있습니다.
에러 메시지를 그대로 복사해서 알려주시면 고쳐드립니다.

## 실기기에서 돌리려면 (선택)

1. Xcode → 프로젝트 → `Todogether` 타겟 → **Signing & Capabilities**
2. **Team** 에 본인 Apple ID 선택 (무료 계정도 개인 기기 설치 가능)
3. `PRODUCT_BUNDLE_IDENTIFIER` 충돌 시 `com.todogether.app` 을 본인 것으로 변경
4. iPhone 연결 후 `⌘ + R`

## 아직 빠진 것 (개발자 계정 필요 → 나중에)

이번 첫 빌드 구성에서는 **UI 확인 우선**으로 아래는 제외했습니다.

| 기능 | 추가로 필요한 것 |
|------|------------------|
| 위젯(WidgetKit) | Widget Extension 타겟 + App Group entitlement |
| Apple 로그인 | Sign in with Apple capability (유료 개발자 계정) |
| CloudKit 공유방 | iCloud 컨테이너 + CloudKit capability |

앱 자체는 위 없이도 빌드·실행되어 화면/로직을 확인할 수 있습니다.
(Apple 로그인 버튼은 보이지만 capability 없이는 실제 인증이 동작하지 않습니다.)

import SwiftUI

// MARK: - 손글씨 메모장 디자인 시스템
// 크림색 종이 위에 잉크로 쓴 것처럼 보이는 테마
public enum SketchTheme {

    // MARK: - Colors
    public enum Color {
        /// 메인 배경 — 크림색 종이
        public static let paper       = SwiftUI.Color(hex: "#FEFAE0")
        /// 카드/셀 배경 — 약간 더 밝은 종이
        public static let card        = SwiftUI.Color(hex: "#FFFDF5")
        /// 기본 텍스트 — 따뜻한 다크 브라운 (순수 검정 X)
        public static let ink         = SwiftUI.Color(hex: "#2D2A22")
        /// 보조 텍스트 — 연한 갈색
        public static let softInk     = SwiftUI.Color(hex: "#8C7B6B")
        /// 줄 / 구분선 — 노트 줄처럼
        public static let ruleLine    = SwiftUI.Color(hex: "#C4B8A0")
        /// 강조색 — 테라코타 (따뜻한 붉은 오렌지)
        public static let accent      = SwiftUI.Color(hex: "#E07A5F")
        /// 완료 — 세이지 그린
        public static let sage        = SwiftUI.Color(hex: "#81B29A")
        /// 잠김 — 연한 모래색
        public static let sand        = SwiftUI.Color(hex: "#C4A882")
        /// 하이라이트 — 연한 노란색 (형광펜)
        public static let highlight   = SwiftUI.Color(hex: "#FFE87C").opacity(0.55)
        /// 위험/삭제
        public static let warm_red    = SwiftUI.Color(hex: "#C0392B")
    }

    // MARK: - Fonts
    // iOS 내장 손글씨 폰트: "Noteworthy", "Chalkboard SE", "Bradley Hand"
    // 커스텀 폰트를 번들하려면 Info.plist에 UIAppFonts 추가 후 아래 fontName 변경
    public static let fontName = "Noteworthy"
    public static let fontNameBold = "Noteworthy-Bold"

    public static func font(_ size: CGFloat, bold: Bool = false) -> SwiftUI.Font {
        let name = bold ? fontNameBold : fontName
        return .custom(name, size: size)
    }

    // 의미적 타이포그래피
    public static var title:    SwiftUI.Font { font(20, bold: true) }
    public static var headline: SwiftUI.Font { font(16, bold: true) }
    public static var body:     SwiftUI.Font { font(15) }
    public static var caption:  SwiftUI.Font { font(12) }
    public static var nano:     SwiftUI.Font { font(10) }
}

// MARK: - ViewModifiers

/// 종이 배경 + 살짝 기울어진 그림자 (포스트잇 느낌)
public struct SketchCard: ViewModifier {
    var angle: Double
    public init(tilt: Double = 0) { self.angle = tilt }

    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(SketchTheme.Color.card)
                    .shadow(color: SketchTheme.Color.ink.opacity(0.10), radius: 3, x: 1, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(SketchTheme.Color.ruleLine, lineWidth: 1.2)
                    )
            )
            .rotationEffect(.degrees(angle))
    }
}

/// 가로 줄노트 배경 (종이 위에 그어진 줄처럼)
public struct RuledBackground: View {
    var lineSpacing: CGFloat = 36

    public init(lineSpacing: CGFloat = 36) { self.lineSpacing = lineSpacing }

    public var body: some View {
        GeometryReader { geo in
            SketchTheme.Color.paper.ignoresSafeArea()
            Canvas { ctx, size in
                let n = Int(size.height / lineSpacing) + 2
                for i in 0..<n {
                    let y = CGFloat(i) * lineSpacing + 12
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    ctx.stroke(path,
                               with: .color(SketchTheme.Color.ruleLine.opacity(0.45)),
                               lineWidth: 0.8)
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - 손글씨 체크박스 (ToggleStyle)
public struct SketchCheckboxStyle: ToggleStyle {
    var completed: Bool
    var locked: Bool

    public init(completed: Bool = false, locked: Bool = false) {
        self.completed = completed
        self.locked = locked
    }

    public func makeBody(configuration: Configuration) -> some View {
        Button {
            if !locked { configuration.isOn.toggle() }
        } label: {
            ZStack {
                // 삐뚤빼뚤한 원 (Canvas)
                Canvas { ctx, size in
                    let r: CGFloat = size.width / 2 - 1
                    let cx = size.width / 2
                    let cy = size.height / 2
                    // 손으로 그린 것처럼 약간 어긋난 원
                    let wobble: [(CGFloat, CGFloat)] = [
                        (-1.2, -0.8), (0.5, -1.0), (1.3, 0.2), (0.8, 1.1),
                        (-0.4, 1.3), (-1.1, 0.6), (-1.3, -0.2)
                    ]
                    var path = Path()
                    for (idx, (dx, dy)) in wobble.enumerated() {
                        let angle = CGFloat(idx) / CGFloat(wobble.count) * 2 * .pi
                        let px = cx + (r + dx) * cos(angle)
                        let py = cy + (r + dy) * sin(angle)
                        if idx == 0 { path.move(to: CGPoint(x: px, y: py)) }
                        else { path.addLine(to: CGPoint(x: px, y: py)) }
                    }
                    path.closeSubpath()

                    let color: SwiftUI.Color = locked ? SketchTheme.Color.sand
                        : completed ? SketchTheme.Color.sage
                        : SketchTheme.Color.softInk
                    ctx.stroke(path, with: .color(color), lineWidth: 1.8)
                    if completed {
                        ctx.fill(path, with: .color(SketchTheme.Color.sage.opacity(0.15)))
                    }
                }
                .frame(width: 24, height: 24)

                if completed {
                    // 손으로 그린 체크
                    Canvas { ctx, size in
                        var path = Path()
                        path.move(to: CGPoint(x: size.width * 0.22, y: size.height * 0.52))
                        path.addLine(to: CGPoint(x: size.width * 0.42, y: size.height * 0.72))
                        path.addLine(to: CGPoint(x: size.width * 0.78, y: size.height * 0.30))
                        ctx.stroke(path, with: .color(SketchTheme.Color.sage),
                                   style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                    }
                    .frame(width: 24, height: 24)
                } else if locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(SketchTheme.Color.sand)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 형광펜 밑줄 효과
public struct HighlightUnderline: ViewModifier {
    public func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            SketchTheme.Color.highlight
                .frame(height: 8)
                .offset(y: 2)
        }
    }
}

// MARK: - View extensions
public extension View {
    func sketchCard(tilt: Double = 0) -> some View {
        modifier(SketchCard(tilt: tilt))
    }
    func highlightUnderline() -> some View {
        modifier(HighlightUnderline())
    }
}

import SwiftUI

// MARK: - 손그림 노트패드 디자인 시스템
// 흰 종이 + 굵고 삐뚤한 검정 잉크 펜 스타일
public enum SketchTheme {

    // MARK: - Colors (거의 흑백, 잉크 온 화이트)
    public enum Color {
        /// 종이 흰색
        public static let paper       = SwiftUI.Color(hex: "#F7F7F5")
        /// 카드/셀
        public static let card        = SwiftUI.Color(hex: "#FFFFFF")
        /// 잉크 블랙 (순수 검정보다 살짝 따뜻하게)
        public static let ink         = SwiftUI.Color(hex: "#1A1A18")
        /// 연한 잉크 (부제목, 힌트)
        public static let softInk     = SwiftUI.Color(hex: "#555550")
        /// 더 연한 잉크 (완료된 항목)
        public static let fadedInk    = SwiftUI.Color(hex: "#AAAAAA")
        /// 줄선
        public static let ruleLine    = SwiftUI.Color(hex: "#CCCCCC")
        /// 강조 — 거의 안 쓰는 진한 포인트 (날짜 초과 등)
        public static let accent      = SwiftUI.Color(hex: "#1A1A18")
        /// 완료 체크 — 잉크와 동일하게
        public static let sage        = SwiftUI.Color(hex: "#1A1A18")
        /// 잠금
        public static let sand        = SwiftUI.Color(hex: "#AAAAAA")
        /// 형광펜 (노란 하이라이트)
        public static let highlight   = SwiftUI.Color(hex: "#FFE066").opacity(0.6)
        /// 위험/삭제
        public static let warm_red    = SwiftUI.Color(hex: "#1A1A18")
    }

    // MARK: - Fonts
    public static let fontName     = "Noteworthy"
    public static let fontNameBold = "Noteworthy-Bold"

    public static func font(_ size: CGFloat, bold: Bool = false) -> SwiftUI.Font {
        .custom(bold ? fontNameBold : fontName, size: size)
    }

    public static var title:    SwiftUI.Font { font(20, bold: true) }
    public static var headline: SwiftUI.Font { font(16, bold: true) }
    public static var body:     SwiftUI.Font { font(15) }
    public static var caption:  SwiftUI.Font { font(12) }
    public static var nano:     SwiftUI.Font { font(10) }
}

// MARK: - 결정적 난수 (LCG)
public struct SeededRNG {
    private var state: UInt64

    public init(seed: Int) {
        state = UInt64(bitPattern: Int64(seed &* 2654435761))
        _ = next(); _ = next()
    }

    public mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double(state >> 33) / Double(1 << 31)
    }

    public mutating func jitter(_ range: Double) -> Double {
        (next() * 2 - 1) * range
    }
}

// MARK: - 행 하단에 잉크 선 하나 (행 높이에 맞춰 글자 아래 정확히 위치)
public struct RuledRowBackground: View {
    var seed: Int
    var paperColor: SwiftUI.Color

    public init(seed: Int = 0, paperColor: SwiftUI.Color = SketchTheme.Color.paper) {
        self.seed = seed
        self.paperColor = paperColor
    }

    public var body: some View {
        paperColor
            .overlay(
                Canvas { ctx, size in
                    var rng = SeededRNG(seed: seed &* 137 &+ 17)
                    let opacity = 0.22 + rng.next() * 0.10
                    let lineWidth = 1.1 + rng.next() * 0.7
                    // 행 하단 바로 위 — 패딩 8pt 여유
                    let y = size.height - 8.0

                    let segW: CGFloat = 22
                    let segs = Int(size.width / segW) + 2
                    var path = Path()
                    for s in 0..<segs {
                        let x0 = CGFloat(s) * segW
                        let x1 = x0 + segW
                        let y0 = y + CGFloat(rng.jitter(1.2))
                        let y1 = y + CGFloat(rng.jitter(1.2))
                        let cy = y + CGFloat(rng.jitter(1.8))
                        if s == 0 { path.move(to: CGPoint(x: x0, y: y0)) }
                        path.addQuadCurve(
                            to: CGPoint(x: x1, y: y1),
                            control: CGPoint(x: (x0 + x1) / 2, y: cy)
                        )
                    }
                    ctx.stroke(path,
                               with: .color(SketchTheme.Color.ink.opacity(opacity)),
                               style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                }
            )
    }
}

// MARK: - 전체 배경용 (비어있는 공간 채우기 — 선 없이 종이색만)
public struct RuledBackground: View {
    public init() {}
    public var body: some View {
        SketchTheme.Color.paper.ignoresSafeArea()
    }
}

// MARK: - 손그림 사각형 체크박스 (네모 스타일)
public struct SketchCheckboxStyle: ToggleStyle {
    var completed: Bool
    var locked: Bool
    var seed: Int

    public init(completed: Bool = false, locked: Bool = false, seed: Int = 0) {
        self.completed = completed
        self.locked = locked
        self.seed = seed
    }

    public func makeBody(configuration: Configuration) -> some View {
        Button {
            if !locked { configuration.isOn.toggle() }
        } label: {
            ZStack {
                WobblySquare(seed: seed, completed: completed, locked: locked)
                    .frame(width: 22, height: 22)

                if completed {
                    CheckmarkShape(seed: seed)
                        .frame(width: 22, height: 22)
                } else if locked {
                    // 잠금: 작은 X 표시
                    Canvas { ctx, size in
                        var p = Path()
                        let m: CGFloat = size.width * 0.28
                        p.move(to:    CGPoint(x: m,           y: m))
                        p.addLine(to: CGPoint(x: size.width-m, y: size.height-m))
                        p.move(to:    CGPoint(x: size.width-m, y: m))
                        p.addLine(to: CGPoint(x: m,            y: size.height-m))
                        ctx.stroke(p, with: .color(SketchTheme.Color.fadedInk),
                                   style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 삐뚤빼뚤한 사각형
private struct WobblySquare: View {
    let seed: Int
    let completed: Bool
    let locked: Bool

    var body: some View {
        Canvas { ctx, size in
            var rng = SeededRNG(seed: seed)
            let inset: CGFloat = 1.5
            let j = { CGFloat(rng.jitter(1.2)) }

            // 4 꼭짓점에 살짝 흔들림
            let tl = CGPoint(x: inset + j(), y: inset + j())
            let tr = CGPoint(x: size.width - inset + j(), y: inset + j())
            let br = CGPoint(x: size.width - inset + j(), y: size.height - inset + j())
            let bl = CGPoint(x: inset + j(), y: size.height - inset + j())

            // 각 변을 중간에 한 번 꺾어서 파형 느낌
            func midWobble(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
                let mx = (a.x + b.x) / 2 + CGFloat(rng.jitter(1.0))
                let my = (a.y + b.y) / 2 + CGFloat(rng.jitter(1.0))
                return CGPoint(x: mx, y: my)
            }

            var path = Path()
            path.move(to: tl)
            path.addLine(to: midWobble(tl, tr))
            path.addLine(to: tr)
            path.addLine(to: midWobble(tr, br))
            path.addLine(to: br)
            path.addLine(to: midWobble(br, bl))
            path.addLine(to: bl)
            path.addLine(to: midWobble(bl, tl))
            path.closeSubpath()

            let col = locked ? SketchTheme.Color.fadedInk
                : completed ? SketchTheme.Color.ink
                : SketchTheme.Color.ink
            let lw = 1.8 + CGFloat(rng.next() * 0.5)
            ctx.stroke(path, with: .color(col),
                       style: StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round))

            if completed {
                ctx.fill(path, with: .color(SketchTheme.Color.ink.opacity(0.06)))
            }
        }
    }
}

// MARK: - 씨앗별 체크 모양 (4종)
private struct CheckmarkShape: View {
    let seed: Int

    var body: some View {
        Canvas { ctx, size in
            var rng = SeededRNG(seed: seed &+ 9999)
            let style = Int(rng.next() * 4)
            let w = size.width, h = size.height
            let j = { CGFloat(rng.jitter(1.4)) }

            var path = Path()
            switch style {
            case 0:
                path.move(to:    CGPoint(x: w*0.18+j(), y: h*0.52+j()))
                path.addLine(to: CGPoint(x: w*0.42+j(), y: h*0.74+j()))
                path.addLine(to: CGPoint(x: w*0.82+j(), y: h*0.26+j()))
            case 1:
                path.move(to:    CGPoint(x: w*0.16+j(), y: h*0.55+j()))
                path.addLine(to: CGPoint(x: w*0.40+j(), y: h*0.72+j()))
                path.addLine(to: CGPoint(x: w*0.84+j(), y: h*0.24+j()))
            case 2:
                path.move(to:    CGPoint(x: w*0.20+j(), y: h*0.48+j()))
                path.addLine(to: CGPoint(x: w*0.38+j(), y: h*0.70+j()))
                path.addLine(to: CGPoint(x: w*0.80+j(), y: h*0.22+j()))
            default:
                path.move(to:    CGPoint(x: w*0.22+j(), y: h*0.50+j()))
                path.addLine(to: CGPoint(x: w*0.42+j(), y: h*0.68+j()))
                path.addLine(to: CGPoint(x: w*0.80+j(), y: h*0.28+j()))
            }

            let lw = 2.2 + CGFloat(rng.next() * 0.4)
            ctx.stroke(path, with: .color(SketchTheme.Color.ink),
                       style: StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round))
        }
    }
}

// MARK: - 손그림 카드 테두리 (굵은 사각형)
public struct SketchCard: ViewModifier {
    var angle: Double
    var seed: Int

    public init(tilt: Double = 0, seed: Int = 0) {
        self.angle = tilt
        self.seed = seed
    }

    public func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(SketchTheme.Color.card)
                    WobblyCardBorder(seed: seed)
                }
            )
            .rotationEffect(.degrees(angle))
    }
}

private struct WobblyCardBorder: View {
    let seed: Int

    var body: some View {
        Canvas { ctx, size in
            var rng = SeededRNG(seed: seed &+ 42)
            let inset: CGFloat = 1.0
            let j = { CGFloat(rng.jitter(1.0)) }

            let tl = CGPoint(x: inset+j(), y: inset+j())
            let tr = CGPoint(x: size.width-inset+j(), y: inset+j())
            let br = CGPoint(x: size.width-inset+j(), y: size.height-inset+j())
            let bl = CGPoint(x: inset+j(), y: size.height-inset+j())

            var path = Path()
            path.move(to: tl)
            // 각 변 4개의 분절점으로 파형
            for (a, b) in [(tl,tr),(tr,br),(br,bl),(bl,tl)] {
                let t1 = CGPoint(x: a.x+(b.x-a.x)*0.33+CGFloat(rng.jitter(0.8)),
                                 y: a.y+(b.y-a.y)*0.33+CGFloat(rng.jitter(0.8)))
                let t2 = CGPoint(x: a.x+(b.x-a.x)*0.67+CGFloat(rng.jitter(0.8)),
                                 y: a.y+(b.y-a.y)*0.67+CGFloat(rng.jitter(0.8)))
                path.addLine(to: t1)
                path.addLine(to: t2)
                path.addLine(to: b)
            }
            path.closeSubpath()

            let lw = 1.6 + CGFloat(rng.next() * 0.5)
            ctx.stroke(path, with: .color(SketchTheme.Color.ink.opacity(0.75)),
                       style: StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round))
        }
    }
}

// MARK: - 형광펜 밑줄
public struct HighlightUnderline: ViewModifier {
    public func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            SketchTheme.Color.highlight
                .frame(height: 8)
                .offset(y: 2)
        }
    }
}

// MARK: - 전역 폰트 환경 주입
// .font(.body), .font(.headline) 등 시스템 스케일도 Noteworthy로 통일
public struct SketchFontEnvironment: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .environment(\.font, SketchTheme.body)
    }
}

// MARK: - View extensions
public extension View {
    func sketchCard(tilt: Double = 0, seed: Int = 0) -> some View {
        modifier(SketchCard(tilt: tilt, seed: seed))
    }
    func highlightUnderline() -> some View {
        modifier(HighlightUnderline())
    }
    /// 앱 루트에 한 번 적용 — 모든 .font(.body/.caption 등)을 Noteworthy로 교체
    func sketchFontEnvironment() -> some View {
        modifier(SketchFontEnvironment())
    }
}

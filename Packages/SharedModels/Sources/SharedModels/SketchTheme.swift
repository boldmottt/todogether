import SwiftUI

// MARK: - 손글씨 메모장 디자인 시스템
public enum SketchTheme {

    // MARK: - Colors
    public enum Color {
        public static let paper       = SwiftUI.Color(hex: "#FEFAE0")
        public static let card        = SwiftUI.Color(hex: "#FFFDF5")
        public static let ink         = SwiftUI.Color(hex: "#2D2A22")
        public static let softInk     = SwiftUI.Color(hex: "#8C7B6B")
        public static let ruleLine    = SwiftUI.Color(hex: "#C4B8A0")
        public static let accent      = SwiftUI.Color(hex: "#E07A5F")
        public static let sage        = SwiftUI.Color(hex: "#81B29A")
        public static let sand        = SwiftUI.Color(hex: "#C4A882")
        public static let highlight   = SwiftUI.Color(hex: "#FFE87C").opacity(0.55)
        public static let warm_red    = SwiftUI.Color(hex: "#C0392B")
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

// MARK: - 결정적 난수 (LCG) — 씨앗이 같으면 항상 같은 수열 반환
public struct SeededRNG {
    private var state: UInt64

    public init(seed: Int) {
        state = UInt64(bitPattern: Int64(seed &* 2654435761))
        // warm-up
        _ = next(); _ = next()
    }

    public mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double(state >> 33) / Double(1 << 31)   // [0, 1)
    }

    /// [-range, +range]
    public mutating func jitter(_ range: Double) -> Double {
        (next() * 2 - 1) * range
    }
}

// MARK: - 손으로 그린 줄노트 배경
public struct RuledBackground: View {
    var lineSpacing: CGFloat

    public init(lineSpacing: CGFloat = 36) { self.lineSpacing = lineSpacing }

    public var body: some View {
        GeometryReader { geo in
            SketchTheme.Color.paper.ignoresSafeArea()
            Canvas { ctx, size in
                let count = Int(size.height / lineSpacing) + 2
                for i in 0..<count {
                    let baseY = CGFloat(i) * lineSpacing + 14
                    var rng = SeededRNG(seed: i &* 137 &+ 17)

                    // 잉크 압력 변화 → 선마다 미세하게 다른 두께·불투명도
                    let opacity = 0.28 + rng.next() * 0.18
                    let lineWidth = 0.6 + rng.next() * 0.5

                    // 선을 짧은 세그먼트로 나눠 각각 살짝 흔들기
                    let segmentWidth: CGFloat = 18
                    let segments = Int(size.width / segmentWidth) + 2
                    var path = Path()

                    for s in 0..<segments {
                        let x0 = CGFloat(s) * segmentWidth
                        let x1 = x0 + segmentWidth
                        // 각 세그먼트 끝점에 미세한 Y 편차
                        let y0 = baseY + CGFloat(rng.jitter(0.9))
                        let y1 = baseY + CGFloat(rng.jitter(0.9))
                        // 제어점 — 살짝 굽어진 곡선
                        let cy = baseY + CGFloat(rng.jitter(1.4))

                        if s == 0 {
                            path.move(to: CGPoint(x: x0, y: y0))
                        }
                        path.addQuadCurve(
                            to: CGPoint(x: x1, y: y1),
                            control: CGPoint(x: (x0 + x1) / 2, y: cy)
                        )
                    }

                    ctx.stroke(
                        path,
                        with: .color(SketchTheme.Color.ruleLine.opacity(opacity)),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - 손으로 그린 체크박스 (씨앗 기반 변형)
public struct SketchCheckboxStyle: ToggleStyle {
    var completed: Bool
    var locked: Bool
    var seed: Int   // todo.id.hashValue → 항상 같은 모양

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
                WobblyCircle(seed: seed, completed: completed, locked: locked)
                    .frame(width: 24, height: 24)

                if completed {
                    CheckmarkShape(seed: seed)
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

// MARK: - 씨앗으로 변형된 삐뚤빼뚤한 원
private struct WobblyCircle: View {
    let seed: Int
    let completed: Bool
    let locked: Bool

    var body: some View {
        Canvas { ctx, size in
            var rng = SeededRNG(seed: seed)
            let cx = size.width / 2
            let cy = size.height / 2
            let r: CGFloat = size.width / 2 - 1.5

            // 씨앗에 따라 꼭짓점 수(7~10)와 흔들림 크기가 달라짐
            let points = 7 + Int(rng.next() * 4)
            let wobbleMag = 0.8 + rng.next() * 1.0

            var path = Path()
            for idx in 0..<points {
                let angle = CGFloat(idx) / CGFloat(points) * 2 * .pi
                let dx = CGFloat(rng.jitter(wobbleMag))
                let dy = CGFloat(rng.jitter(wobbleMag))
                let px = cx + (r + dx) * cos(angle)
                let py = cy + (r + dy) * sin(angle)
                if idx == 0 { path.move(to: CGPoint(x: px, y: py)) }
                else { path.addLine(to: CGPoint(x: px, y: py)) }
            }
            path.closeSubpath()

            let strokeColor: SwiftUI.Color = locked ? SketchTheme.Color.sand
                : completed ? SketchTheme.Color.sage
                : SketchTheme.Color.softInk

            // 잉크 두께도 씨앗마다 미세하게 다름
            let lw = 1.6 + CGFloat(rng.next() * 0.6)
            ctx.stroke(path, with: .color(strokeColor),
                       style: StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round))
            if completed {
                ctx.fill(path, with: .color(SketchTheme.Color.sage.opacity(0.14)))
            }
        }
    }
}

// MARK: - 씨앗으로 변형된 체크 모양 (4가지 스타일)
private struct CheckmarkShape: View {
    let seed: Int

    var body: some View {
        Canvas { ctx, size in
            var rng = SeededRNG(seed: seed &+ 9999)
            let style = Int(rng.next() * 4)  // 0~3 → 4가지 체크 스타일

            let w = size.width
            let h = size.height
            let j = { CGFloat(rng.jitter(1.6)) }

            var path = Path()
            switch style {
            case 0:
                // 클래식 체크 ✓ (살짝 흔들림)
                path.move(to:    CGPoint(x: w*0.20 + j(), y: h*0.52 + j()))
                path.addLine(to: CGPoint(x: w*0.42 + j(), y: h*0.73 + j()))
                path.addLine(to: CGPoint(x: w*0.80 + j(), y: h*0.28 + j()))
            case 1:
                // 짧고 통통한 체크 — 중간점 살짝 올라감
                path.move(to:    CGPoint(x: w*0.18 + j(), y: h*0.55 + j()))
                path.addLine(to: CGPoint(x: w*0.40 + j(), y: h*0.70 + j()))
                path.addLine(to: CGPoint(x: w*0.82 + j(), y: h*0.25 + j()))
            case 2:
                // 넓게 퍼진 체크 — 꼬리가 길다
                path.move(to:    CGPoint(x: w*0.15 + j(), y: h*0.48 + j()))
                path.addLine(to: CGPoint(x: w*0.38 + j(), y: h*0.72 + j()))
                path.addLine(to: CGPoint(x: w*0.85 + j(), y: h*0.22 + j()))
            default:
                // 꺾인 각도가 예리한 체크
                path.move(to:    CGPoint(x: w*0.22 + j(), y: h*0.50 + j()))
                path.addLine(to: CGPoint(x: w*0.40 + j(), y: h*0.68 + j()))
                path.addLine(to: CGPoint(x: w*0.78 + j(), y: h*0.30 + j()))
            }

            let lw = 2.0 + CGFloat(rng.next() * 0.5)
            ctx.stroke(path, with: .color(SketchTheme.Color.sage),
                       style: StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round))
        }
    }
}

// MARK: - 손으로 그린 테두리 카드
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
                    RoundedRectangle(cornerRadius: 12)
                        .fill(SketchTheme.Color.card)
                        .shadow(color: SketchTheme.Color.ink.opacity(0.09), radius: 3, x: 1, y: 2)
                    WobblyBorder(seed: seed)
                }
            )
            .rotationEffect(.degrees(angle))
    }
}

// MARK: - 손으로 그린 카드 테두리
private struct WobblyBorder: View {
    let seed: Int

    var body: some View {
        Canvas { ctx, size in
            var rng = SeededRNG(seed: seed &+ 42)
            let cr: CGFloat = 12
            let inset: CGFloat = 1
            let pts = buildRoundedRectPoints(size: size, cornerRadius: cr, inset: inset, segments: 40)

            var path = Path()
            for (i, pt) in pts.enumerated() {
                let dx = CGFloat(rng.jitter(0.7))
                let dy = CGFloat(rng.jitter(0.7))
                let wpt = CGPoint(x: pt.x + dx, y: pt.y + dy)
                if i == 0 { path.move(to: wpt) } else { path.addLine(to: wpt) }
            }
            path.closeSubpath()

            let opacity = 0.55 + rng.next() * 0.2
            let lw = 1.0 + CGFloat(rng.next() * 0.4)
            ctx.stroke(path, with: .color(SketchTheme.Color.ruleLine.opacity(opacity)),
                       style: StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round))
        }
    }

    // 둥근 사각형의 둘레 위 점들을 균등 간격으로 반환
    private func buildRoundedRectPoints(size: CGSize, cornerRadius cr: CGFloat, inset: CGFloat, segments: Int) -> [CGPoint] {
        let rect = CGRect(x: inset, y: inset, width: size.width - inset*2, height: size.height - inset*2)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cr)
        let cgPath = path.cgPath
        // CGPath를 균등 점으로 분해
        var points: [CGPoint] = []
        let step = 1.0 / Double(segments)
        for i in 0..<segments {
            let t = CGFloat(Double(i) * step)
            // 근사: 둘레를 따라 t 비율 위치
            points.append(pointOnPath(cgPath, t: t, perimeter: cgPath.boundingBox.perimeter))
        }
        return points
    }

    private func pointOnPath(_ path: CGPath, t: CGFloat, perimeter: CGFloat) -> CGPoint {
        // 단순 근사: 경계 박스의 모서리 기반 위치 (실제 곡선 보간 생략 — 충분히 자연스러움)
        let box = path.boundingBox
        let total = 2 * (box.width + box.height)
        var dist = t * total
        if dist < box.width { return CGPoint(x: box.minX + dist, y: box.minY) }
        dist -= box.width
        if dist < box.height { return CGPoint(x: box.maxX, y: box.minY + dist) }
        dist -= box.height
        if dist < box.width { return CGPoint(x: box.maxX - dist, y: box.maxY) }
        dist -= box.width
        return CGPoint(x: box.minX, y: box.maxY - dist)
    }
}

private extension CGRect {
    var perimeter: CGFloat { 2 * (width + height) }
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

// MARK: - View extensions
public extension View {
    func sketchCard(tilt: Double = 0, seed: Int = 0) -> some View {
        modifier(SketchCard(tilt: tilt, seed: seed))
    }
    func highlightUnderline() -> some View {
        modifier(HighlightUnderline())
    }
}

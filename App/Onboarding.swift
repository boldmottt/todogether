import SwiftUI

// MARK: - 온보딩 (I1) — 3단계
struct OnboardingView: View {
    let onFinish: () -> Void
    @State private var page = 0

    private let pages: [OnboardingPage] = [
        .init(symbol: "checklist", title: "할 일을 함께",
              body: "오늘 할 일을 적고, 위젯에서 바로 체크하세요."),
        .init(symbol: "person.2.fill", title: "공유방으로 같이",
              body: "가족·친구와 공유방을 만들어 할 일을 나눠요. 누가 끝냈는지 바로 알 수 있어요."),
        .init(symbol: "link", title: "순서대로 이어서",
              body: "‘재료 사기 → 요리’처럼 앞 일이 끝나면 다음 일이 켜져요.")
    ]

    var body: some View {
        VStack {
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { idx, p in
                    VStack(spacing: 20) {
                        Image(systemName: p.symbol)
                            .font(.system(size: 64))
                            .foregroundStyle(.tint)
                        Text(p.title).font(.title.bold())
                        Text(p.body)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .tag(idx)
                }
            }
            .tabViewStyle(.page)

            Button(page == pages.count - 1 ? "시작하기" : "다음") {
                if page == pages.count - 1 { onFinish() }
                else { withAnimation { page += 1 } }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.bottom, 32)

            if page < pages.count - 1 {
                Button("건너뛰기", action: onFinish)
                    .padding(.bottom, 8)
            }
        }
    }
}

private struct OnboardingPage {
    let symbol: String
    let title: String
    let body: String
}

#Preview { OnboardingView(onFinish: {}) }

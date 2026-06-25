import Testing
@testable import TemplateFeature
import SharedModels

@Suite("TemplateInstantiator")
struct TemplateInstantiatorTests {
    @Test func templateHasCorrectItemCount() {
        let items = [TemplateItem(title: "A"), TemplateItem(title: "B"), TemplateItem(title: "C")]
        let template = TodoTemplate(name: "테스트", items: items)
        #expect(template.items.count == 3)
    }

    @Test func templateItemTitlesPreserved() {
        let items = [TemplateItem(title: "장보기"), TemplateItem(title: "요리")]
        let template = TodoTemplate(name: "저녁 루틴", items: items)
        #expect(template.items.map(\.title) == ["장보기", "요리"])
    }
}

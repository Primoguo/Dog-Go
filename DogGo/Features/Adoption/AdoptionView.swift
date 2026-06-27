import SwiftData
import SwiftUI
import UIKit

struct AdoptionView: View {
    @Environment(\.modelContext) private var modelContext
    @FocusState private var isNameFocused: Bool

    @State private var name = "栗子"
    @State private var errorMessage: String?
    @State private var isSaving = false

    var body: some View {
        ZStack {
            DogGoTheme.Colors.canvas.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Spacer()
                        Image(systemName: "dog.fill")
                            .font(.system(size: 76, weight: .light))
                            .foregroundStyle(DogGoTheme.Colors.ochre)
                            .frame(width: 168, height: 168)
                            .background(DogGoTheme.Colors.ochre.opacity(0.10))
                            .clipShape(Circle())
                            .accessibilityLabel("一只好奇又爱整洁的柴犬")
                        Spacer()
                    }
                    .padding(.top, 30)

                    Text("认识一下")
                        .font(DogGoTheme.Typography.caption)
                        .foregroundStyle(DogGoTheme.Colors.olive)
                        .padding(.top, DogGoTheme.Spacing.large)

                    Text("好奇，也有自己的秩序")
                        .font(DogGoTheme.Typography.title)
                        .foregroundStyle(DogGoTheme.Colors.ink)
                        .padding(.top, 6)

                    Text("它会花很久观察窗外，也会默默把歪掉的小毯子推回自己喜欢的位置。")
                        .font(DogGoTheme.Typography.body)
                        .foregroundStyle(DogGoTheme.Colors.secondaryInk)
                        .lineSpacing(7)
                        .padding(.top, DogGoTheme.Spacing.small)

                    Text("它叫什么名字？")
                        .font(DogGoTheme.Typography.headline)
                        .foregroundStyle(DogGoTheme.Colors.ink)
                        .padding(.top, 34)

                    TextField("栗子", text: $name)
                        .font(DogGoTheme.Typography.body)
                        .textInputAutocapitalization(.never)
                        .submitLabel(.done)
                        .focused($isNameFocused)
                        .padding(.horizontal, 18)
                        .frame(height: 56)
                        .background(DogGoTheme.Colors.ink.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(DogGoTheme.Colors.ink.opacity(0.12), lineWidth: 1)
                        }
                        .onSubmit { isNameFocused = false }
                        .accessibilityLabel("狗狗的名字")

                    if let errorMessage {
                        Text(errorMessage)
                            .font(DogGoTheme.Typography.caption)
                            .foregroundStyle(.red.opacity(0.75))
                            .padding(.top, 8)
                            .accessibilityLabel("名字提示：\(errorMessage)")
                    }

                    Text("确认后，M0 中不会更换狗狗。你随时可以删除全部本地数据。")
                        .font(DogGoTheme.Typography.caption)
                        .foregroundStyle(DogGoTheme.Colors.secondaryInk)
                        .lineSpacing(4)
                        .padding(.top, DogGoTheme.Spacing.large)

                    Button(action: confirmAdoption) {
                        HStack(spacing: 10) {
                            if isSaving {
                                ProgressView().tint(DogGoTheme.Colors.canvas)
                            }
                            Text("确认领养")
                        }
                        .font(DogGoTheme.Typography.button)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(DogGoTheme.Colors.olive)
                        .foregroundStyle(DogGoTheme.Colors.canvas)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving)
                    .padding(.top, 30)
                    .padding(.bottom, 36)
                    .accessibilityHint("保存领养信息并进入新家")
                }
                .padding(.horizontal, DogGoTheme.Spacing.page)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private func confirmAdoption() {
        isNameFocused = false
        errorMessage = nil
        isSaving = true

        do {
            try AdoptionService().adopt(name: name, in: modelContext)
            UIAccessibility.post(notification: .announcement, argument: "领养成功")
        } catch let error as DogNameValidationError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "暂时没能保存，请再试一次。"
        }

        isSaving = false
    }
}

#Preview {
    AdoptionView()
        .modelContainer(for: [DogProfile.self, DogState.self, Relationship.self], inMemory: true)
}

//
//  TranscriptionSectionView.swift
//  Hex
//

#if canImport(FoundationModels)
import FoundationModels
#endif
import ComposableArchitecture
import HexCore
import SwiftUI

struct TranscriptionSectionView: View {
    @Bindable var store: StoreOf<SettingsFeature>

    var body: some View {
        #if canImport(FoundationModels)
        if #available(macOS 26, *) {
            availableBody
        }
        #endif
    }

    #if canImport(FoundationModels)
    @available(macOS 26, *)
    @ViewBuilder
    private var availableBody: some View {
        switch SystemLanguageModel.default.availability {
        case .available:
            sectionView(disabled: false, caption: nil)
        case .unavailable(.appleIntelligenceNotEnabled):
            sectionView(
                disabled: true,
                caption: "Enable Apple Intelligence in System Settings → Apple Intelligence to use this feature."
            )
        case .unavailable(.modelNotReady):
            sectionView(
                disabled: true,
                caption: "AI model is loading. Try again shortly."
            )
        default:
            EmptyView()
        }
    }

    @available(macOS 26, *)
    private func sectionView(disabled: Bool, caption: String?) -> some View {
        Section {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Toggle("AI Text Cleanup", isOn: $store.hexSettings.aiTextCleanupEnabled)
                        .disabled(disabled)
                    Text(
                        caption ?? "Fixes misheard words and cleans up filler words using on-device AI. Runs after your word remappings."
                    )
                    .settingsCaption()
                }
            } icon: {
                Image(systemName: "sparkles")
            }
        } header: {
            Text("Transcription")
        }
    }
    #endif
}

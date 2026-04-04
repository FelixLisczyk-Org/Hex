//
//  FoundationModelsClient.swift
//  Hex
//

#if canImport(FoundationModels)
import FoundationModels
#endif
import ComposableArchitecture
import Dependencies
import DependenciesMacros
import Foundation
import HexCore

enum FoundationModelsAvailability: Equatable {
    case available
    case notEnabled
    case notEligible
    case notReady
}

@DependencyClient
struct FoundationModelsClient {
    var checkAvailability: @Sendable () -> FoundationModelsAvailability = { .notEligible }
    var cleanup: @Sendable (_ text: String) async -> String = { text in text }
}

extension FoundationModelsClient: DependencyKey {
    static var liveValue: Self {
        #if canImport(FoundationModels)
        if #available(macOS 26, *) {
            return Self(
                checkAvailability: {
                    switch SystemLanguageModel.default.availability {
                    case .available:
                        return .available
                    case .unavailable(.appleIntelligenceNotEnabled):
                        return .notEnabled
                    case .unavailable(.deviceNotEligible):
                        return .notEligible
                    case .unavailable(.modelNotReady):
                        return .notReady
                    case .unavailable:
                        return .notEligible
                    }
                },
                cleanup: { text in
                    let logger = HexLog.transcription
                    do {
                        let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)
                        let session = LanguageModelSession(model: model, instructions: """
                            You are a transcription correction assistant. The user has dictated \
                            text using a voice-to-text tool. Fix words that were clearly misheard \
                            based on the surrounding context. Remove any remaining filler words or \
                            spoken-language artifacts. Preserve the original meaning exactly. Do not \
                            add, rephrase, or expand content. Return only the corrected text with no \
                            explanation.
                            """)
                        let response = try await session.respond(to: text)
                        logger.debug("AI cleanup result: '\(response.content, privacy: .private)'")
                        return response.content
                    } catch {
                        logger.error("AI text cleanup failed, falling back to original: \(error)")
                        return text
                    }
                }
            )
        } else {
            return Self(
                checkAvailability: { .notEligible },
                cleanup: { text in text }
            )
        }
        #else
        return Self(
            checkAvailability: { .notEligible },
            cleanup: { text in text }
        )
        #endif
    }

    static var testValue: Self {
        Self(
            checkAvailability: { .available },
            cleanup: { text in text }
        )
    }
}

extension DependencyValues {
    var foundationModels: FoundationModelsClient {
        get { self[FoundationModelsClient.self] }
        set { self[FoundationModelsClient.self] = newValue }
    }
}

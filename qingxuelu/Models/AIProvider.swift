//
//  AIProvider.swift
//  qingxuelu
//
//  Created by AI Assistant on 2025/1/20.
//

import Foundation

// MARK: - AI模型枚举
enum AIModel: String, CaseIterable, Codable {
    case qwenPlus = "qwen-plus"
    case qwenFlash = "qwen-flash"
    case deepseekChat = "deepseek-chat"
    
    var displayName: String {
        switch self {
        case .qwenPlus:
            return "Qwen Plus"
        case .qwenFlash:
            return "Qwen Flash"
        case .deepseekChat:
            return "DeepSeek Chat"
        }
    }
    
    var description: String {
        switch self {
        case .qwenPlus:
            return "阿里云百炼平台提供的Qwen Plus模型，性能强劲"
        case .qwenFlash:
            return "阿里云百炼平台提供的Qwen Flash模型，响应快速"
        case .deepseekChat:
            return "DeepSeek提供的V3.1-Terminus模型"
        }
    }
    
    var icon: String {
        switch self {
        case .qwenPlus:
            return "cloud.fill"
        case .qwenFlash:
            return "bolt.fill"
        case .deepseekChat:
            return "brain.head.profile"
        }
    }
    
    var color: String {
        switch self {
        case .qwenPlus:
            return "blue"
        case .qwenFlash:
            return "orange"
        case .deepseekChat:
            return "purple"
        }
    }
    
    var provider: String {
        switch self {
        case .qwenPlus, .qwenFlash:
            return "阿里云"
        case .deepseekChat:
            return "DeepSeek"
        }
    }
}

// MARK: - AI服务配置
struct AIServiceConfig {
    let model: AIModel
    let apiKey: String
    let baseURL: String
    let temperature: Double
    let maxTokens: Int
    let topP: Double
    
    static func config(for model: AIModel) -> AIServiceConfig {
        switch model {
        case .qwenPlus:
            return AIServiceConfig(
                model: .qwenPlus,
                apiKey: "sk-f648425ba77d477499c746cb78dc681e",
                baseURL: "https://dashscope.aliyuncs.com/compatible-mode/v1",
                temperature: 0.7,
                maxTokens: 8000,
                topP: 0.8
            )
        case .qwenFlash:
            return AIServiceConfig(
                model: .qwenFlash,
                apiKey: "sk-f648425ba77d477499c746cb78dc681e",
                baseURL: "https://dashscope.aliyuncs.com/compatible-mode/v1",
                temperature: 0.7,
                maxTokens: 8000,
                topP: 0.8
            )
        case .deepseekChat:
            return AIServiceConfig(
                model: .deepseekChat,
                apiKey: "sk-637b8ec80f52459e90128e131417a21b",
                baseURL: "https://api.deepseek.com",
                temperature: 0.7,
                maxTokens: 8000,
                topP: 0.8
            )
        }
    }
}

// MARK: - 用户偏好管理器
class UserPreferencesManager: ObservableObject {
    static let shared = UserPreferencesManager()
    
    @Published var selectedAIModel: AIModel {
        didSet {
            UserDefaults.standard.set(selectedAIModel.rawValue, forKey: "selectedAIModel")
        }
    }
    
    private init() {
        // 从UserDefaults读取保存的偏好设置
        if let savedModel = UserDefaults.standard.string(forKey: "selectedAIModel"),
           let model = AIModel(rawValue: savedModel) {
            self.selectedAIModel = model
        } else {
            // 默认使用Qwen Plus
            self.selectedAIModel = .qwenPlus
        }
    }
    
    func getCurrentAIConfig() -> AIServiceConfig {
        return AIServiceConfig.config(for: selectedAIModel)
    }
}

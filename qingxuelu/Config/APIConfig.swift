//
//  APIConfig.swift
//  qingxuelu
//
//  Created by ZL on 2025/9/5.
//

import Foundation

// MARK: - API配置管理
struct APIConfig {
    // 阿里云百炼API配置
    static let dashScopeAPIKey = "sk-f648425ba77d477499c746cb78dc681e"
    static let baseURL = "https://dashscope.aliyuncs.com/compatible-mode/v1"
    static let model = "qwen-plus"
    static let temperature = 0.7
    static let maxTokens = 8000  // 增加token限制以支持更长的计划生成
    static let topP = 0.8
    
    // API端点
    static let chatCompletionsEndpoint = "\(baseURL)/chat/completions"
    
    // 请求头配置
    static var defaultHeaders: [String: String] {
        return [
            "Authorization": "Bearer \(dashScopeAPIKey)",
            "Content-Type": "application/json"
        ]
    }
}

// MARK: - 环境配置
enum AppEnvironment {
    case development
    case production
    
    static var current: AppEnvironment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }
    
    var apiKey: String {
        switch self {
        case .development:
            return APIConfig.dashScopeAPIKey
        case .production:
            // 在生产环境中，应该从安全的配置文件中读取
            return APIConfig.dashScopeAPIKey
        }
    }
    
    var baseURL: String {
        return APIConfig.baseURL
    }
}

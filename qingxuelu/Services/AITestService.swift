//
//  AITestService.swift
//  qingxuelu
//
//  Created by ZL on 2025/9/5.
//

import Foundation

// MARK: - AI测试服务
class AITestService: ObservableObject {
    static let shared = AITestService()
    
    @Published var isTesting = false
    @Published var testResult: String?
    @Published var testError: String?
    
    private let preferencesManager = UserPreferencesManager.shared
    
    private init() {}
    
    // MARK: - 测试API连接
    func testAPIConnection() async {
        await MainActor.run {
            isTesting = true
            testResult = nil
            testError = nil
        }
        
        do {
            let config = preferencesManager.getCurrentAIConfig()
            let response = try await callTestAPI(config: config)
            await MainActor.run {
                testResult = response
                isTesting = false
            }
        } catch {
            await MainActor.run {
                testError = error.localizedDescription
                isTesting = false
            }
        }
    }
    
    // MARK: - 调用测试API
    private func callTestAPI(config: AIServiceConfig) async throws -> String {
        guard let url = URL(string: "\(config.baseURL)/chat/completions") else {
            throw AIServiceError.invalidURL
        }
        
        let requestBody = OpenAICompatibleRequest(
            model: config.model.rawValue,
            messages: [
                OpenAIMessage(role: "user", content: "请简单介绍一下你自己，用一句话回答即可。")
            ],
            temperature: config.temperature,
            maxTokens: 100,
            topP: config.topP
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        // 设置超时时间
        request.timeoutInterval = 60.0 // 测试API用1分钟超时即可
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.apiError
        }
        
        if httpResponse.statusCode != 200 {
            let _ = String(data: data, encoding: .utf8) ?? "未知错误"
            throw AIServiceError.apiError
        }
        
        let openAIResponse = try JSONDecoder().decode(OpenAICompatibleResponse.self, from: data)
        
        guard let content = openAIResponse.choices.first?.message.content else {
            throw AIServiceError.noContent
        }
        
        return content
    }
}

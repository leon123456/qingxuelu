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
    
    private init() {}
    
    // MARK: - 测试API连接
    func testAPIConnection() async {
        await MainActor.run {
            isTesting = true
            testResult = nil
            testError = nil
        }
        
        do {
            let response = try await callTestAPI()
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
    private func callTestAPI() async throws -> String {
        guard let url = URL(string: APIConfig.chatCompletionsEndpoint) else {
            throw AIServiceError.invalidURL
        }
        
        let requestBody = OpenAICompatibleRequest(
            model: APIConfig.model,
            messages: [
                OpenAIMessage(role: "user", content: "请简单介绍一下你自己，用一句话回答即可。")
            ],
            temperature: APIConfig.temperature,
            maxTokens: 100,
            topP: APIConfig.topP
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // 使用配置的请求头
        for (key, value) in APIConfig.defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.apiError
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "未知错误"
            throw AIServiceError.apiError
        }
        
        let openAIResponse = try JSONDecoder().decode(OpenAICompatibleResponse.self, from: data)
        
        guard let content = openAIResponse.choices.first?.message.content else {
            throw AIServiceError.noContent
        }
        
        return content
    }
}

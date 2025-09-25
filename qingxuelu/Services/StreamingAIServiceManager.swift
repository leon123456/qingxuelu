//
//  StreamingAIServiceManager.swift
//  qingxuelu
//
//  Created by Assistant on 2025-09-24.
//

import Foundation
import Combine

// MARK: - 流式AI响应数据模型
struct StreamingResponse {
    let content: String
    let isComplete: Bool
    let thinkingProcess: String?
}

// MARK: - 流式AI服务管理器
class StreamingAIServiceManager: ObservableObject {
    static let shared = StreamingAIServiceManager()
    
    @Published var isLoading = false
    @Published var currentContent = ""
    @Published var thinkingProcess = ""
    @Published var errorMessage: String?
    @Published var progress: Double = 0.0
    
    private let preferencesManager = UserPreferencesManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - 流式生成学习模板
    func generateLearningTemplateStream(for profile: StudentProfile) -> AsyncThrowingStream<StreamingResponse, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    isLoading = true
                    currentContent = ""
                    thinkingProcess = ""
                    progress = 0.0
                    
                    let prompt = buildStreamingPrompt(for: profile)
                    let config = preferencesManager.getCurrentAIConfig()
                    
                    try await callStreamingAIAPI(prompt: prompt, config: config) { response in
                        Task { @MainActor in
                            self.currentContent = response.content
                            self.thinkingProcess = response.thinkingProcess ?? ""
                            self.progress = response.isComplete ? 1.0 : 0.5
                            
                            continuation.yield(response)
                            
                            if response.isComplete {
                                continuation.finish()
                                self.isLoading = false
                            }
                        }
                    }
                } catch {
                    continuation.finish(throwing: error)
                    await MainActor.run {
                        self.isLoading = false
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
    
    // MARK: - 构建流式提示词
    private func buildStreamingPrompt(for profile: StudentProfile) -> String {
        let subjectScoresText = profile.subjectScores.map { score in
            "\(score.subject.rawValue): \(score.score)分 (\(score.level.rawValue))"
        }.joined(separator: ", ")
        
        return """
        你是一位专业的教育专家，请为以下学生制定一个科学的学习管理模板。
        
        请按以下步骤思考并生成：
        
        1. 首先分析学生情况
        2. 然后制定学习目标
        3. 最后生成具体任务
        
        学生信息：
        - 年级：\(profile.grade.rawValue)
        - 学术水平：\(profile.academicLevel.rawValue)
        - 学科成绩：\(subjectScoresText)
        - 学习目标：\(profile.goals.joined(separator: ", "))
        - 兴趣爱好：\(profile.interests.joined(separator: ", "))
        - 学习风格：\(profile.learningStyle.rawValue)
        - 优势：\(profile.strengths.joined(separator: ", "))
        - 劣势：\(profile.weaknesses.joined(separator: ", "))
        
        请生成一个包含以下结构的JSON模板：
        {
            "goals": [
                {
                    "title": "目标标题",
                    "description": "目标描述",
                    "category": "学科类别",
                    "priority": "高/中/低",
                    "targetDate": "2025-12-31",
                    "goalType": "短期/中期/长期",
                    "milestones": [
                        {
                            "title": "里程碑标题",
                            "description": "里程碑描述",
                            "targetDate": "2025-10-31"
                        }
                    ],
                    "keyResults": [
                        {
                            "title": "关键结果标题",
                            "description": "关键结果描述",
                            "targetValue": 100,
                            "unit": "分"
                        }
                    ]
                }
            ],
            "tasks": [
                {
                    "title": "任务标题",
                    "description": "任务描述",
                    "category": "学科类别",
                    "taskPriority": "高/中/低",
                    "estimatedDuration": 60
                }
            ]
        }
        
        请确保JSON格式正确，并包含具体的、可执行的学习目标和任务。
        """
    }
    
    // MARK: - 流式API调用
    private func callStreamingAIAPI(prompt: String, config: AIServiceConfig, onResponse: @escaping (StreamingResponse) -> Void) async throws {
        guard let url = URL(string: "\(config.baseURL)/chat/completions") else {
            throw AIServiceError.invalidURL
        }
        
        let requestBody = OpenAICompatibleRequest(
            model: config.model.rawValue,
            messages: [
                OpenAIMessage(role: "user", content: prompt)
            ],
            temperature: config.temperature,
            maxTokens: config.maxTokens,
            topP: config.topP,
            stream: true // 启用流式响应
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        request.timeoutInterval = 120.0
        
        // 使用URLSession的流式响应
        let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AIServiceError.apiError
        }
        
        var accumulatedContent = ""
        var thinkingProcess = ""
        
        for try await line in asyncBytes.lines {
            if line.hasPrefix("data: ") {
                let jsonString = String(line.dropFirst(6))
                
                if jsonString.trimmingCharacters(in: .whitespacesAndNewlines) == "[DONE]" {
                    // 流式响应结束
                    onResponse(StreamingResponse(
                        content: accumulatedContent,
                        isComplete: true,
                        thinkingProcess: thinkingProcess
                    ))
                    break
                }
                
                // 解析SSE数据
                if let data = jsonString.data(using: .utf8),
                   let sseResponse = try? JSONDecoder().decode(OpenAIStreamingResponse.self, from: data),
                   let delta = sseResponse.choices.first?.delta {
                    
                    if let content = delta.content {
                        accumulatedContent += content
                        
                        // 检查是否是思考过程
                        if content.contains("分析") || content.contains("思考") || content.contains("制定") {
                            thinkingProcess += content
                        }
                        
                        // 发送部分响应
                        onResponse(StreamingResponse(
                            content: accumulatedContent,
                            isComplete: false,
                            thinkingProcess: thinkingProcess
                        ))
                    }
                }
            }
        }
    }
}

// MARK: - 流式响应数据模型
struct OpenAIStreamingResponse: Codable {
    let choices: [StreamingChoice]
}

struct StreamingChoice: Codable {
    let delta: StreamingDelta
}

struct StreamingDelta: Codable {
    let content: String?
}

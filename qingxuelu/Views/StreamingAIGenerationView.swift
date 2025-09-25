//
//  StreamingAIGenerationView.swift
//  qingxuelu
//
//  Created by Assistant on 2025-09-24.
//

import SwiftUI

// MARK: - 流式AI生成视图
struct StreamingAIGenerationView: View {
    let profile: StudentProfile
    @StateObject private var streamingManager = StreamingAIServiceManager.shared
    @State private var generatedTemplate: LearningTemplate?
    @State private var isComplete = false
    @State private var errorMessage: String?
    
    let onComplete: (LearningTemplate) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if streamingManager.isLoading {
                    // 流式生成状态
                    VStack(spacing: 20) {
                        // 进度指示器
                        VStack(spacing: 12) {
                            ProgressView(value: streamingManager.progress)
                                .progressViewStyle(LinearProgressViewStyle())
                                .frame(height: 8)
                            
                            Text("AI正在分析学生信息...")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("\(Int(streamingManager.progress * 100))% 完成")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // 思考过程显示
                        if !streamingManager.thinkingProcess.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("AI思考过程")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                ScrollView {
                                    Text(streamingManager.thinkingProcess)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .frame(maxHeight: 100)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                        
                        // 当前生成内容预览
                        if !streamingManager.currentContent.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("生成内容预览")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                ScrollView {
                                    Text(streamingManager.currentContent)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .frame(maxHeight: 150)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                        
                        // 动态提示文字
                        VStack(spacing: 8) {
                            Text("请稍候，我们正在为您生成个性化的学习计划")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Text("AI会根据学生信息智能分析并制定最适合的学习方案")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding()
                } else if let error = errorMessage {
                    // 错误状态
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                        
                        Text("AI生成失败")
                            .font(.headline)
                        
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else if isComplete, let template = generatedTemplate {
                    // 完成状态
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                        
                        Text("AI分析完成！")
                            .font(.headline)
                        
                        Text("已成功生成学习计划模板，请点击下一步查看详情。")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    // 初始状态
                    VStack(spacing: 16) {
                        Image(systemName: "hourglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("等待AI分析")
                            .font(.headline)
                        
                        Text("请确保已填写学生信息并点击生成按钮")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .cornerRadius(15)
            .shadow(radius: 5)
            .navigationTitle("AI生成计划")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        onCancel()
                    }
                }
            }
        }
        .onAppear {
            startStreamingGeneration()
        }
    }
    
    // MARK: - 开始流式生成
    private func startStreamingGeneration() {
        Task {
            do {
                for try await response in streamingManager.generateLearningTemplateStream(for: profile) {
                    if response.isComplete {
                        // 解析完整的响应
                        let template = try parseTemplateResponse(response.content, profile: profile)
                        await MainActor.run {
                            self.generatedTemplate = template
                            self.isComplete = true
                            self.onComplete(template)
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - 解析模板响应
    private func parseTemplateResponse(_ response: String, profile: StudentProfile) throws -> LearningTemplate {
        // 清理响应文本，提取JSON部分
        let cleanedResponse = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 尝试修复不完整的JSON
        let fixedResponse = fixIncompleteJSON(cleanedResponse)
        
        guard let data = fixedResponse.data(using: .utf8) else {
            throw AIServiceError.parseError
        }
        
        // 解析JSON
        let template = try JSONDecoder().decode(LearningTemplate.self, from: data)
        return template
    }
    
    // MARK: - 修复不完整的JSON
    private func fixIncompleteJSON(_ jsonString: String) -> String {
        var fixed = jsonString
        
        // 如果JSON不完整，尝试修复
        if !fixed.hasSuffix("}") {
            // 查找最后一个完整的对象
            let lines = fixed.components(separatedBy: "\n")
            var fixedLines: [String] = []
            
            for line in lines {
                if line.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix(",") {
                    // 移除末尾的逗号
                    let fixedLine = String(line.dropLast())
                    fixedLines.append(fixedLine)
                } else {
                    fixedLines.append(line)
                }
            }
            
            fixed = fixedLines.joined(separator: "\n")
            
            // 确保JSON结构完整
            if !fixed.hasSuffix("}") {
                fixed += "\n}"
            }
        }
        
        return fixed
    }
}

// MARK: - 预览
struct StreamingAIGenerationView_Previews: PreviewProvider {
    static var previews: some View {
        StreamingAIGenerationView(
            profile: StudentProfile(
                studentId: UUID(),
                grade: .grade7,
                academicLevel: .average
            ),
            onComplete: { _ in },
            onCancel: { }
        )
    }
}

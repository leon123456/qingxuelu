//
//  TaskCompletionTestView.swift
//  qingxuelu
//
//  Created by AI Assistant on 2025/1/27.
//

import SwiftUI

struct TaskCompletionTestView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var testTask: LearningTask?
    @State private var showingCompletion = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("任务完成流程测试")
                .font(.title)
                .fontWeight(.bold)
            
            if let task = testTask {
                VStack(alignment: .leading, spacing: 12) {
                    Text("测试任务: \(task.title)")
                        .font(.headline)
                    
                    Text("状态: \(task.status.rawValue)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("预估时长: \(Int(task.estimatedDuration/60)) 分钟")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Button("测试任务完成") {
                    showingCompletion = true
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("创建测试任务") {
                    createTestTask()
                }
                .buttonStyle(.borderedProminent)
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingCompletion) {
            if let task = testTask {
                TaskCompletionView(task: task)
            }
        }
    }
    
    private func createTestTask() {
        let task = LearningTask(
            title: "测试英语单词背诵",
            description: "背诵20个新单词，测试任务完成流程",
            category: .english,
            priority: .high,
            estimatedDuration: 30 * 60, // 30分钟
            taskType: .manual
        )
        
        dataManager.addTask(task)
        testTask = task
        
        print("✅ 已创建测试任务: \(task.title)")
    }
}

#Preview {
    TaskCompletionTestView()
        .environmentObject(DataManager())
}

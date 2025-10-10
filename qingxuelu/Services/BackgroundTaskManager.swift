//
//  BackgroundTaskManager.swift
//  qingxuelu
//
//  Created by AI Assistant on 2025/10/5.
//

import Foundation
import UIKit

// MARK: - 后台任务管理器
class BackgroundTaskManager: ObservableObject {
    static let shared = BackgroundTaskManager()
    
    @Published var isBackgroundTaskRunning = false
    @Published var backgroundTaskProgress: String = ""
    
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    private init() {
        registerBackgroundTasks()
    }
    
    // MARK: - 注册后台任务
    private func registerBackgroundTasks() {
        // 使用UIBackgroundTask进行后台任务管理
        // UIBackgroundTask提供约30秒的后台执行时间
        print("🔄 后台任务管理器已初始化")
    }
    
    // MARK: - 开始后台任务
    func startBackgroundTask(name: String = "AI Plan Generation") -> UIBackgroundTaskIdentifier {
        let identifier = UIApplication.shared.beginBackgroundTask(withName: name) { [weak self] in
            // 后台任务即将被系统终止
            self?.endBackgroundTask()
        }
        
        backgroundTaskIdentifier = identifier
        isBackgroundTaskRunning = true
        
        print("🔄 开始后台任务: \(name), ID: \(identifier.rawValue)")
        return identifier
    }
    
    // MARK: - 结束后台任务
    func endBackgroundTask() {
        if backgroundTaskIdentifier != .invalid {
            print("✅ 结束后台任务: \(backgroundTaskIdentifier.rawValue)")
            UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            backgroundTaskIdentifier = .invalid
            isBackgroundTaskRunning = false
        }
    }
    
    
    // MARK: - 执行AI计划生成
    private func performAIPlanGeneration() async {
        // 这里实现具体的AI生成逻辑
        // 可以从DataManager获取待处理的目标
        print("🤖 在后台执行AI计划生成...")
    }
    
    
    // MARK: - 调度后台任务
    func scheduleBackgroundTask(type: BackgroundTaskType = .aiPlanGeneration) {
        // 使用UIBackgroundTask而不是BGTaskScheduler
        // UIBackgroundTask可以在应用进入后台时自动开始
        print("📅 后台任务已准备就绪: \(type)")
    }
}

// MARK: - 后台任务扩展
extension BackgroundTaskManager {
    
    // MARK: - 在后台执行AI计划生成
    func generateAIPlanInBackground(
        for goal: LearningGoal,
        dataManager: DataManager,
        completion: @escaping (Result<LearningPlan, Error>) -> Void
    ) {
        let _ = startBackgroundTask(name: "AI Plan Generation for \(goal.title)")
        
        Task {
            do {
                // 更新进度
                await MainActor.run {
                    backgroundTaskProgress = "正在生成AI学习计划..."
                }
                
                // 执行AI生成
                let plan = try await AIPlanServiceManager.shared.generateLearningPlan(
                    for: goal,
                    dataManager: dataManager
                )
                
                // 更新进度
                await MainActor.run {
                    backgroundTaskProgress = "计划生成完成，正在保存..."
                }
                
                // 保存计划
                await MainActor.run {
                    dataManager.addPlan(plan)
                    backgroundTaskProgress = "✅ 计划已保存"
                }
                
                // 完成任务
                endBackgroundTask()
                completion(.success(plan))
                
            } catch {
                // 处理错误
                await MainActor.run {
                    backgroundTaskProgress = "❌ 生成失败: \(error.localizedDescription)"
                }
                
                endBackgroundTask()
                completion(.failure(error))
            }
        }
    }
    
}

// MARK: - 后台任务类型
enum BackgroundTaskType {
    case aiPlanGeneration
}

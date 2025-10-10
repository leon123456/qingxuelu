//
//  qingxueluApp.swift
//  qingxuelu
//
//  Created by ZL on 2025/9/5.
//

import SwiftUI

@main
struct qingxueluApp: App {
    @StateObject private var dataManager = DataManager()
    
    init() {
        // 初始化后台任务管理器
        _ = BackgroundTaskManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    // 应用进入后台时，调度后台任务
                    BackgroundTaskManager.shared.scheduleBackgroundTask()
                }
        }
    }
}

//
//  MainTabView.swift
//  qingxuelu
//
//  Created by AI Assistant on 2025/1/27.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var dataManager = DataManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Today - 今日任务
            TodayView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("今日")
                }
                .tag(0)
            
            // Plan - 学习计划
            PlanView()
                .tabItem {
                    Image(systemName: "calendar.badge.clock")
                    Text("计划")
                }
                .tag(1)
            
            // Goals - 学习目标
            GoalsView()
                .tabItem {
                    Image(systemName: "target")
                    Text("目标")
                }
                .tag(2)
            
            // Stats - 数据复盘
            StatsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("复盘")
                }
                .tag(3)
            
            // Settings - 设置
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("设置")
                }
                .tag(4)
        }
        .environmentObject(dataManager)
    }
}

#Preview {
    MainTabView()
}

//
//  TodayView.swift
//  qingxuelu
//
//  Created by AI Assistant on 2025/1/27.
//

import SwiftUI

struct TodayView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddTask = false
    
    var body: some View {
        NavigationView {
            TimelineTaskView()
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddTask) {
            AddTaskView()
        }
    }
}

#Preview {
    TodayView()
        .environmentObject(DataManager())
}

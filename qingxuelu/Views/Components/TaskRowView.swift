//
//  TaskRowView.swift
//  qingxuelu
//
//  Created by Assistant on 2025-09-11.
//

import SwiftUI

// MARK: - 简单任务行视图
struct SimpleTaskRowView: View {
    let task: LearningTask
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        HStack {
            Image(systemName: task.category.icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(task.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // 完成状态
            Button(action: {
                toggleTaskCompletion()
            }) {
                Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.status == .completed ? .green : .gray)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func toggleTaskCompletion() {
        var updatedTask = task
        updatedTask.status = task.status == .completed ? .pending : .completed
        updatedTask.completedDate = task.status == .completed ? nil : Date()
        dataManager.updateTask(updatedTask)
    }
}

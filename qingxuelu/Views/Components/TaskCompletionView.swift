//
//  TaskCompletionView.swift
//  qingxuelu
//
//  Created by AI Assistant on 2025/1/27.
//

import SwiftUI

struct TaskCompletionView: View {
    let task: LearningTask
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var actualDurationMinutes: Int = 0
    @State private var notes: String = ""
    @State private var rating: Int = 5
    @State private var startTime: Date = Date().addingTimeInterval(-30 * 60) // 默认30分钟前开始
    @State private var endTime: Date = Date()
    
    private var estimatedDurationMinutes: Int {
        Int(task.estimatedDuration / 60)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 任务信息卡片
                    TaskInfoCard(task: task)
                    
                    // 学习时长设置
                    DurationSection(
                        estimatedMinutes: estimatedDurationMinutes,
                        actualMinutes: $actualDurationMinutes,
                        startTime: $startTime,
                        endTime: $endTime
                    )
                    
                    // 学习质量评分
                    RatingSection(rating: $rating)
                    
                    // 学习笔记
                    NotesSection(notes: $notes)
                    
                    // 完成统计
                    CompletionStatsSection(
                        task: task,
                        actualDuration: TimeInterval(actualDurationMinutes * 60)
                    )
                }
                .padding()
            }
            .navigationTitle("任务完成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        completeTask()
                    }
                    .fontWeight(.semibold)
                    .disabled(actualDurationMinutes <= 0)
                }
            }
        }
        .onAppear {
            // 初始化实际时长
            actualDurationMinutes = estimatedDurationMinutes
        }
    }
    
    private func completeTask() {
        let actualDuration = TimeInterval(actualDurationMinutes * 60)
        let notesText = notes.isEmpty ? nil : notes
        
        dataManager.completeTask(
            task,
            actualDuration: actualDuration,
            notes: notesText,
            rating: rating
        )
        
        dismiss()
    }
}

// MARK: - 任务信息卡片
struct TaskInfoCard: View {
    let task: LearningTask
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: task.category.icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(task.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            
            // 任务标签
            HStack {
                Label(task.category.rawValue, systemImage: "tag")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
                
                Label(task.priority.rawValue, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(8)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 学习时长设置
struct DurationSection: View {
    let estimatedMinutes: Int
    @Binding var actualMinutes: Int
    @Binding var startTime: Date
    @Binding var endTime: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("学习时长")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // 预估时长显示
                HStack {
                    Text("预估时长")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(estimatedMinutes) 分钟")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                // 实际时长设置
                HStack {
                    Text("实际时长")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Stepper(value: $actualMinutes, in: 1...480, step: 5) {
                        Text("\(actualMinutes) 分钟")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                
                // 时间选择器
                VStack(alignment: .leading, spacing: 8) {
                    Text("学习时间")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    DatePicker("开始时间", selection: $startTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                    
                    DatePicker("结束时间", selection: $endTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 学习质量评分
struct RatingSection: View {
    @Binding var rating: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("学习质量评分")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { star in
                    Button(action: {
                        rating = star
                    }) {
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .font(.title2)
                            .foregroundColor(star <= rating ? .yellow : .gray)
                    }
                }
                
                Spacer()
                
                Text(ratingDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var ratingDescription: String {
        switch rating {
        case 1: return "需要改进"
        case 2: return "一般"
        case 3: return "良好"
        case 4: return "很好"
        case 5: return "优秀"
        default: return ""
        }
    }
}

// MARK: - 学习笔记
struct NotesSection: View {
    @Binding var notes: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("学习笔记")
                .font(.headline)
                .fontWeight(.semibold)
            
            TextField("记录学习心得、遇到的问题、收获等...", text: $notes, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 完成统计
struct CompletionStatsSection: View {
    let task: LearningTask
    let actualDuration: TimeInterval
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("完成统计")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                StatRow(
                    title: "学习效率",
                    value: efficiencyText,
                    color: efficiencyColor
                )
                
                StatRow(
                    title: "完成状态",
                    value: "已完成",
                    color: .green
                )
                
                StatRow(
                    title: "学习时长",
                    value: "\(Int(actualDuration/60)) 分钟",
                    color: .blue
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var efficiencyText: String {
        let estimatedMinutes = Int(task.estimatedDuration / 60)
        let actualMinutes = Int(actualDuration / 60)
        
        if actualMinutes <= estimatedMinutes {
            return "提前完成"
        } else {
            let extraMinutes = actualMinutes - estimatedMinutes
            return "超时 \(extraMinutes) 分钟"
        }
    }
    
    private var efficiencyColor: Color {
        let estimatedMinutes = Int(task.estimatedDuration / 60)
        let actualMinutes = Int(actualDuration / 60)
        
        if actualMinutes <= estimatedMinutes {
            return .green
        } else if actualMinutes <= Int(Double(estimatedMinutes) * 1.5) {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - 统计行
struct StatRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

#Preview {
    TaskCompletionView(task: LearningTask(
        title: "英语单词背诵",
        description: "背诵20个新单词",
        category: .english,
        priority: .high,
        estimatedDuration: 30 * 60
    ))
    .environmentObject(DataManager())
}

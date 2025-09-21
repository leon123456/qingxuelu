//
//  SettingsView.swift
//  qingxuelu
//
//  Created by ZL on 2025/9/5.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    @StateObject private var aiTestService = AITestService.shared
    @State private var showingAddStudent = false
    @State private var showingEditStudent = false
    @State private var showingStudentProfile = false
    @State private var selectedStudent: Student?
    
    var body: some View {
        NavigationView {
            List {
                // 学生管理区域
                Section {
                    if dataManager.students.isEmpty {
                        EmptyStudentCard()
                    } else {
                        ForEach(dataManager.students) { student in
                            StudentRowView(student: student) {
                                selectedStudent = student
                                showingEditStudent = true
                            } onProfile: {
                                selectedStudent = student
                                showingStudentProfile = true
                            }
                        }
                    }
                    
                    Button(action: { showingAddStudent = true }) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                                .foregroundColor(.blue)
                            Text("添加学生")
                                .foregroundColor(.blue)
                        }
                    }
                } header: {
                    Text("学生管理")
                }
                
                // AI服务测试区域
                Section {
                    Button(action: {
                        Task {
                            await aiTestService.testAPIConnection()
                        }
                    }) {
                        HStack {
                            if aiTestService.isTesting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.purple)
                            }
                            
                            Text(aiTestService.isTesting ? "测试中..." : "测试AI服务连接")
                                .foregroundColor(.purple)
                        }
                    }
                    .disabled(aiTestService.isTesting)
                    
                    if let result = aiTestService.testResult {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AI响应:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(result)
                                .font(.body)
                                .foregroundColor(Color(.systemGreen))
                        }
                        .padding(.vertical, 4)
                    }
                    
                    if let error = aiTestService.testError {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("错误信息:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(error)
                                .font(.body)
                                .foregroundColor(Color(.systemRed))
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("AI服务")
                } footer: {
                    Text("测试阿里云Qwen Plus API连接状态")
                }
                
                // 回收站区域
                Section {
                    NavigationLink(destination: RecycleBinView()) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(Color(.systemRed))
                            Text("回收站")
                            
                            Spacer()
                            
                            if !dataManager.recycleBin.isEmpty {
                                Text("\(dataManager.recycleBin.count)")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemRed).opacity(0.2))
                                    .foregroundColor(Color(.systemRed))
                                    .cornerRadius(8)
                            }
                        }
                    }
                } header: {
                    Text("回收站")
                } footer: {
                    Text("已删除的目标会保存在回收站中，可以恢复或永久删除")
                }
                
                // 应用设置区域
                Section {
                    NavigationLink(destination: NotificationSettingsView()) {
                        HStack {
                            Image(systemName: "bell")
                                .foregroundColor(Color(.systemOrange))
                            Text("通知设置")
                        }
                    }
                    
                    NavigationLink(destination: DataManagementView()) {
                        HStack {
                            Image(systemName: "externaldrive")
                                .foregroundColor(Color(.systemGreen))
                            Text("数据管理")
                        }
                    }
                    
                    NavigationLink(destination: AboutView()) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("关于应用")
                        }
                    }
                } header: {
                    Text("应用设置")
                }
                
                // 学习统计区域
                if let currentStudent = dataManager.currentStudent {
                    Section {
                        LearningStatsRow(
                            title: "总学习时间",
                            value: formatDuration(dataManager.getTotalStudyTime(for: currentStudent.id)),
                            icon: "clock.fill",
                            color: .blue
                        )
                        
                        LearningStatsRow(
                            title: "学习目标",
                            value: "\(dataManager.getGoalsForStudent(currentStudent.id).count)个",
                            icon: "target",
                            color: .green
                        )
                        
                        LearningStatsRow(
                            title: "完成任务",
                            value: "\(dataManager.getTasksForStudent(currentStudent.id).filter { $0.status == .completed }.count)个",
                            icon: "checkmark.circle.fill",
                            color: .orange
                        )
                    } header: {
                        Text("学习统计")
                    }
                }
            }
            .navigationTitle("设置")
        }
        .sheet(isPresented: $showingAddStudent) {
            AddStudentView()
        }
        .sheet(isPresented: $showingEditStudent) {
            if let student = selectedStudent {
                EditStudentView(student: student)
            }
        }
        .sheet(isPresented: $showingStudentProfile) {
            if let student = selectedStudent {
                StudentProfileView()
            }
        }
    }
}

// MARK: - 空学生卡片
struct EmptyStudentCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.circle")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("还没有学生信息")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("添加学生信息开始管理学习")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 学生行视图
struct StudentRowView: View {
    let student: Student
    let onEdit: () -> Void
    let onProfile: () -> Void
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        HStack {
            // 头像
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(student.name.prefix(1)))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                )
            
            // 学生信息
            VStack(alignment: .leading, spacing: 4) {
                Text(student.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(student.grade)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(student.school)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 当前学生标识
            if dataManager.currentStudent?.id == student.id {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color(.systemGreen))
            }
            
            // 操作按钮
            HStack(spacing: 12) {
                Button(action: onProfile) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple)
                }
                
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
        .onTapGesture {
            dataManager.setCurrentStudent(student)
        }
    }
}

// MARK: - 学习统计行视图
struct LearningStatsRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}

// MARK: - 添加学生视图
struct AddStudentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    @State private var name = ""
    @State private var grade = ""
    @State private var school = ""
    @State private var avatar = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("姓名", text: $name)
                    TextField("年级", text: $grade)
                    TextField("学校", text: $school)
                } header: {
                    Text("基本信息")
                }
                
                Section {
                    TextField("头像URL（可选）", text: $avatar)
                } header: {
                    Text("头像")
                } footer: {
                    Text("可以输入头像图片的URL地址")
                }
            }
            .navigationTitle("添加学生")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveStudent()
                    }
                    .disabled(name.isEmpty || grade.isEmpty || school.isEmpty)
                }
            }
        }
    }
    
    private func saveStudent() {
        let student = Student(
            name: name,
            grade: grade,
            school: school,
            avatar: avatar.isEmpty ? nil : avatar
        )
        dataManager.addStudent(student)
        dismiss()
    }
}

// MARK: - 编辑学生视图
struct EditStudentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    let student: Student
    @State private var name: String
    @State private var grade: String
    @State private var school: String
    @State private var avatar: String
    
    init(student: Student) {
        self.student = student
        self._name = State(initialValue: student.name)
        self._grade = State(initialValue: student.grade)
        self._school = State(initialValue: student.school)
        self._avatar = State(initialValue: student.avatar ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("姓名", text: $name)
                    TextField("年级", text: $grade)
                    TextField("学校", text: $school)
                } header: {
                    Text("基本信息")
                }
                
                Section {
                    TextField("头像URL（可选）", text: $avatar)
                } header: {
                    Text("头像")
                } footer: {
                    Text("可以输入头像图片的URL地址")
                }
            }
            .navigationTitle("编辑学生")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveStudent()
                    }
                    .disabled(name.isEmpty || grade.isEmpty || school.isEmpty)
                }
            }
        }
    }
    
    private func saveStudent() {
        var updatedStudent = student
        updatedStudent.name = name
        updatedStudent.grade = grade
        updatedStudent.school = school
        updatedStudent.avatar = avatar.isEmpty ? nil : avatar
        updatedStudent.updatedAt = Date()
        
        dataManager.updateStudent(updatedStudent)
        dismiss()
    }
}

// MARK: - 通知设置视图
struct NotificationSettingsView: View {
    @State private var enableNotifications = true
    @State private var studyReminders = true
    @State private var goalDeadlines = true
    @State private var dailyReport = false
    
    var body: some View {
        Form {
            Section {
                Toggle("启用通知", isOn: $enableNotifications)
            } header: {
                Text("通知设置")
            } footer: {
                Text("关闭后将不会收到任何学习提醒")
            }
            
            if enableNotifications {
                Section {
                    Toggle("学习提醒", isOn: $studyReminders)
                    Toggle("目标截止提醒", isOn: $goalDeadlines)
                    Toggle("每日学习报告", isOn: $dailyReport)
                } header: {
                    Text("通知类型")
                }
            }
        }
        .navigationTitle("通知设置")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 数据管理视图
struct DataManagementView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingExportAlert = false
    @State private var showingImportAlert = false
    @State private var showingClearAlert = false
    
    var body: some View {
        Form {
            Section {
                Button("导出数据") {
                    showingExportAlert = true
                }
                
                Button("导入数据") {
                    showingImportAlert = true
                }
            } header: {
                Text("数据备份")
            } footer: {
                Text("建议定期备份学习数据，避免数据丢失")
            }
            
            Section {
                Button("清除所有数据") {
                    showingClearAlert = true
                }
                .foregroundColor(Color(.systemRed))
            } header: {
                Text("危险操作")
            } footer: {
                Text("此操作将删除所有学习数据，且无法恢复")
            }
        }
        .navigationTitle("数据管理")
        .navigationBarTitleDisplayMode(.inline)
        .alert("导出数据", isPresented: $showingExportAlert) {
            Button("确定") { }
        } message: {
            Text("数据导出功能正在开发中")
        }
        .alert("导入数据", isPresented: $showingImportAlert) {
            Button("确定") { }
        } message: {
            Text("数据导入功能正在开发中")
        }
        .alert("清除所有数据", isPresented: $showingClearAlert) {
            Button("取消", role: .cancel) { }
            Button("确定", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("确定要删除所有学习数据吗？此操作无法撤销。")
        }
    }
    
    private func clearAllData() {
        dataManager.clearAllData()
    }
}

// MARK: - 关于应用视图
struct AboutView: View {
    var body: some View {
        Form {
            Section {
                HStack {
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text("清学路")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("版本 1.0.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            
            Section {
                Text("清学路是一款专为家长设计的学业管理应用，帮助您科学地管理孩子的学习进度，制定合理的学习目标，跟踪学习任务完成情况。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } header: {
                Text("应用介绍")
            }
            
            Section {
                Text("通过项目管理的科学方法，将学习目标分解为可执行的任务，实时跟踪学习进度，分析学习数据，培养良好的学习习惯。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } header: {
                Text("核心理念")
            }
        }
        .navigationTitle("关于应用")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 辅助函数
private func formatDuration(_ duration: TimeInterval) -> String {
    let hours = Int(duration) / 3600
    let minutes = Int(duration) % 3600 / 60
    
    if hours > 0 {
        return "\(hours)小时\(minutes)分钟"
    } else {
        return "\(minutes)分钟"
    }
}

// MARK: - 回收站视图
struct RecycleBinView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingClearAlert = false
    
    var deletedGoals: [DeletedGoal] {
        dataManager.getRecycleBinGoals()
    }
    
    var body: some View {
        List {
            if deletedGoals.isEmpty {
                EmptyRecycleBinView()
            } else {
                ForEach(deletedGoals) { deletedGoal in
                    DeletedGoalRowView(deletedGoal: deletedGoal)
                }
                
                Section {
                    Button("清空回收站") {
                        showingClearAlert = true
                    }
                    .foregroundColor(Color(.systemRed))
                }
            }
        }
        .navigationTitle("回收站")
        .navigationBarTitleDisplayMode(.large)
        .alert("清空回收站", isPresented: $showingClearAlert) {
            Button("取消", role: .cancel) { }
            Button("清空", role: .destructive) {
                dataManager.clearRecycleBin()
            }
        } message: {
            Text("确定要清空回收站吗？此操作将永久删除所有已删除的目标，且无法恢复。")
        }
    }
}

// MARK: - 空回收站视图
struct EmptyRecycleBinView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "trash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("回收站为空")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text("已删除的目标会显示在这里")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - 已删除目标行视图
struct DeletedGoalRowView: View {
    let deletedGoal: DeletedGoal
    @EnvironmentObject var dataManager: DataManager
    @State private var showingRestoreAlert = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: deletedGoal.goal.category.icon)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(deletedGoal.goal.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(deletedGoal.goal.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatDate(deletedGoal.deletedAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("已删除")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            HStack(spacing: 12) {
                Button(action: { showingRestoreAlert = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.uturn.backward")
                        Text("恢复")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Button(action: { showingDeleteAlert = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                        Text("永久删除")
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 8)
        .alert("恢复目标", isPresented: $showingRestoreAlert) {
            Button("取消", role: .cancel) { }
            Button("恢复") {
                dataManager.restoreGoal(deletedGoal)
            }
        } message: {
            Text("确定要恢复「\(deletedGoal.goal.title)」吗？")
        }
        .alert("永久删除", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                dataManager.permanentlyDeleteGoal(deletedGoal)
            }
        } message: {
            Text("确定要永久删除「\(deletedGoal.goal.title)」吗？此操作无法撤销。")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    SettingsView()
        .environmentObject(DataManager())
}

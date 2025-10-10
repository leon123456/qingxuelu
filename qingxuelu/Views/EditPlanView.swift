//
//  EditPlanView.swift
//  qingxuelu
//
//  Created by AI Assistant on 2025/1/27.
//

import SwiftUI

struct EditPlanView: View {
    let plan: LearningPlan
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var editedTitle: String
    @State private var editedDescription: String
    @State private var editedStartDate: Date
    @State private var editedEndDate: Date
    
    init(plan: LearningPlan) {
        self.plan = plan
        self._editedTitle = State(initialValue: plan.title)
        self._editedDescription = State(initialValue: plan.description)
        self._editedStartDate = State(initialValue: plan.startDate)
        self._editedEndDate = State(initialValue: plan.endDate)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    TextField("计划标题", text: $editedTitle)
                    TextField("计划描述", text: $editedDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("时间设置") {
                    DatePicker("开始日期", selection: $editedStartDate, displayedComponents: .date)
                    DatePicker("结束日期", selection: $editedEndDate, displayedComponents: .date)
                }
                
                Section("计划统计") {
                    HStack {
                        Text("总周数")
                        Spacer()
                        Text("\(plan.totalWeeks) 周")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("总任务数")
                        Spacer()
                        Text("\(getTotalTaskCount()) 个")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("调度状态")
                        Spacer()
                        Text(plan.scheduleStatus.rawValue)
                            .foregroundColor(Color(plan.scheduleStatus.color))
                    }
                }
            }
            .navigationTitle("编辑计划")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        savePlan()
                    }
                }
            }
        }
    }
    
    private func savePlan() {
        var updatedPlan = plan
        updatedPlan.title = editedTitle
        updatedPlan.description = editedDescription
        updatedPlan.startDate = editedStartDate
        updatedPlan.endDate = editedEndDate
        
        dataManager.updatePlan(updatedPlan)
        dismiss()
    }
    
    private func getTotalTaskCount() -> Int {
        return plan.weeklyPlans.reduce(0) { total, weeklyPlan in
            total + weeklyPlan.tasks.count
        }
    }
}

#Preview {
    EditPlanView(plan: LearningPlan(
        id: UUID(),
        title: "英语口语提升计划",
        description: "通过日常练习提升英语口语表达能力",
        startDate: Date(),
        endDate: Date().addingTimeInterval(90 * 24 * 3600),
        totalWeeks: 12
    ))
    .environmentObject(DataManager())
}

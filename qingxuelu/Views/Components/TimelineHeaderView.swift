//
//  TimelineHeaderView.swift
//  qingxuelu
//
//  Created by Assistant on 2025-09-18.
//

import SwiftUI

// MARK: - 时间线头部视图（借鉴Structured设计）
struct TimelineHeaderView: View {
    @Binding var selectedDate: Date
    @State private var showingDatePicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 主日期显示
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatMainDate(selectedDate))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .animation(.easeInOut(duration: 0.3), value: selectedDate)
                    
                    Text(formatWeekday(selectedDate))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .animation(.easeInOut(duration: 0.3), value: selectedDate)
                }
                
                Spacer()
                
                // 日期导航按钮
                HStack(spacing: 16) {
                    Button(action: { navigateToPreviousDay() }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: { navigateToNextDay() }) {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            
            // 周历条
            WeekCalendarStrip(selectedDate: $selectedDate)
                .padding(.horizontal, 20)
                .padding(.top, 16)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - 日期格式化
    private func formatMainDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
    }
    
    private func formatWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    // MARK: - 日期导航
    private func navigateToPreviousDay() {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        }
    }
    
    private func navigateToNextDay() {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        }
    }
}

// MARK: - 周历条组件
struct WeekCalendarStrip: View {
    @Binding var selectedDate: Date
    @State private var weekDates: [Date] = []
    
    var body: some View {
        // 使用 HStack 替代 ScrollView，确保七个日期按钮完整显示
        HStack(spacing: 8) {
            ForEach(weekDates, id: \.self) { date in
                DayButton(
                    date: date,
                    isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                    onTap: { selectedDate = date }
                )
            }
        }
        .padding(.horizontal, 4)
        .onAppear {
            generateWeekDates()
        }
        .onChange(of: selectedDate) { _, _ in
            generateWeekDates()
        }
    }
    
    private func generateWeekDates() {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        
        weekDates = (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
    }
}

// MARK: - 日期按钮
struct DayButton: View {
    let date: Date
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 3) {
                Text(formatWeekday(date))
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white : .secondary)
                
                Text(formatDay(date))
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundColor(isSelected ? .white : .primary)
                
                // 任务指示器
                HStack(spacing: 1.5) {
                    Circle()
                        .fill(Color.blue.opacity(0.6))
                        .frame(width: 3, height: 3)
                    
                    Circle()
                        .fill(Color.pink.opacity(0.6))
                        .frame(width: 3, height: 3)
                }
                .opacity(isSelected ? 0 : 1)
            }
            .frame(width: 44, height: 55)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
    
    private func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

#Preview {
    TimelineHeaderView(selectedDate: .constant(Date()))
}

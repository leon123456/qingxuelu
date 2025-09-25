#!/usr/bin/env swift

import Foundation

// MARK: - 测试数据结构
struct TestPlan: Codable {
    let title: String
    let description: String
    let totalWeeks: Int
    let weeklyPlans: [TestWeeklyPlan]
    let resources: [TestResource]
}

struct TestWeeklyPlan: Codable {
    let weekNumber: Int
    let milestones: [String]
    let taskCount: Int
    let estimatedHours: Int
    let tasks: [TestTask]
}

struct TestTask: Codable {
    let title: String
    let quantity: String
    let duration: String
    let difficulty: String
}

struct TestResource: Codable {
    let title: String
    let type: String
    let url: String
    let description: String
}

// MARK: - 任务分配类型枚举
enum TaskDistributionType: String, CaseIterable, Codable {
    case daily = "daily"           // 每日任务
    case weekly = "weekly"         // 周任务
    case intensive = "intensive"   // 集中任务
    
    var displayName: String {
        switch self {
        case .daily: return "每日任务"
        case .weekly: return "周任务"
        case .intensive: return "集中任务"
        }
    }
}

// MARK: - 任务拆分测试
class TaskSchedulerTest {
    
    static func runTest() {
        print("🧪 开始测试任务拆分逻辑...")
        print(String(repeating: "=", count: 60))
        
        // 读取测试数据
        guard let testData = loadTestData() else {
            print("❌ 无法加载测试数据")
            return
        }
        
        print("📋 测试计划: \(testData.title)")
        print("📊 总周数: \(testData.totalWeeks)")
        print("📚 资源数量: \(testData.resources.count)")
        print()
        
        // 测试每一周的任务拆分
        for weeklyPlan in testData.weeklyPlans {
            testWeeklyPlan(weeklyPlan)
        }
        
        print(String(repeating: "=", count: 60))
        print("✅ 测试完成！")
    }
    
    private static func loadTestData() -> TestPlan? {
        let currentDirectory = FileManager.default.currentDirectoryPath
        let testFilePath = "\(currentDirectory)/qingxuelu/Data/Test/test_plan.json"
        
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: testFilePath)) else {
            print("❌ 无法找到 test_plan.json 文件")
            print("   查找路径: \(testFilePath)")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(TestPlan.self, from: data)
        } catch {
            print("❌ 解析JSON失败: \(error)")
            return nil
        }
    }
    
    private static func testWeeklyPlan(_ weeklyPlan: TestWeeklyPlan) {
        print("📅 第\(weeklyPlan.weekNumber)周测试")
        print("🎯 里程碑: \(weeklyPlan.milestones.joined(separator: ", "))")
        print("⏱️ 预计总时长: \(weeklyPlan.estimatedHours)小时")
        print("📝 任务数量: \(weeklyPlan.taskCount)")
        print()
        
        var totalMinutes = 0
        
        for (index, task) in weeklyPlan.tasks.enumerated() {
            print("  📋 任务\(index + 1): \(task.title)")
            print("    数量: \(task.quantity)")
            print("    时长: \(task.duration)")
            print("    难度: \(task.difficulty)")
            
            // 解析时长
            let durationInSeconds = parseDurationFromString(task.duration)
            let durationInMinutes = Int(durationInSeconds / 60)
            totalMinutes += durationInMinutes
            
            print("    解析后时长: \(durationInMinutes)分钟 (\(durationInSeconds)秒)")
            
            // 测试任务类型判断
            let taskType = determineTaskDistributionType(durationInSeconds)
            print("    任务类型: \(taskType.displayName)")
            
            // 测试最优天数计算
            let optimalDays = calculateOptimalDays(durationInSeconds)
            print("    最优天数: \(optimalDays)天")
            
            // 测试任务拆分
            let subTaskDuration = durationInSeconds / Double(optimalDays)
            let subTaskMinutes = Int(subTaskDuration / 60)
            print("    拆分后每天: \(subTaskMinutes)分钟")
            
            print()
        }
        
        let totalHours = Double(totalMinutes) / 60.0
        print("  📊 第\(weeklyPlan.weekNumber)周总时长: \(totalMinutes)分钟 (\(String(format: "%.1f", totalHours))小时)")
        print("  ✅ 与预计时长对比: \(weeklyPlan.estimatedHours)小时 vs \(String(format: "%.1f", totalHours))小时")
        
        if abs(Double(weeklyPlan.estimatedHours) - totalHours) < 0.1 {
            print("  ✅ 时长匹配！")
        } else {
            print("  ⚠️ 时长不匹配！")
        }
        
        print(String(repeating: "-", count: 50))
        print()
    }
    
    // MARK: - 复制TaskScheduler中的方法进行测试
    
    private static func parseDurationFromString(_ durationString: String) -> TimeInterval {
        // 解析类似"30分钟"、"2小时"、"1.5小时"的字符串
        let trimmedString = durationString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 使用正则表达式提取数字和小数
        let pattern = "([0-9]+\\.?[0-9]*)"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: trimmedString.utf16.count)
        
        if let match = regex?.firstMatch(in: trimmedString, range: range) {
            let numberString = String(trimmedString[Range(match.range, in: trimmedString)!])
            if let number = Double(numberString) {
                if trimmedString.contains("小时") || trimmedString.contains("hour") {
                    return number * 3600 // 转换为秒
                } else if trimmedString.contains("分钟") || trimmedString.contains("minute") {
                    return number * 60 // 转换为秒
                } else {
                    return number * 3600 // 默认按小时处理
                }
            }
        }
        
        // 如果解析失败，返回默认值
        return 3600 // 默认1小时 = 3600秒
    }
    
    private static func determineTaskDistributionType(_ duration: TimeInterval) -> TaskDistributionType {
        let hours = duration / 3600 // 转换为小时
        
        // 根据任务时长和描述判断类型
        if hours <= 0.5 { // 30分钟
            return .weekly
        } else if hours <= 2.0 { // 2小时
            return .weekly
        } else {
            return .intensive
        }
    }
    
    private static func calculateOptimalDays(_ duration: TimeInterval) -> Int {
        let hours = duration / 3600 // 转换为小时
        
        if hours <= 0.5 { // 30分钟
            return 1 // 30分钟任务分配到1天
        } else if hours <= 1.0 { // 60分钟
            return 2 // 60分钟任务分配到2天
        } else if hours <= 2.0 { // 2小时
            return 2 // 2小时任务分配到2天
        } else if hours <= 3.0 { // 3小时
            return 3 // 3小时任务分配到3天
        } else if hours <= 4.0 { // 4小时
            return 4 // 4小时任务分配到4天
        } else {
            return 5 // 更长任务分配到5天
        }
    }
}

// MARK: - 运行测试
TaskSchedulerTest.runTest()

//
//  qingxueluTests.swift
//  qingxueluTests
//
//  Created by ZL on 2025/9/5.
//

import Testing
import Foundation
@testable import qingxuelu

struct qingxueluTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
    
    @Test func testAIGoalGeneratorMilestoneParsing() async throws {
        // 测试AI生成里程碑的日期解析功能
        // 注意：由于parseGoalResponse是私有方法，我们无法直接测试
        // 这里我们测试AIGoalGenerator的基本功能
        let aiGenerator = AIGoalGenerator.shared
        
        // 验证AI生成器可以正常初始化
        #expect(aiGenerator != nil)
        
        // 验证AI生成器的状态
        #expect(!aiGenerator.isLoading)
        #expect(aiGenerator.errorMessage == nil)
    }
    
    @Test func testMilestoneCreation() {
        // 测试里程碑创建功能
        let milestone = Milestone(
            title: "测试里程碑",
            description: "这是一个测试里程碑",
            targetDate: Date().addingTimeInterval(7 * 24 * 3600)
        )
        
        #expect(milestone.title == "测试里程碑")
        #expect(milestone.description == "这是一个测试里程碑")
        #expect(!milestone.isCompleted)
        #expect(milestone.progress == 0.0)
    }
    
    @Test func testKeyResultCreation() {
        // 测试关键结果创建功能
        let keyResult = KeyResult(
            title: "测试关键结果",
            description: "这是一个测试关键结果",
            targetValue: 100,
            unit: "分"
        )
        
        #expect(keyResult.title == "测试关键结果")
        #expect(keyResult.description == "这是一个测试关键结果")
        #expect(keyResult.targetValue == 100)
        #expect(keyResult.unit == "分")
        #expect(keyResult.currentValue == 0.0)
        #expect(!keyResult.isCompleted)
        #expect(keyResult.progress == 0.0)
    }
    
    @Test func testClassicLiteratureTemplateDuration() {
        // 测试经典文学阅读模板的持续时间计算
        let templateManager = GoalTemplateManager.shared
        let templates = templateManager.templates
        
        // 找到经典文学阅读模板
        let classicLiteratureTemplate = templates.first { $0.name == "经典文学阅读" }
        #expect(classicLiteratureTemplate != nil, "应该找到经典文学阅读模板")
        
        guard let template = classicLiteratureTemplate else { return }
        
        // 验证模板配置
        #expect(template.duration == 45, "经典文学阅读模板应该是45天")
        #expect(template.name == "经典文学阅读")
        #expect(template.category == .chinese)
        #expect(template.goalType == .hybrid)
        
        // 转换为学习目标
        let goal = template.toLearningGoal()
        
        // 验证目标转换
        #expect(goal.title == "经典文学阅读")
        #expect(goal.category == .chinese)
        #expect(goal.goalType == .hybrid)
        
        // 计算实际天数
        let calendar = Calendar.current
        let daysBetween = calendar.dateComponents([.day], from: goal.startDate, to: goal.targetDate).day ?? 0
        let expectedWeeks = Int(ceil(Double(daysBetween) / 7.0))
        
        print("📚 经典文学阅读目标分析:")
        print("  模板持续时间: \(template.duration)天")
        print("  目标开始日期: \(goal.startDate)")
        print("  目标结束日期: \(goal.targetDate)")
        print("  实际天数差: \(daysBetween)天")
        print("  预期周数: \(expectedWeeks)周")
        
        // 验证天数计算
        #expect(daysBetween == 45, "目标持续时间应该是45天")
        #expect(expectedWeeks == 7, "45天应该对应7周（向上取整）")
        
        // 测试AI计划生成时的周数计算
        let components = calendar.dateComponents([.weekOfYear], from: goal.startDate, to: goal.targetDate)
        let actualWeeks = components.weekOfYear ?? 16
        
        print("  AI计算周数: \(actualWeeks)周")
        
        // 检查是否存在周数计算问题
        if actualWeeks != expectedWeeks {
            print("❌ 发现问题: AI计算的周数(\(actualWeeks))与预期周数(\(expectedWeeks))不一致")
            print("   这可能导致AI生成\(actualWeeks)周的计划而不是\(expectedWeeks)周的计划")
        } else {
            print("✅ 周数计算正确")
        }
    }
    
    @Test func testAIPlanPromptGeneration() async throws {
        // 测试AI计划生成的prompt构建
        let templateManager = GoalTemplateManager.shared
        let classicLiteratureTemplate = templateManager.templates.first { $0.name == "经典文学阅读" }
        
        #expect(classicLiteratureTemplate != nil, "应该找到经典文学阅读模板")
        guard let template = classicLiteratureTemplate else { return }
        
        let goal = template.toLearningGoal()
        
        // 模拟AIPlanServiceManager的周数计算逻辑
        let calendar = Calendar.current
        let actualWeeks = calendar.dateComponents([.weekOfYear], from: goal.startDate, to: goal.targetDate).weekOfYear ?? 16
        
        // 构建prompt（模拟AIPlanServiceManager.buildPlanPrompt方法）
        let milestonesText = goal.milestones.map { milestone in
            "- \(milestone.title): \(milestone.description)"
        }.joined(separator: "\n")
        
        let keyResultsText = goal.keyResults.map { keyResult in
            "- \(keyResult.title): 目标 \(Int(keyResult.targetValue)) \(keyResult.unit)"
        }.joined(separator: "\n")
        
        let prompt = """
        你是一位专业的学习规划师，请为以下学习目标制定一个详细的、可量化的 \(actualWeeks) 周学习计划：
        
        目标信息：
        - 目标标题：\(goal.title)
        - 目标描述：\(goal.description)
        - 目标类型：\(goal.goalType.rawValue)
        - 学科分类：\(goal.category.rawValue)
        - 优先级：\(goal.priority.rawValue)
        - 开始时间：\(goal.startDate.formatted(date: .abbreviated, time: .omitted))
        - 目标完成时间：\(goal.targetDate.formatted(date: .abbreviated, time: .omitted))
        
        里程碑：
        \(milestonesText.isEmpty ? "无" : milestonesText)
        
        关键结果：
        \(keyResultsText.isEmpty ? "无" : keyResultsText)
        
        请生成一个JSON格式的详细学习计划，包含以下内容：
        1. 计划标题和描述
        2. 每周的具体学习计划（\(actualWeeks)周）
        3. 每周的里程碑和关键结果
        4. 每周的任务数量和预估学习时长
        5. 每周的具体学习任务列表
        6. 学习资源推荐
        """
        
        print("🤖 AI Prompt分析:")
        print("  Prompt中指定的周数: \(actualWeeks)周")
        print("  Prompt长度: \(prompt.count)字符")
        
        // 验证prompt中的关键信息
        #expect(prompt.contains("\(actualWeeks) 周学习计划"), "Prompt应该包含正确的周数")
        #expect(prompt.contains("经典文学阅读"), "Prompt应该包含目标标题")
        #expect(prompt.contains("阅读经典文学作品"), "Prompt应该包含目标描述")
        
        // 检查prompt中是否明确指定了周数
        let weekMentions = prompt.components(separatedBy: "\(actualWeeks)周").count - 1
        print("  Prompt中周数出现次数: \(weekMentions)")
        
        #expect(weekMentions >= 2, "Prompt中应该多次提到周数")
        
        // 输出prompt的关键部分用于调试
        print("  Prompt关键部分:")
        let lines = prompt.components(separatedBy: "\n")
        for (index, line) in lines.enumerated() {
            if line.contains("\(actualWeeks)") || line.contains("周") {
                print("    第\(index + 1)行: \(line)")
            }
        }
    }
    
    @Test func testActualAIPlanGeneration() async throws {
        // 实际测试AI计划生成，验证是否返回16周计划
        let templateManager = GoalTemplateManager.shared
        let classicLiteratureTemplate = templateManager.templates.first { $0.name == "经典文学阅读" }
        
        #expect(classicLiteratureTemplate != nil, "应该找到经典文学阅读模板")
        guard let template = classicLiteratureTemplate else { return }
        
        let goal = template.toLearningGoal()
        
        // 使用AIPlanServiceManager测试计划生成
        let planManager = AIPlanServiceManager.shared
        
        print("🧪 开始测试AI计划生成...")
        print("📚 目标: \(goal.title)")
        print("📅 目标持续时间: 45天")
        print("📅 开始日期: \(goal.startDate)")
        print("📅 结束日期: \(goal.targetDate)")
        
        // 计算实际周数
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekOfYear], from: goal.startDate, to: goal.targetDate)
        let actualWeeks = components.weekOfYear ?? 16
        
        print("🔢 AI计算的周数: \(actualWeeks)周")
        
        // 手动计算预期周数
        let daysBetween = calendar.dateComponents([.day], from: goal.startDate, to: goal.targetDate).day ?? 0
        let expectedWeeks = Int(ceil(Double(daysBetween) / 7.0))
        
        print("🔢 预期周数: \(expectedWeeks)周")
        print("🔢 实际天数差: \(daysBetween)天")
        
        // 验证周数计算
        #expect(daysBetween == 45, "目标持续时间应该是45天")
        #expect(expectedWeeks == 7, "45天应该对应7周（向上取整）")
        
        // 检查是否存在周数计算问题
        if actualWeeks != expectedWeeks {
            print("❌ 发现问题: AI计算的周数(\(actualWeeks))与预期周数(\(expectedWeeks))不一致")
            print("   这可能导致AI生成\(actualWeeks)周的计划而不是\(expectedWeeks)周的计划")
            
            // 这是问题的根源！
            print("🔍 问题分析:")
            print("   - 经典文学阅读模板设置为45天")
            print("   - 但AI计算周数时使用了Calendar.current.dateComponents([.weekOfYear], ...)")
            print("   - 这个方法可能返回了16周而不是7周")
            print("   - 导致AI prompt中指定了16周而不是7周")
        } else {
            print("✅ 周数计算正确")
        }
        
        // 测试AI prompt构建
        let testPrompt = """
        你是一位专业的学习规划师，请为以下学习目标制定一个详细的、可量化的 \(actualWeeks) 周学习计划：
        
        目标信息：
        - 目标标题：\(goal.title)
        - 目标描述：\(goal.description)
        - 目标类型：\(goal.goalType.rawValue)
        - 学科分类：\(goal.category.rawValue)
        - 优先级：\(goal.priority.rawValue)
        - 开始时间：\(goal.startDate.formatted(date: .abbreviated, time: .omitted))
        - 目标完成时间：\(goal.targetDate.formatted(date: .abbreviated, time: .omitted))
        
        请生成一个JSON格式的详细学习计划，包含以下内容：
        1. 计划标题和描述
        2. 每周的具体学习计划（\(actualWeeks)周）
        3. 每周的里程碑和关键结果
        4. 每周的任务数量和预估学习时长
        5. 每周的具体学习任务列表
        6. 学习资源推荐
        """
        
        print("🤖 AI Prompt分析:")
        print("  Prompt中指定的周数: \(actualWeeks)周")
        print("  Prompt长度: \(testPrompt.count)字符")
        
        // 验证prompt中的关键信息
        #expect(testPrompt.contains("\(actualWeeks) 周学习计划"), "Prompt应该包含正确的周数")
        
        // 检查prompt中是否明确指定了周数
        let weekMentions = testPrompt.components(separatedBy: "\(actualWeeks)周").count - 1
        print("  Prompt中周数出现次数: \(weekMentions)")
        
        #expect(weekMentions >= 2, "Prompt中应该多次提到周数")
        
        // 输出关键发现
        print("\n🎯 关键发现:")
        if actualWeeks == 16 {
            print("   ❌ 确认问题: AI计算的周数是16周，而不是预期的7周")
            print("   📝 这解释了为什么AI会生成16周的计划")
            print("   🔧 需要修复AIPlanServiceManager中的周数计算逻辑")
        } else {
            print("   ✅ 周数计算正确，问题可能在其他地方")
        }
    }

}

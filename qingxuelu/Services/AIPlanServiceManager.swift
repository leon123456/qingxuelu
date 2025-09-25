//
//  AIPlanServiceManager.swift
//  qingxuelu
//
//  Created by Assistant on 2025-09-11.
//

import Foundation
import Combine

// MARK: - AI学习计划生成服务管理器
class AIPlanServiceManager: ObservableObject {
    static let shared = AIPlanServiceManager()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiKey = AppEnvironment.current.apiKey
    private let baseURL = AppEnvironment.current.baseURL
    
    private init() {}
    
    // MARK: - 计算实际周数
    private func calculateActualWeeks(from startDate: Date, to endDate: Date) -> Int {
        let calendar = Calendar.current
        
        // 计算两个日期之间的天数
        let daysBetween = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        
        // 将天数转换为周数，向上取整
        let weeks = Int(ceil(Double(daysBetween) / 7.0))
        
        // 确保至少为1周
        let finalWeeks = max(1, weeks)
        
        // 添加调试日志
        print("=== 周数计算调试 ===")
        print("开始日期: \(startDate)")
        print("结束日期: \(endDate)")
        print("天数差: \(daysBetween)")
        print("计算周数: \(daysBetween) ÷ 7 = \(Double(daysBetween) / 7.0)")
        print("向上取整: \(weeks)")
        print("最终周数: \(finalWeeks)")
        print("=== 周数计算调试结束 ===")
        
        return finalWeeks
    }
    
    // MARK: - 生成学习计划
    func generateLearningPlan(for goal: LearningGoal, totalWeeks: Int? = nil, dataManager: DataManager? = nil) async throws -> LearningPlan {
        // 根据目标的开始日期和结束日期计算实际周数
        let actualWeeks = calculateActualWeeks(from: goal.startDate, to: goal.targetDate)
        let weeks = totalWeeks ?? actualWeeks
        isLoading = true
        defer { isLoading = false }
        
        do {
            let prompt = buildPlanPrompt(for: goal, totalWeeks: weeks)
            
            // 添加调试日志：打印传给大模型的prompt
            print("=== AI计划生成Prompt开始 ===")
            print("目标开始时间: \(goal.startDate)")
            print("目标结束时间: \(goal.targetDate)")
            print("计算的实际周数: \(actualWeeks)")
            print("使用的周数: \(weeks)")
            print("完整Prompt:")
            print(prompt)
            print("=== AI计划生成Prompt结束 ===")
            
            let response = try await callQwenAPI(prompt: prompt)
            
            // 解析响应
            let plan = try parsePlanResponse(response, goal: goal, totalWeeks: weeks)
            
            // 不进行任务调度，只返回基础计划
            // 任务调度将在用户确认后进行
            return plan
        } catch let error as URLError {
            switch error.code {
            case .timedOut:
                errorMessage = "请求超时，请检查网络连接并重试"
            case .notConnectedToInternet:
                errorMessage = "无法连接到网络，请检查网络设置"
            default:
                errorMessage = "网络请求失败：\(error.localizedDescription)"
            }
            throw error
        } catch {
            errorMessage = "生成计划失败：\(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - 测试AI计划生成（调试用）
    func testPlanGeneration(for goal: LearningGoal, totalWeeks: Int) async throws -> String {
        let prompt = buildPlanPrompt(for: goal, totalWeeks: totalWeeks)
        return try await callQwenAPI(prompt: prompt)
    }
    
    // MARK: - 构建AI提示词
    private func buildPlanPrompt(for goal: LearningGoal, totalWeeks: Int) -> String {
        let milestonesText = goal.milestones.map { milestone in
            "- \(milestone.title): \(milestone.description)"
        }.joined(separator: "\n")
        
        let keyResultsText = goal.keyResults.map { keyResult in
            "- \(keyResult.title): 目标 \(Int(keyResult.targetValue)) \(keyResult.unit)"
        }.joined(separator: "\n")
        
        return """
        你是一位专业的学习规划师，请为以下学习目标制定一个详细的、可量化的 \(totalWeeks) 周学习计划：
        
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
        2. 每周的具体学习计划（\(totalWeeks)周）
        3. 每周的里程碑和关键结果
        4. 每周的任务数量和预估学习时长
        5. 每周的具体学习任务列表
        6. 学习资源推荐
        
        要求：
        - 计划要具体可量化，每项任务都要有明确的数量指标
        - 每周的任务要循序渐进，符合学习规律
        - 时间安排要合理，考虑学习强度和休息
        - 任务要具体可执行，避免模糊描述
        - 要体现目标的关键结果和里程碑
        - 保持JSON结构简洁，避免冗余描述
        - 每周任务控制在3-5个，避免过多细节
        
        返回格式必须是有效的JSON，结构如下：
        {
          "title": "计划标题",
          "description": "计划描述",
          "totalWeeks": \(totalWeeks),
          "weeklyPlans": [
            {
              "weekNumber": 1,
              "milestones": ["本周里程碑1", "本周里程碑2"],
              "taskCount": 5,
              "estimatedHours": 10,
              "tasks": [
                {
                  "title": "任务标题",
                  "quantity": "数量",
                  "duration": "时长",
                  "difficulty": "难度"
                }
              ]
            }
          ],
          "resources": [
            {
              "title": "资源标题",
              "type": "资源类型",
              "url": "资源链接",
              "description": "资源描述"
            }
          ]
        }
        
        请确保返回的是有效的JSON格式，不要包含其他文字说明。
        """
    }
    
    // MARK: - 调用Qwen API
    private func callQwenAPI(prompt: String, retryCount: Int = 3) async throws -> String {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw AIServiceError.invalidURL
        }
        
        let requestBody = OpenAICompatibleRequest(
            model: APIConfig.model,
            messages: [
                OpenAIMessage(role: "user", content: prompt)
            ],
            temperature: APIConfig.temperature,
            maxTokens: APIConfig.maxTokens,
            topP: APIConfig.topP
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        // 设置更长的超时时间，因为AI生成学习计划需要更多时间
        request.timeoutInterval = 300.0 // 5分钟超时
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            return try handleResponse(data: data, response: response)
        } catch {
            if retryCount > 0 {
                // 等待1秒后重试
                try await Task.sleep(nanoseconds: 1_000_000_000)
                return try await callQwenAPI(prompt: prompt, retryCount: retryCount - 1)
            }
            throw error
        }
        
    }
    
    private func handleResponse(data: Data, response: URLResponse) throws -> String {
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AIServiceError.apiError
        }
        
        let openAIResponse = try JSONDecoder().decode(OpenAICompatibleResponse.self, from: data)
        
        guard let content = openAIResponse.choices.first?.message.content else {
            throw AIServiceError.noContent
        }
        
        return content
    }
    
    // MARK: - 解析AI响应
    private func parsePlanResponse(_ response: String, goal: LearningGoal, totalWeeks: Int) throws -> LearningPlan {
        // 添加调试信息
        print("=== AI计划生成原始响应开始 ===")
        print(response)
        print("=== AI计划生成原始响应结束 ===")
        
        // 清理响应文本，提取JSON部分
        let cleanedResponse = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("=== 清理后计划响应开始 ===")
        print(cleanedResponse)
        print("=== 清理后计划响应结束 ===")
        
        // 尝试修复不完整的JSON
        let fixedResponse = fixIncompleteJSON(cleanedResponse)
        print("=== 修复后计划响应开始 ===")
        print(fixedResponse)
        print("=== 修复后计划响应结束 ===")
        
        guard let data = fixedResponse.data(using: .utf8) else {
            print("无法将计划响应转换为UTF-8数据")
            throw AIServiceError.parseError
        }
        
        // 先尝试解析为字典
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            print("=== 计划JSON对象解析成功 ===")
            print(jsonObject)
            print("=== 计划JSON对象结束 ===")
            
            // 尝试解析为灵活的字典结构
            if let dict = jsonObject as? [String: Any] {
                return try parseFlexiblePlan(from: dict, goal: goal, totalWeeks: totalWeeks)
            }
        } catch {
            print("计划JSON对象解析失败: \(error)")
            print("原始数据: \(String(data: data, encoding: .utf8) ?? "无法转换为字符串")")
        }
        
        // 如果解析失败，创建一个默认计划
        print("创建默认学习计划...")
        return createDefaultPlan(for: goal, totalWeeks: totalWeeks)
    }
    
    // MARK: - 修复不完整的JSON
    private func fixIncompleteJSON(_ jsonString: String) -> String {
        var fixed = jsonString
        
        // 检查是否缺少结束的括号
        let openBraces = fixed.filter { $0 == "{" }.count
        let closeBraces = fixed.filter { $0 == "}" }.count
        let openBrackets = fixed.filter { $0 == "[" }.count
        let closeBrackets = fixed.filter { $0 == "]" }.count
        
        // 添加缺少的结束括号
        for _ in 0..<(openBrackets - closeBrackets) {
            fixed += "]"
        }
        for _ in 0..<(openBraces - closeBraces) {
            fixed += "}"
        }
        
        return fixed
    }
    
    // MARK: - 灵活解析计划
    private func parseFlexiblePlan(from dict: [String: Any], goal: LearningGoal, totalWeeks: Int) throws -> LearningPlan {
        // 提取标题和描述
        let title = dict["title"] as? String ?? "\(goal.title) 学习计划"
        let description = dict["description"] as? String ?? "基于AI生成的学习计划"
        
        let plan = LearningPlan(
            id: goal.id,  // 使用目标的ID
            title: title,
            description: description,
            startDate: goal.startDate,
            endDate: goal.targetDate,
            totalWeeks: totalWeeks
        )
        
        // 解析周计划
        var weeklyPlans: [WeeklyPlan] = []
        if let weeklyPlansArray = dict["weeklyPlans"] as? [[String: Any]] {
            for weekDict in weeklyPlansArray {
                if let weeklyPlan = parseWeeklyPlan(from: weekDict, goal: goal) {
                    weeklyPlans.append(weeklyPlan)
                }
            }
        }
        
        // 解析学习资源
        var resources: [LearningResource] = []
        if let resourcesArray = dict["resources"] as? [[String: Any]] {
            for resourceDict in resourcesArray {
                if let resource = parseResource(from: resourceDict) {
                    resources.append(resource)
                }
            }
        }
        
        var updatedPlan = plan
        updatedPlan.weeklyPlans = weeklyPlans
        updatedPlan.resources = resources
        
        print("✅ AI计划解析成功！")
        print("📊 周计划数量: \(weeklyPlans.count)")
        print("📊 资源数量: \(resources.count)")
        
        return updatedPlan
    }
    
    // MARK: - 解析周计划
    private func parseWeeklyPlan(from weekDict: [String: Any], goal: LearningGoal) -> WeeklyPlan? {
        guard let weekNumber = weekDict["weekNumber"] as? Int else { return nil }
        
        let milestones = weekDict["milestones"] as? [String] ?? []
        let taskCount = weekDict["taskCount"] as? Int ?? 5
        let estimatedHours = weekDict["estimatedHours"] as? Double ?? 10.0
        
        // 解析任务列表
        var tasks: [WeeklyTask] = []
        if let tasksArray = weekDict["tasks"] as? [[String: Any]] {
            print("🔍 第\(weekNumber)周任务数组长度: \(tasksArray.count)")
            for (index, taskDict) in tasksArray.enumerated() {
                print("🔍 第\(weekNumber)周任务\(index + 1): \(taskDict)")
                if let task = parseWeeklyTask(from: taskDict) {
                    tasks.append(task)
                    print("✅ 第\(weekNumber)周任务\(index + 1)解析成功: \(task.title)")
                } else {
                    print("❌ 第\(weekNumber)周任务\(index + 1)解析失败")
                }
            }
        } else {
            print("❌ 第\(weekNumber)周没有找到tasks数组")
        }
        
        print("🔍 第\(weekNumber)周最终任务数量: \(tasks.count)")
        
        // 计算周的开始和结束日期
        let calendar = Calendar.current
        
        // 确保开始日期是周一
        var currentDate = goal.startDate
        let weekday = calendar.component(.weekday, from: currentDate)
        if weekday != 2 { // 2 表示周一
            let daysToAdd = (9 - weekday) % 7 // 计算到下周一的天数
            currentDate = calendar.date(byAdding: .day, value: daysToAdd, to: currentDate) ?? currentDate
        }
        
        // 根据周数计算开始和结束日期
        let startDate = calendar.date(byAdding: .weekOfYear, value: weekNumber - 1, to: currentDate) ?? currentDate
        let endDate = calendar.date(byAdding: .day, value: 6, to: startDate) ?? startDate
        
        return WeeklyPlan(
            weekNumber: weekNumber,
            startDate: startDate,
            endDate: endDate,
            milestones: milestones,
            taskCount: taskCount,
            estimatedHours: estimatedHours,
            tasks: tasks
        )
    }
    
    // MARK: - 解析周任务
    private func parseWeeklyTask(from taskDict: [String: Any]) -> WeeklyTask? {
        guard let title = taskDict["title"] as? String else { return nil }
        
        let quantity = taskDict["quantity"] as? String ?? ""
        let duration = taskDict["duration"] as? String ?? ""
        let difficultyString = taskDict["difficulty"] as? String ?? "中等"
        
        // 解析难度
        let difficulty: TaskDifficulty
        switch difficultyString.lowercased() {
        case "简单", "easy":
            difficulty = .easy
        case "困难", "hard":
            difficulty = .hard
        default:
            difficulty = .medium
        }
        
        // 解析预估时长（从duration字符串中提取）
        let estimatedDuration = parseDurationFromString(duration)
        
        return WeeklyTask(
            title: title,
            description: "", // 简化版本不包含描述
            quantity: quantity,
            duration: duration,
            difficulty: difficulty,
            estimatedDuration: estimatedDuration
        )
    }
    
    // MARK: - 解析时长字符串
    private func parseDurationFromString(_ durationString: String) -> TimeInterval {
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
    
    // MARK: - 解析学习资源
    private func parseResource(from resourceDict: [String: Any]) -> LearningResource? {
        guard let title = resourceDict["title"] as? String else { return nil }
        
        let description = resourceDict["description"] as? String ?? ""
        let url = resourceDict["url"] as? String ?? ""
        let typeString = resourceDict["type"] as? String ?? "文档"
        
        let resourceType: ResourceType
        switch typeString.lowercased() {
        case "视频", "video":
            resourceType = .video
        case "文档", "document", "pdf", "教材", "textbook":
            resourceType = .textbook
        case "网站", "website", "url":
            resourceType = .website
        case "应用", "app", "application":
            resourceType = .app
        case "习题", "exercise":
            resourceType = .exercise
        case "课程", "course":
            resourceType = .course
        default:
            resourceType = .other
        }
        
        return LearningResource(
            title: title,
            type: resourceType,
            url: url,
            description: description
        )
    }
    
    // MARK: - 创建默认计划
    private func createDefaultPlan(for goal: LearningGoal, totalWeeks: Int) -> LearningPlan {
        let plan = LearningPlan(
            id: goal.id,  // 使用目标的ID
            title: "\(goal.title) 学习计划",
            description: "基于目标自动生成的学习计划",
            startDate: goal.startDate,
            endDate: goal.targetDate,
            totalWeeks: totalWeeks
        )
        
        // 生成默认的周计划
        var weeklyPlans: [WeeklyPlan] = []
        let calendar = Calendar.current
        
        // 确保开始日期是周一
        var currentDate = goal.startDate
        let weekday = calendar.component(.weekday, from: currentDate)
        if weekday != 2 { // 2 表示周一
            let daysToAdd = (9 - weekday) % 7 // 计算到下周一的天数
            currentDate = calendar.date(byAdding: .day, value: daysToAdd, to: currentDate) ?? currentDate
        }
        
        for week in 1...totalWeeks {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: week - 1, to: currentDate) ?? currentDate
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
            
            // 生成默认任务
            let defaultTasks = [
                WeeklyTask(title: "理论学习", description: "学习相关理论知识", quantity: "2小时", duration: "2小时", difficulty: .medium),
                WeeklyTask(title: "实践练习", description: "完成相关练习", quantity: "5道题", duration: "1小时", difficulty: .medium),
                WeeklyTask(title: "复习巩固", description: "复习本周学习内容", quantity: "1次", duration: "1小时", difficulty: .easy),
                WeeklyTask(title: "拓展阅读", description: "阅读相关资料", quantity: "3篇文章", duration: "1小时", difficulty: .easy),
                WeeklyTask(title: "总结反思", description: "总结学习心得", quantity: "1篇", duration: "30分钟", difficulty: .easy)
            ]
            
            let weeklyPlan = WeeklyPlan(
                weekNumber: week,
                startDate: weekStart,
                endDate: weekEnd,
                milestones: ["完成第\(week)周学习目标"],
                taskCount: defaultTasks.count,
                estimatedHours: 10.0,
                tasks: defaultTasks
            )
            weeklyPlans.append(weeklyPlan)
        }
        
        var updatedPlan = plan
        updatedPlan.weeklyPlans = weeklyPlans
        
        return updatedPlan
    }
    
    // MARK: - 任务调度
    func schedulePlanTasks(_ plan: LearningPlan, dataManager: DataManager?) async throws -> LearningPlan {
        var scheduledPlan = plan
        var allScheduledTasks: [LearningTask] = []
        
        // 为每个周计划调度任务
        for weeklyPlan in plan.weeklyPlans {
            let scheduledTasks = TaskScheduler.shared.scheduleWeeklyTasks(
                weeklyPlan, 
                for: weeklyPlan.startDate,
                goalId: plan.id, // LearningPlan的id就是目标的ID
                planId: plan.id  // 传递计划ID
            )
            allScheduledTasks.append(contentsOf: scheduledTasks)
        }
        
        // 将调度的任务添加到计划中，但不保存到DataManager
        scheduledPlan.scheduledTasks = allScheduledTasks
        
        print("✅ 任务调度完成！共调度了 \(allScheduledTasks.count) 个任务")
        print("📝 任务已添加到计划中，等待用户确认后保存")
        
        return scheduledPlan
    }
}

// MARK: - AI计划生成请求模型
struct AIPlanRequest: Codable {
    let goal: LearningGoal
    let totalWeeks: Int
    let preferences: PlanPreferences?
}

struct PlanPreferences: Codable {
    let dailyStudyHours: Double?
    let weeklyStudyDays: Int?
    let difficultyLevel: String?
    let focusAreas: [String]?
}

// MARK: - AI计划生成响应模型
struct AIPlanResponse: Codable {
    let title: String
    let description: String
    let totalWeeks: Int
    let weeklyPlans: [AIWeeklyPlan]
    let resources: [AIResource]
}

struct AIWeeklyPlan: Codable {
    let weekNumber: Int
    let milestones: [String]
    let taskCount: Int
    let estimatedHours: Double
    let tasks: [AITask]
}

struct AITask: Codable {
    let title: String
    let description: String
    let quantity: String?
    let duration: String?
    let difficulty: String?
}

struct AIResource: Codable {
    let title: String
    let type: String
    let url: String?
    let description: String?
}

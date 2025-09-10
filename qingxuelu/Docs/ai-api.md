# 🤖 AI服务API文档

## 概述

本文档描述了清学路应用中使用的阿里云百炼AI服务的API接口和实现细节。

## 服务架构

### 核心组件

1. **AIServiceManager** - AI服务管理器
2. **AITestService** - AI测试服务
3. **APIConfig** - API配置管理

## API配置

### 阿里云百炼配置

```swift
struct APIConfig {
    // 阿里云百炼API配置
    static let dashScopeAPIKey = "sk-f648425ba77d477499c746cb78dc681e"
    static let baseURL = "https://dashscope.aliyuncs.com/compatible-mode/v1"
    static let model = "qwen-plus"
    static let temperature = 0.7
    static let maxTokens = 4000
    static let topP = 0.8
    
    // API端点
    static let chatCompletionsEndpoint = "\(baseURL)/chat/completions"
}
```

### 请求头配置

```swift
static var defaultHeaders: [String: String] {
    return [
        "Authorization": "Bearer \(dashScopeAPIKey)",
        "Content-Type": "application/json"
    ]
}
```

## API接口

### 1. 生成学习模板

#### 接口描述
根据学生档案信息生成个性化的学习管理模板。

#### 请求方法
`POST /chat/completions`

#### 请求参数

```swift
struct OpenAICompatibleRequest: Codable {
    let model: String              // 模型名称，固定为 "qwen-plus"
    let messages: [OpenAIMessage]  // 消息列表
    let temperature: Double        // 温度参数，控制随机性 (0.7)
    let maxTokens: Int            // 最大token数 (4000)
    let topP: Double              // Top-p参数 (0.8)
}

struct OpenAIMessage: Codable {
    let role: String    // 角色，固定为 "user"
    let content: String // 消息内容
}
```

#### 请求示例

```json
{
    "model": "qwen-plus",
    "messages": [
        {
            "role": "user",
            "content": "你是一位专业的教育专家，请为以下学生制定一个科学的学习管理模板：\n\n学生信息：\n- 年级：高一 (高中)\n- 学业水平：良好\n- 各科成绩：数学: 85分 (良好), 英语: 78分 (中等)\n- 学习风格：综合型\n- 优势：逻辑思维强, 学习态度认真\n- 薄弱环节：英语词汇量不足, 数学解题速度慢\n- 兴趣爱好：编程, 数学\n- 学习目标：提升英语成绩, 加强数学练习\n\n请生成一个JSON格式的学习管理模板..."
        }
    ],
    "temperature": 0.7,
    "max_tokens": 4000,
    "top_p": 0.8
}
```

#### 响应格式

```swift
struct OpenAICompatibleResponse: Codable {
    let choices: [OpenAIChoice]
}

struct OpenAIChoice: Codable {
    let message: OpenAIMessage
}
```

#### 响应示例

```json
{
    "choices": [
        {
            "message": {
                "role": "assistant",
                "content": "{\n  \"title\": \"高一学生个性化学习计划\",\n  \"description\": \"为高一学生制定的全面提升学习计划\",\n  \"goals\": [\n    {\n      \"title\": \"提升英语成绩至85分以上\",\n      \"description\": \"通过词汇积累和语法练习提升英语水平\",\n      \"category\": \"英语\",\n      \"priority\": \"高\",\n      \"targetDate\": \"2024-06-30\",\n      \"goalType\": \"smart\",\n      \"milestones\": [\"完成词汇书背诵\", \"完成语法专项练习\"],\n      \"keyResults\": []\n    }\n  ],\n  \"tasks\": [\n    \"每日背诵50个英语单词\",\n    \"每周完成2篇英语作文\",\n    \"每日练习30道数学题\"\n  ],\n  \"schedule\": {\n    \"dailyStudyTime\": 120,\n    \"weeklyStudyDays\": 6,\n    \"studyTimeSlots\": [],\n    \"breakTime\": 15\n  },\n  \"recommendations\": [\n    \"建议每天保持规律的学习时间\",\n    \"注意劳逸结合\",\n    \"定期复习巩固\"\n  ]\n}"
            }
        }
    ]
}
```

### 2. 测试API连接

#### 接口描述
测试AI服务连接是否正常。

#### 请求方法
`POST /chat/completions`

#### 请求参数

```swift
let requestBody = OpenAICompatibleRequest(
    model: "qwen-plus",
    messages: [
        OpenAIMessage(role: "user", content: "请简单介绍一下你自己，用一句话回答即可。")
    ],
    temperature: 0.7,
    maxTokens: 100,
    topP: 0.8
)
```

## 错误处理

### 错误类型

```swift
enum AIServiceError: Error, LocalizedError {
    case invalidURL      // 无效的API地址
    case apiError        // API调用失败
    case noContent       // AI未返回内容
    case parseError      // 解析AI响应失败
}
```

### 错误处理流程

1. **网络请求错误**：检查URL和网络连接
2. **API响应错误**：检查HTTP状态码和响应内容
3. **解析错误**：使用灵活的JSON解析和默认模板回退

## 响应解析

### JSON解析策略

#### 1. 清理响应文本
```swift
let cleanedResponse = response
    .replacingOccurrences(of: "```json", with: "")
    .replacingOccurrences(of: "```", with: "")
    .trimmingCharacters(in: .whitespacesAndNewlines)
```

#### 2. 修复不完整JSON
```swift
private func fixIncompleteJSON(_ jsonString: String) -> String {
    var fixed = jsonString
    
    // 检查并添加缺少的结束括号
    let openBraces = fixed.filter { $0 == "{" }.count
    let closeBraces = fixed.filter { $0 == "}" }.count
    let openBrackets = fixed.filter { $0 == "[" }.count
    let closeBrackets = fixed.filter { $0 == "]" }.count
    
    for _ in 0..<(openBrackets - closeBrackets) {
        fixed += "]"
    }
    for _ in 0..<(openBraces - closeBraces) {
        fixed += "}"
    }
    
    return fixed
}
```

#### 3. 灵活解析模板
```swift
private func parseFlexibleTemplate(from dict: [String: Any], profile: StudentProfile) throws -> LearningTemplate {
    // 支持中英文键名
    let title = dict["title"] as? String ?? 
               dict["templateTitle"] as? String ?? 
               dict["模板标题"] as? String ?? 
               "\(profile.grade.rawValue)学习计划"
    
    // 解析目标和任务
    // ...
}
```

## 使用示例

### 生成学习模板

```swift
// 创建学生档案
let profile = StudentProfile(
    studentId: UUID(),
    grade: .grade10,
    academicLevel: .good
)

// 调用AI服务
let template = try await AIServiceManager.shared.generateLearningTemplate(for: profile)
```

### 测试API连接

```swift
// 测试API连接
await AITestService.shared.testAPIConnection()

// 检查测试结果
if let result = AITestService.shared.testResult {
    print("API测试成功: \(result)")
} else if let error = AITestService.shared.testError {
    print("API测试失败: \(error)")
}
```

## 安全注意事项

1. **API密钥保护**：生产环境中应将API密钥存储在安全配置文件中
2. **请求频率限制**：避免频繁调用API，注意速率限制
3. **数据隐私**：确保学生信息在传输过程中的安全性
4. **错误处理**：完善的错误处理机制，避免敏感信息泄露

## 性能优化

1. **缓存机制**：对生成的模板进行缓存，避免重复请求
2. **异步处理**：使用async/await进行异步API调用
3. **超时设置**：设置合理的请求超时时间
4. **重试机制**：对失败的请求进行重试

## 未来扩展

1. **多模型支持**：支持不同的AI模型
2. **个性化调优**：根据用户反馈优化提示词
3. **批量处理**：支持批量生成多个模板
4. **实时更新**：支持模板的实时更新和调整

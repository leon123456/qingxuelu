//
//  TemplateManager.swift
//  qingxuelu
//
//  Created by AI Assistant on 2025/10/6.
//

import Foundation

// MARK: - 模板管理器
class TemplateManager: ObservableObject {
    static let shared = TemplateManager()
    
    @Published var templates: [GoalTemplate] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let templatesDirectory = "Templates"
    
    private init() {
        loadAllTemplates()
    }
    
    // MARK: - 加载所有模板
    func loadAllTemplates() {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            var allTemplates: [GoalTemplate] = []
            
            // 直接加载已知的模板文件
            let templateFiles = [
                // Math templates
                "advanced_math_review",
                "junior_math_grade7",
                "junior_math_grade8", 
                "junior_math_grade9",
                // Chinese templates
                "classical_chinese_learning",
                "classical_literature_reading",
                "tang_song_poetry_learning",
                "writing_skills_improvement",
                "junior_chinese_grade7",
                "junior_chinese_grade8",
                "junior_chinese_grade9",
                // English templates
                "english_speaking_improvement",
                "middle_school_english_improvement",
                "junior_english_grade7",
                "junior_english_grade8",
                "junior_english_grade9",
                // Skills templates
                "python_programming_basics",
                "time_management_skills"
            ]
            
            for templateFile in templateFiles {
                // 尝试从不同目录加载模板文件
                let possiblePaths = [
                    templateFile, // 根目录
                    "Templates/Math/\(templateFile)",
                    "Templates/Chinese/\(templateFile)", 
                    "Templates/English/\(templateFile)",
                    "Templates/Skills/\(templateFile)",
                    "Templates/Science/\(templateFile)"
                ]
                
                var templateLoaded = false
                for path in possiblePaths {
                    if let bundlePath = Bundle.main.path(forResource: path, ofType: "json") {
                        if let template = self.loadTemplateFromFile(bundlePath) {
                            allTemplates.append(template)
                            print("✅ 加载模板: \(template.name) (从 \(path))")
                            templateLoaded = true
                            break
                        }
                    }
                }
                
                if !templateLoaded {
                    print("❌ 无法找到模板文件: \(templateFile).json")
                }
            }
            
            DispatchQueue.main.async {
                self.templates = allTemplates.sorted { $0.name < $1.name }
                self.isLoading = false
                print("✅ 总共加载了 \(allTemplates.count) 个目标模板")
            }
        }
    }
    
    // MARK: - 从分类加载模板
    private func loadTemplatesFromCategory(_ category: String) -> [GoalTemplate]? {
        // 直接尝试加载已知的模板文件
        let templateFiles: [String]
        
        switch category {
        case "Math":
            templateFiles = ["advanced_math_review", "junior_math_grade7", "junior_math_grade8", "junior_math_grade9"]
        case "Chinese":
            templateFiles = ["classical_chinese_learning", "classical_literature_reading", "tang_song_poetry_learning", "writing_skills_improvement", "junior_chinese_grade7", "junior_chinese_grade8", "junior_chinese_grade9"]
        case "English":
            templateFiles = ["english_speaking_improvement", "middle_school_english_improvement", "junior_english_grade7", "junior_english_grade8", "junior_english_grade9"]
        case "Skills":
            templateFiles = ["python_programming_basics", "time_management_skills"]
        default:
            templateFiles = []
        }
        
        var templates: [GoalTemplate] = []
        
        for templateFile in templateFiles {
            // 尝试从不同目录加载模板文件
            let possiblePaths = [
                templateFile, // 根目录
                "Templates/Math/\(templateFile)",
                "Templates/Chinese/\(templateFile)", 
                "Templates/English/\(templateFile)",
                "Templates/Skills/\(templateFile)",
                "Templates/Science/\(templateFile)"
            ]
            
            var templateLoaded = false
            for path in possiblePaths {
                if let bundlePath = Bundle.main.path(forResource: path, ofType: "json") {
                    if let template = loadTemplateFromFile(bundlePath) {
                        templates.append(template)
                        templateLoaded = true
                        break
                    }
                }
            }
            
            if !templateLoaded {
                print("❌ 无法找到模板文件: \(templateFile).json")
            }
        }
        
        if !templates.isEmpty {
            print("✅ 加载了 \(templates.count) 个 \(category) 模板")
        }
        
        return templates.isEmpty ? nil : templates
    }
    
    // MARK: - 从文件加载单个模板
    private func loadTemplateFromFile(_ filePath: String) -> GoalTemplate? {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
            let templateData = try JSONDecoder().decode(TemplateDataModel.self, from: data)
            return templateData.toGoalTemplate()
        } catch {
            print("❌ 加载模板文件失败: \(filePath), 错误: \(error)")
            return nil
        }
    }
    
    // MARK: - 按分类获取模板
    func getTemplatesByCategory(_ category: SubjectCategory) -> [GoalTemplate] {
        return templates.filter { $0.category == category }
    }
    
    // MARK: - 搜索模板
    func searchTemplates(_ searchText: String) -> [GoalTemplate] {
        if searchText.isEmpty {
            return templates
        }
        
        return templates.filter { template in
            template.name.localizedCaseInsensitiveContains(searchText) ||
            template.description.localizedCaseInsensitiveContains(searchText) ||
            template.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    // MARK: - 获取模板统计
    func getTemplateStats() -> TemplateStats {
        let categoryCount = Dictionary(grouping: templates, by: { $0.category })
            .mapValues { $0.count }
        
        return TemplateStats(
            totalTemplates: templates.count,
            categoryCount: categoryCount,
            averageDuration: templates.map { $0.duration }.reduce(0, +) / max(templates.count, 1)
        )
    }
}

// MARK: - 模板统计
struct TemplateStats {
    let totalTemplates: Int
    let categoryCount: [SubjectCategory: Int]
    let averageDuration: Int
    
    var categoryBreakdown: String {
        return categoryCount.map { "\($0.key.rawValue): \($0.value)" }.joined(separator: ", ")
    }
}

// MARK: - 模板文件结构
struct TemplateFileStructure {
    static let categories = [
        "Math": "数学",
        "Chinese": "语文", 
        "English": "英语",
        "Science": "科学",
        "Skills": "技能"
    ]
    
    static func getCategoryDisplayName(_ category: String) -> String {
        return categories[category] ?? category
    }
    
    static func getCategoryForSubject(_ subject: SubjectCategory) -> String {
        switch subject {
        case .math:
            return "Math"
        case .chinese:
            return "Chinese"
        case .english:
            return "English"
        case .physics, .chemistry, .biology, .science:
            return "Science"
        case .history, .geography, .politics, .other:
            return "Skills"
        }
    }
}

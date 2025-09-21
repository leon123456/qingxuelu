//
//  GlassmorphismCard.swift
//  qingxuelu
//
//  Created by AI Assistant on 2025/1/27.
//

import SwiftUI

/// 毛玻璃效果卡片组件
struct GlassmorphismCard<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    let padding: EdgeInsets
    
    init(
        cornerRadius: CGFloat = 16,
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .shadow(
                        color: .black.opacity(0.1),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
    }
}

/// 带边框的毛玻璃效果卡片
struct GlassmorphismCardWithBorder<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    let padding: EdgeInsets
    let borderColor: Color
    let borderWidth: CGFloat
    
    init(
        cornerRadius: CGFloat = 16,
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        borderColor: Color = .white.opacity(0.2),
        borderWidth: CGFloat = 1,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
                    .shadow(
                        color: .black.opacity(0.1),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
    }
}

#Preview {
    VStack(spacing: 20) {
        GlassmorphismCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("基础毛玻璃卡片")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("这是一个基础的毛玻璃效果卡片，使用 .ultraThinMaterial 材质")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        
        GlassmorphismCardWithBorder {
            VStack(alignment: .leading, spacing: 8) {
                Text("带边框的毛玻璃卡片")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("这是一个带边框的毛玻璃效果卡片，具有更明显的视觉边界")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    .padding()
    .background(
        LinearGradient(
            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}


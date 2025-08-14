//
//  OnboardingView.swift
//  FrameExtractionTool
//
//  Created by Casper Ong on 14/8/2025.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @State private var currentPage = 0
    
    private let pages = [
        OnboardingPage(
            icon: "video.fill",
            title: "Choose Your Video",
            description: "Select any video from your photo library to get started",
            color: .blue
        ),
        OnboardingPage(
            icon: "plus.circle.fill",
            title: "Mark Perfect Moments",
            description: "Play your video and tap the plus button to mark frames you want to extract",
            color: .green
        ),
        OnboardingPage(
            icon: "photo.stack",
            title: "Extract & Save",
            description: "Save all your marked frames to your photo library in original quality",
            color: .purple
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Page Content
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(maxHeight: .infinity)
            
            // Bottom Controls
            VStack(spacing: 20) {
                // Page Indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? pages[currentPage].color : Color.gray.opacity(0.3))
                            .frame(width: 10, height: 10)
                            .animation(.easeInOut, value: currentPage)
                    }
                }
                
                // Action Button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation(.easeInOut) {
                            currentPage += 1
                        }
                    } else {
                        showOnboarding = false
                    }
                } label: {
                    HStack {
                        Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                        if currentPage < pages.count - 1 {
                            Image(systemName: "arrow.right")
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(pages[currentPage].color)
                .animation(.easeInOut, value: currentPage)
                
                // Skip Button
                if currentPage < pages.count - 1 {
                    Button("Skip") {
                        showOnboarding = false
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .background(.regularMaterial)
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icon
            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundStyle(page.color.gradient)
            
            // Content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(showOnboarding: .constant(true))
}

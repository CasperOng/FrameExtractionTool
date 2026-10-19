//
//  OnboardingView.swift
//  FrameExtractionTool
//
//  Created by Casper Ong on 14/8/2025.
//

import SwiftUI

/// The first-run tour. Also reachable from Settings, so it always offers a way out.
struct OnboardingView: View {

    let onFinish: () -> Void

    @State private var pageIndex = 0

    private struct Page: Identifiable {
        let id = UUID()
        let symbol: String
        let title: String
        let description: String
    }

    private let pages: [Page] = [
        Page(
            symbol: "photo.on.rectangle.angled",
            title: "Choose a Video",
            description: "Pick any video from your photo library."
        ),
        Page(
            symbol: "square.and.arrow.down.on.square",
            title: "Or Share One In",
            description: "Share a video to Frame Extractor from Photos, Files or any other app — it opens ready to use."
        ),
        Page(
            symbol: "plus.circle",
            title: "Mark the Moments",
            description: "Play the video and tap the plus button to mark the frames you want."
        ),
        Page(
            symbol: "photo.stack",
            title: "Extract and Save",
            description: "Save every marked frame to your photo library at the video’s own resolution."
        ),
    ]

    private var isLastPage: Bool { pageIndex == pages.count - 1 }

    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.xl) {
                TabView(selection: $pageIndex) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        pageView(page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                Button {
                    if isLastPage {
                        onFinish()
                    } else {
                        withAnimation(.easeInOut) { pageIndex += 1 }
                    }
                } label: {
                    Text(isLastPage ? "Get Started" : "Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.bottom, AppTheme.Spacing.sm)

                if !isLastPage {
                    Button("Skip") { onFinish() }
                        .font(AppTheme.Typography.subheadline)
                        .padding(.bottom, AppTheme.Spacing.lg)
                }
            }
            .navigationTitle("Frame Extractor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onFinish()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Close tutorial")
                }
            }
        }
    }

    private func pageView(_ page: Page) -> some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()
            Image(systemName: page.symbol)
                .font(.system(.largeTitle, design: .rounded))
                .imageScale(.large)
                .fontWeight(.light)
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)
                .accessibilityHidden(true)

            VStack(spacing: AppTheme.Spacing.sm) {
                Text(page.title)
                    .font(AppTheme.Typography.title2)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    OnboardingView {}
}

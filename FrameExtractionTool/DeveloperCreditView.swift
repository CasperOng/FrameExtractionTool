//
//  DeveloperCreditView.swift
//  FrameExtractionTool
//

import SwiftUI

/// The developer credit that closes the app, in the same shape as the footer on
/// casperong.is-a.dev and in the Visitor Connect apps: the signature, the name,
/// and what helped build it — all linking to the developer's site.
struct DeveloperCreditView: View {

    static let siteURL = URL(string: "https://casperong.is-a.dev/")!

    /// Width of the signature artwork; the height follows its 541 × 136 shape.
    var signatureWidth: CGFloat = 156

    private var signatureHeight: CGFloat {
        signatureWidth * 136 / 541
    }

    var body: some View {
        Link(destination: Self.siteURL) {
            VStack(spacing: AppTheme.Spacing.md) {
                Image("CasperSignature")
                    .resizable()
                    .scaledToFit()
                    .frame(width: signatureWidth, height: signatureHeight)
                    .opacity(0.8)
                    .accessibilityHidden(true)

                VStack(spacing: AppTheme.Spacing.xs) {
                    Text("Developed by Casper Ong")
                    Text("With the help of GitHub Copilot and Claude")
                }
                .font(AppTheme.Typography.footnote)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(.secondary)
            .frame(minHeight: AppTheme.minimumHitTarget)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.sm)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens casperong.is-a.dev")
    }
}

#Preview {
    DeveloperCreditView()
}

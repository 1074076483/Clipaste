import AppKit
import KeyboardShortcuts
import SwiftUI

struct OnboardingView: View {
    @StateObject var viewModel = OnboardingViewModel()

    private var isLastStep: Bool {
        viewModel.currentStep == .preferences
    }

    private var canContinue: Bool {
        viewModel.currentStep != .permissions || viewModel.hasAccessibilityPermission
    }

    var body: some View {
        ZStack {
            backgroundView

            VStack(spacing: 0) {
                // ── Page content ──
                
                // Step Indicator Dots in Content Area
                stepIndicatorDots
                
                Group {
                    switch viewModel.currentStep {
                    case .welcomeAndShortcut:
                        ShortcutView()
                            .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .trailing)), removal: .opacity.combined(with: .move(edge: .leading))))
                    case .permissions:
                        PermissionView(
                            hasAccessibilityPermission: viewModel.hasAccessibilityPermission,
                            openSystemSettings: viewModel.openSystemSettingsForAccessibility
                        )
                        .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .trailing)), removal: .opacity.combined(with: .move(edge: .leading))))
                    case .preferences:
                        PreferencesView(
                            launchAtLogin: $viewModel.launchAtLogin,
                            historyLimit: $viewModel.historyLimit
                        )
                        .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .trailing)), removal: .opacity.combined(with: .move(edge: .leading))))
                    }
                }
                .id(viewModel.currentStep)
                .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)

                // ── Bottom bar ──
                bottomNavigationBar
            }
            .padding(30)
        }
        .frame(width: 520, height: 460)
        .onAppear {
            if viewModel.currentStep == .permissions {
                viewModel.checkPermission()
            }
        }
        .onChange(of: viewModel.currentStep) { _, newStep in
            if newStep == .permissions {
                viewModel.checkPermission()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            viewModel.checkPermission()
        }
    }

    // MARK: - Background

    private var backgroundView: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.94, green: 0.98, blue: 0.97),
                    Color(red: 0.92, green: 0.95, blue: 1.00)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color(red: 0.27, green: 0.68, blue: 0.59).opacity(0.22))
                .frame(width: 240, height: 240)
                .blur(radius: 18)
                .offset(x: 170, y: -150)

            Circle()
                .fill(Color(red: 0.99, green: 0.73, blue: 0.37).opacity(0.18))
                .frame(width: 220, height: 220)
                .blur(radius: 24)
                .offset(x: -180, y: 155)
        }
        .overlay(.ultraThinMaterial.opacity(0.5))
    }

    // MARK: - Step Indicator
    
    private var stepIndicatorDots: some View {
        HStack(spacing: 8) {
            ForEach(OnboardingStep.allCases, id: \.self) { step in
                Circle()
                    .fill(step == viewModel.currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.22), value: viewModel.currentStep)
            }
        }
        .padding(.bottom, 24)
        .padding(.top, 16)
    }

    // MARK: - Bottom Navigation Bar

    private var bottomNavigationBar: some View {
        HStack {
            Spacer()

            // Primary Action Button
            Button(action: viewModel.nextStep) {
                Text(isLastStep ? "完成" : "下一步")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(minWidth: 96)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(.accentColor)
            .controlSize(.large)
            .disabled(!canContinue)
        }
        .padding(.top, 16)
        .padding(.bottom, 10)
    }
}

// MARK: - Step 1: Shortcut

private struct ShortcutView: View {
    private var appIcon: NSImage {
        NSApplication.shared.applicationIconImage
    }

    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 20) {
                // App icon
                Image(nsImage: appIcon)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 96, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 20, y: 10)

                // Title / Subtitle
                VStack(spacing: 8) {
                    Text("欢迎使用 Clipaste")
                        .font(.system(size: 28, weight: .bold))

                    Text("设置你的专属唤醒快捷键")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                // Shortcut recorder panel
                VStack(alignment: .leading, spacing: 12) {
                    Text("全局快捷键")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)

                    HStack {
                        Text("呼出剪贴板历史记录")
                            .font(.system(size: 15, weight: .medium))

                        Spacer()

                        KeyboardShortcuts.Recorder(for: .toggleClipboardPanel)
                    }
                }
                .padding(20)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.4))
                )
                .padding(.horizontal, 36)

                Text("稍后也可以在设置中修改。")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Step 2: Permissions

private struct PermissionView: View {
    let hasAccessibilityPermission: Bool
    let openSystemSettings: () -> Void

    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: hasAccessibilityPermission ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(hasAccessibilityPermission ? Color.green : Color.red)

                VStack(spacing: 8) {
                    Text("赋予粘贴超能力")
                        .font(.system(size: 28, weight: .bold))

                    Text("Clipaste 需要辅助功能权限才能在任何应用中安全地模拟粘贴。")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 360)
                }

                Label(
                    hasAccessibilityPermission
                        ? "已授权 — 请继续"
                        : "需要授权 — 去系统设置中开启",
                    systemImage: hasAccessibilityPermission ? "checkmark.circle.fill" : "xmark.circle.fill"
                )
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(hasAccessibilityPermission ? Color.green : Color.red)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule(style: .continuous))

                Button(action: openSystemSettings) {
                    Text("打开系统设置以授权")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal, 72)

                Text("授权后返回 Clipaste；状态会自动刷新。")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
            }
            
            Spacer()
        }
    }
}

// MARK: - Step 3: Preferences

private struct PreferencesView: View {
    @Binding var launchAtLogin: Bool
    @Binding var historyLimit: HistoryLimit

    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("设置偏好")
                        .font(.system(size: 28, weight: .bold))

                    Text("这些选项随时可以在设置中更改。")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: $launchAtLogin) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("登录时启动")
                                    .font(.system(size: 15, weight: .semibold))

                                Text("登录后自动运行并在菜单栏显示，不打扰你的工作流。")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .toggleStyle(.switch)
                    }
                    .padding(18)

                    Divider()
                        .overlay(Color.white.opacity(0.4))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("历史记录容量")
                            .font(.system(size: 15, weight: .semibold))

                        Picker("历史记录容量", selection: $historyLimit) {
                            ForEach(HistoryLimit.allCases) { limit in
                                Text(limit.displayName).tag(limit)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(18)
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.4))
                )
                .padding(.horizontal, 36)
            }
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
}

//
//  MainView.swift
//  PomodorroFly
//
//  Created by Andrei Musca on 05.11.2025.
//

import SwiftUI

struct MainView: View {
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    // MARK: - Configurable durations (seconds)
    @State private var focusDuration: Int = 25 * 60
    @State private var smallBreakDuration: Int = 5 * 60
    @State private var bigBreakDuration: Int = 15 * 60
    @State private var sessionsPerCycle: Int = 4

    // MARK: - Runtime state
    @State private var isRunning: Bool = false
    @State private var phase: Phase = .focus
    @State private var remaining: Int = 25 * 60
    @State private var currentSession: Int = 1 // 1...sessionsPerCycle
    @State private var timer: Timer? = nil
    @State private var showSettings: Bool = false

    enum Phase: String { case focus, smallBreak, bigBreak }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                header
                progressRing
                controls
                statusFooter
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem() {
                    Button {
                        showSettings = true
                    } label: {
                        Label("Setări", systemImage: "slider.horizontal.3")
                    }
                }
                //modificare
                ToolbarItem() {
                    Button {
                        Task { await handleLogout() }
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }
                    .disabled(isLoading)
                }
            }
            .sheet(isPresented: $showSettings) { settingsView }
            .onDisappear { invalidateTimer() }
            .onAppear { syncRemainingForPhase() }
            .alert("Eroare la logout", isPresented: .constant(errorMessage != nil), actions: {
                Button("OK") { errorMessage = nil }
            }, message: {
                Text(errorMessage ?? "A apărut o eroare necunoscută.")
            })
        }
    }

    // MARK: - Subviews
    private var header: some View {
        VStack(spacing: 4) {
            Text(titleForPhase)
                .font(.largeTitle).bold()
            Text(subtitleForPhase)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 16)
                .frame(width: 240, height: 240)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(colorForPhase, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 240, height: 240)
                .animation(.easeInOut(duration: 0.2), value: progress)

            VStack(spacing: 6) {
                Text(timeString(from: remaining))
                    .font(.system(size: 42, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text(secondaryTimeLabel)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 16) {
            Button(action: toggle) {
                Label(isRunning ? "Pauză" : "Start", systemImage: isRunning ? "pause.fill" : "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button(action: skipPhase) {
                Label("Fast Forward", systemImage: "goforward")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.secondary)
        }
        .padding(.horizontal)
    }

    private var statusFooter: some View {
        VStack(spacing: 8) {
            HStack {
                Label("Sesiune: \(currentSession)/\(sessionsPerCycle)", systemImage: "circlebadge")
                Spacer()
                Label("Fază: \(titleForPhase)", systemImage: "clock")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }

    private var settingsView: some View {
        NavigationStack {
            Form {
                Section("Focus") {
                    Stepper(value: $focusDuration, in: 5*60...120*60, step: 60, onEditingChanged: { _ in syncRemainingIfIdle() }) {
                        LabeledContent("Durată", value: durationString(from: focusDuration))
                    }
                }

                Section("Small break") {
                    Stepper(value: $smallBreakDuration, in: 1*60...30*60, step: 60, onEditingChanged: { _ in syncRemainingIfIdle() }) {
                        LabeledContent("Durată", value: durationString(from: smallBreakDuration))
                    }
                }

                Section("Sessions per cycle") {
                    Stepper(value: $sessionsPerCycle, in: 1...12, step: 1) {
                        LabeledContent("Sesiuni", value: "\(sessionsPerCycle)")
                    }
                }

                Section("Big break") {
                    Stepper(value: $bigBreakDuration, in: 5*60...60*60, step: 60, onEditingChanged: { _ in syncRemainingIfIdle() }) {
                        LabeledContent("Durată", value: durationString(from: bigBreakDuration))
                    }
                }

                Section {
                    Button(role: .destructive) {
                        resetAll()
                    } label: {
                        Label("Reset ciclul curent", systemImage: "gobackward")
                    }
                }
            }
            .navigationTitle("Setări Pomodoro")
            .toolbar {
                ToolbarItem() {
                    Button("OK") { showSettings = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Derived
    private var totalForCurrentPhase: Int {
        switch phase {
        case .focus: return focusDuration
        case .smallBreak: return smallBreakDuration
        case .bigBreak: return bigBreakDuration
        }
    }

    private var progress: CGFloat {
        guard totalForCurrentPhase > 0 else { return 0 }
        return 1 - CGFloat(remaining) / CGFloat(totalForCurrentPhase)
    }

    private var titleForPhase: String {
        switch phase {
        case .focus: return "Focus"
        case .smallBreak: return "Pauză scurtă"
        case .bigBreak: return "Pauză mare"
        }
    }

    private var subtitleForPhase: String {
        switch phase {
        case .focus:
            return "Sesiunea \(currentSession) din \(sessionsPerCycle)"
        case .smallBreak:
            return "Între sesiuni"
        case .bigBreak:
            return "Între cicluri"
        }
    }

    private var colorForPhase: Color {
        switch phase {
        case .focus: return .red
        case .smallBreak: return .green
        case .bigBreak: return .blue
        }
    }

    private var secondaryTimeLabel: String {
        switch phase {
        case .focus: return "până la pauză"
        case .smallBreak: return "până la următoarea sesiune"
        case .bigBreak: return "până la următorul ciclu"
        }
    }

    // MARK: - Actions
    private func toggle() {
        if isRunning { pause() } else { start() }
    }

    private func start() {
        if remaining <= 0 { advancePhase() }
        isRunning = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in tick() }
        if let timer { RunLoop.current.add(timer, forMode: .common) }
    }

    private func pause() {
        isRunning = false
        invalidateTimer()
    }

    private func resetAll() {
        invalidateTimer()
        isRunning = false
        currentSession = 1
        phase = .focus
        syncRemainingForPhase()
    }

    private func tick() {
        guard remaining > 0 else {
            advancePhase()
            return
        }
        remaining -= 1
    }

    private func advancePhase() {
        switch phase {
        case .focus:
            if currentSession < sessionsPerCycle {
                // Move to small break between sessions
                phase = .smallBreak
            } else {
                // Completed a cycle -> big break
                phase = .bigBreak
            }
        case .smallBreak:
            // After small break, start next focus session
            currentSession += 1
            phase = .focus
        case .bigBreak:
            // After big break, reset session count and start a new cycle with focus
            currentSession = 1
            phase = .focus
        }
        syncRemainingForPhase()
        // Keep timer running if it was running
        if isRunning {
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in tick() }
            if let timer { RunLoop.current.add(timer, forMode: .common) }
        }
    }

    private func skipPhase() {
        // Skip current phase as if it just completed
        remaining = 0
        advancePhase()
    }

    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func syncRemainingForPhase() {
        remaining = totalForCurrentPhase
    }

    private func syncRemainingIfIdle() {
        // If user changes settings while timer is not running and we're at the start of a phase
        if !isRunning { syncRemainingForPhase() }
    }
    
    // MARK: - Auth
    private func handleLogout() async {
        await MainActor.run { isLoading = true; errorMessage = nil }
        do {
            try await AuthService.shared.logOut()
        } catch {
            let message = error.localizedDescription
            await MainActor.run {
                errorMessage = message
                print(errorMessage ?? "Unknown error")
            }
        }
        await MainActor.run { isLoading = false }
    }

    // MARK: - Formatting helpers
    private func timeString(from seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func durationString(from seconds: Int) -> String {
        let m = seconds / 60
        return "\(m) min"
    }
}

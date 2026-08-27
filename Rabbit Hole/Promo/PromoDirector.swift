#if DEBUG
import Foundation
import SwiftUI
import Combine

/// Drives one continuous live Rabbit Hole run. A target is tapped only when
/// the production swing ray genuinely owns it; the director never teleports
/// the hook or skips a pickup/score phase.
@MainActor
final class PromoDirector: ObservableObject {
    enum Phase: Equatable {
        case waitingForCapture
        case entrance
        case firstApproach
        case waitScore15
        case secondApproach
        case waitWrong12
        case octopusTransform
        case octopusApproach
        case waitScore18
        case frogTransform
        case frogApproach
        case waitScore56
        case penguinTransform
        case warning
        case dynamiteApproach
        case falling
        case bunnyLandingTransform
        case rapid15
        case waitRapid15
        case rapid18
        case waitRapid18
        case rapid13
        case waitRapid13
        case finale
        case icon
        case done
    }

    @Published private(set) var phase: Phase = .waitingForCapture
    @Published private(set) var characterID = "bunny"
    @Published private(set) var headline: String? = PromoScript.headlineGrab
    @Published private(set) var showsDynamiteArrow = false
    @Published private(set) var showsIcon = false
    @Published private(set) var blursPlayfield = false
    @Published private(set) var isFinished = false
    @Published private(set) var transformationToken = 0

    let model: GameViewModel
    private(set) weak var arena: RabbitHoleArena?
    var onReadyForCapture: (() -> Void)?

    private var timer: Timer?
    private var startedAt: TimeInterval = 0
    private var phaseStartedAt: TimeInterval = 0
    private var completionFinished = false
    private var hasAttached = false

    private var phaseElapsed: Double { CACurrentMediaTime() - phaseStartedAt }
    private var elapsed: Double { CACurrentMediaTime() - startedAt }
    private var timeout: Double {
        ProcessInfo.processInfo.arguments.contains("-RabbitHolePromoDiagnosticTimeout") ? 15 : 55
    }

    init(model: GameViewModel) {
        self.model = model
    }

    func attach(_ arena: RabbitHoleArena) {
        guard !hasAttached else { return }
        hasAttached = true
        self.arena = arena
        arena.promoConfigureTwoFloorRun()
        arena.promoPrepareFloor(byPocket: PromoScript.firstFloorByPocket, isFinal: false)
        model.beginPromo(cards: 0, streak: 0, rounds: PromoScript.rounds)
        onReadyForCapture?()
    }

    /// Called after the exact-size AVAssetWriter has accepted its first
    /// session. The ordinary entrance is therefore frame one of the trailer.
    func start() {
        guard timer == nil, let arena else { return }
        startedAt = CACurrentMediaTime()
        enter(.entrance)
        // `beginPromo` publishes its first remaining-question set through
        // SwiftUI. That update may legitimately stock an idle arena before
        // capture begins, so arm the authored floor again at the exact reset
        // boundary that consumes it.
        arena.promoPrepareFloor(byPocket: PromoScript.firstFloorByPocket,
                                isFinal: false)
        arena.beginEntrance(completion: {})
        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func markCompletionFinished() {
        completionFinished = true
    }

    private func enter(_ phase: Phase) {
        self.phase = phase
        phaseStartedAt = CACurrentMediaTime()
        PromoAudioLog.record("phase:\(String(describing: phase))")
        if phase == .secondApproach, let arena {
            PromoAudioLog.record("items:\(arena.promoItemSummary)")
        }
    }

    private func switchCharacter(to id: String, next: Phase) {
        characterID = id
        transformationToken &+= 1
        enter(next)
    }

    private func tick() {
        guard let arena, !isFinished else { return }
        if elapsed > timeout, phase != .icon, phase != .done {
            PromoAudioLog.record("timeout:\(String(describing: phase))")
            revealIcon()
            return
        }

        switch phase {
        case .waitingForCapture:
            break

        case .entrance:
            if arena.mode == .swinging {
                enter(.firstApproach)
            }

        case .firstApproach:
            if phaseElapsed >= 0.65, arena.promoTapAnswer("15") {
                enter(.waitScore15)
            }

        case .waitScore15:
            if model.cards >= 1, arena.mode == .swinging {
                enter(.secondApproach)
            }

        case .secondApproach:
            if phaseElapsed >= 0.20, arena.promoTapAnswer("12") {
                enter(.waitWrong12)
            }

        case .waitWrong12:
            let twelveGone = !arena.items.contains {
                !$0.isDynamite && $0.isPresent && AnswerValue($0.text) == AnswerValue("12")
            }
            if twelveGone, arena.mode == .swinging {
                headline = PromoScript.headlineUnlock
                switchCharacter(to: "octopus", next: .octopusTransform)
            }

        case .octopusTransform:
            if phaseElapsed >= 0.55 { enter(.octopusApproach) }

        case .octopusApproach:
            if phaseElapsed >= 0.25, arena.promoTapAnswer("18") {
                enter(.waitScore18)
            }

        case .waitScore18:
            if model.cards >= 2, arena.mode == .swinging {
                switchCharacter(to: "frog", next: .frogTransform)
            }

        case .frogTransform:
            if phaseElapsed >= 0.55 { enter(.frogApproach) }

        case .frogApproach:
            if phaseElapsed >= 0.25, arena.promoTapAnswer("56") {
                enter(.waitScore56)
            }

        case .waitScore56:
            if model.cards >= 3, arena.mode == .swinging {
                switchCharacter(to: "penguin", next: .penguinTransform)
            }

        case .penguinTransform:
            if phaseElapsed >= 0.55 {
                arena.promoKeepOnly(answer: "52")
                headline = PromoScript.headlineDynamite
                showsDynamiteArrow = true
                enter(.warning)
            }

        case .warning:
            if phaseElapsed >= 2.0 {
                showsDynamiteArrow = false
                arena.promoPrepareFloor(byPocket: PromoScript.lowerFloorByPocket,
                                        isFinal: true)
                enter(.dynamiteApproach)
            }

        case .dynamiteApproach:
            if arena.promoTapDynamite() {
                headline = nil
                enter(.falling)
            }

        case .falling:
            if arena.floorIndex == 1, arena.mode == .swinging {
                switchCharacter(to: "bunny", next: .bunnyLandingTransform)
            }

        case .bunnyLandingTransform:
            if phaseElapsed >= 0.48 {
                arena.promoSetActionRate(1.65)
                enter(.rapid15)
            }

        case .rapid15:
            if phaseElapsed >= 0.18, arena.promoTapAnswer("15") {
                enter(.waitRapid15)
            }

        case .waitRapid15:
            if model.cards >= 4, arena.mode == .swinging {
                enter(.rapid18)
            }

        case .rapid18:
            if phaseElapsed >= 0.10, arena.promoTapAnswer("18") {
                enter(.waitRapid18)
            }

        case .waitRapid18:
            if model.cards >= 5, arena.mode == .swinging {
                enter(.rapid13)
            }

        case .rapid13:
            if phaseElapsed >= 0.10, arena.promoTapAnswer("13") {
                enter(.waitRapid13)
            }

        case .waitRapid13:
            if model.cards >= 6 {
                enter(.finale)
            }

        case .finale:
            if completionFinished {
                revealIcon()
            }

        case .icon:
            if phaseElapsed >= 2.35 {
                enter(.done)
            }

        case .done:
            isFinished = true
            stop()
        }
    }

    private func revealIcon() {
        guard phase != .icon, phase != .done else { return }
        // Promo sessions suppress the engine's early completion cue. Let the
        // icon become visibly established before the sound begins.
        headline = nil
        showsDynamiteArrow = false
        withAnimation(.easeOut(duration: 0.42)) {
            blursPlayfield = true
        }
        withAnimation(.spring(response: 0.72, dampingFraction: 0.78)) {
            showsIcon = true
        }
        enter(.icon)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            AppAudio.shared.playSessionComplete()
        }
    }
}
#endif

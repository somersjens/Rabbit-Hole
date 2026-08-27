#if DEBUG
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct PromoTrailerRoot: View {
    var body: some View {
        PromoTrailerView(format: PromoMode.format)
            .statusBarHidden(true)
            .onAppear {
                AppLayout.promoForcePad = PromoMode.format.isPad
                // The capture must never inherit the simulator or tester's
                // language. This routes both Text and code-resolved strings to
                // the English catalog before the first rendered frame.
                LanguageManager.shared.override = .english
                PromoCaptureController.shared.prepareAudio()
            }
    }
}

struct PromoTrailerView: View {
    let format: PromoFormat

    @StateObject private var model: GameViewModel
    @StateObject private var director: PromoDirector
    @State private var scoreCounterCenter: CGPoint?
    @State private var playsLevelCompletion = false
    @State private var showsFinale = false
    @State private var iconRotation: Double = -18
    @State private var iconScale: CGFloat = 0.46
    @State private var sampledTop: CGFloat = 0
    @State private var sampledBottom: CGFloat = 0
    @State private var transformGlow: Double = 0

    init(format: PromoFormat) {
        self.format = format
        let model = GameViewModel(request: PromoScript.sessionRequest)
        _model = StateObject(wrappedValue: model)
        _director = StateObject(wrappedValue: PromoDirector(model: model))
    }

    private var isPad: Bool { format.isPad }
    private var character: AnimalCharacter {
        CharacterCatalog.character(id: director.characterID)
    }
    private var controlSize: CGFloat { isPad ? 44 : 34 }
    private var hudStackHeight: CGFloat { controlSize * 2 + (isPad ? 8 : 6) }
    private var topInset: CGFloat { max(sampledTop, format.safeTop) }
    private var bottomInset: CGFloat { max(sampledBottom, format.safeBottom) }

    var body: some View {
        ZStack {
            LinearGradient(colors: [character.skyColor, character.tintColor],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            playfield
                .blur(radius: director.blursPlayfield ? 7 : 0)
                .animation(.easeOut(duration: 0.45), value: director.blursPlayfield)

            hud
                .opacity(showsFinale || director.showsIcon ? 0 : 1)
                .animation(.easeOut(duration: 0.22), value: showsFinale)

            if let headline = director.headline, !showsFinale, !director.showsIcon {
                PromoSpeechBubble(text: headline, character: character, isPad: isPad)
                    .padding(.horizontal, isPad ? 36 : 18)
                    .padding(.top, topInset + hudStackHeight + (isPad ? 24 : 18))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .top)))
                    .allowsHitTesting(false)
            }

            if transformGlow > 0.001, !director.showsIcon {
                RadialGradient(colors: [Color.white.opacity(0.88),
                                        character.color.opacity(0.38),
                                        .clear],
                               center: .center,
                               startRadius: 8,
                               endRadius: isPad ? 310 : 220)
                    .opacity(transformGlow)
                    .blendMode(.screen)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            if director.showsIcon { iconOverlay }
        }
        .ignoresSafeArea()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .currencyIcon(for: character)
        .statusBarHidden(true)
        .onChange(of: model.isGameOver) { isOver in
            if isOver, model.result.reason == .roundsCompleted {
                playsLevelCompletion = true
            }
        }
        .onChange(of: director.transformationToken) { _ in
            transformGlow = 1
            withAnimation(.easeOut(duration: 0.58)) { transformGlow = 0 }
        }
        .onChange(of: director.showsIcon) { showing in
            if showing {
                withAnimation(.spring(response: 0.76, dampingFraction: 0.82)) {
                    iconRotation = 0
                    iconScale = 1
                }
            }
        }
        .onChange(of: director.isFinished) { finished in
            if finished {
                Task { await PromoCaptureController.shared.finish() }
            }
        }
        .onPreferenceChange(ScoreCounterCenterPreferenceKey.self) { center in
            if let center { scoreCounterCenter = center }
        }
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        sampledTop = proxy.safeAreaInsets.top
                        sampledBottom = proxy.safeAreaInsets.bottom
                    }
                    .onChange(of: proxy.safeAreaInsets.top) { sampledTop = $0 }
                    .onChange(of: proxy.safeAreaInsets.bottom) { sampledBottom = $0 }
            }
        }
        .persistentSystemOverlays(.hidden)
    }

    private var playfield: some View {
        RabbitHolePlayfield(round: model.round,
                            remainingQuestions: model.remainingQuestions,
                            mistakeCount: model.rabbitHoleMistakes,
                            resumeFloorState: nil,
                            missedSum: nil,
                            maximumRounds: model.maximumRounds,
                            character: character,
                            isPad: isPad,
                            isLive: model.acceptsInput,
                            isRunning: true,
                            playsKingEntrance: false,
                            isStreakBoostActive: false,
                            playsLevelCompletion: playsLevelCompletion,
                            reduceMotion: false,
                            reservesTutorialMessage: true,
                            showsPromoDynamiteArrow: director.showsDynamiteArrow,
                            topReserve: topInset + hudStackHeight + (isPad ? 18 : 12),
                            bottomReserve: bottomInset,
                            scoreTarget: scoreCounterCenter,
                            onCorrect: { model.select(optionID: $0) },
                            onWrong: model.missCarrot,
                            onDynamiteMistake: model.missDynamite,
                            onFloorStateChanged: { _ in },
                            onFinalFloorCleared: {},
                            onTimeout: model.endByTimeout,
                            onExtensionStarted: model.rabbitHoleExtensionStarted,
                            onItemContact: model.rabbitHoleItemContact,
                            onShellArrived: model.scoreBubbleArrived,
                            onKingEntranceComplete: {},
                            onLevelCompletionStarted: { showsFinale = true },
                            onLevelCompletionFinished: director.markCompletionFinished,
                            onPromoArenaReady: { arena in
                                director.attach(arena)
                                beginCaptureWhenReady()
                            })
            .ignoresSafeArea()
    }

    private var hud: some View {
        HStack(alignment: .top, spacing: isPad ? 12 : 8) {
            VStack(spacing: isPad ? 8 : 6) {
                Circle()
                    .fill(character.deepColor)
                    .frame(width: controlSize, height: controlSize)
                    .overlay { FilledPauseGlyph(isPad: isPad) }

                ZStack {
                    Circle().fill(RabbitHoleHUDStyle.questionInterior)
                    Text(verbatim: LN(model.cards))
                        .font(.system(size: isPad ? 28 : 21,
                                      weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(character.deepColor)
                        .modifier(PromoNumericCountTransition(value: Double(model.cards)))
                }
                .frame(width: controlSize, height: controlSize)
                .background {
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: ScoreCounterCenterPreferenceKey.self,
                            value: CGPoint(x: proxy.frame(in: .global).midX,
                                           y: proxy.frame(in: .global).midY)
                        )
                    }
                }
            }

            RabbitHoleQuestionBanner(prompt: model.round?.question.prompt ?? "",
                                     roundID: model.round?.id,
                                     accent: character.color,
                                     deep: character.deepColor,
                                     isPad: isPad)
                .frame(maxWidth: .infinity)
                .frame(height: hudStackHeight)
        }
        .padding(.leading, isPad ? 28 : 16)
        .padding(.trailing, isPad ? 28 : 16)
        .padding(.top, topInset + (isPad ? 12 : 6))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .allowsHitTesting(false)
    }

    private var iconOverlay: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height) * (isPad ? 0.43 : 0.50)
            ZStack {
                Color.black.opacity(0.12)
                Image("app_icon_trailer")
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: side, height: side)
                    .clipShape(RoundedRectangle(cornerRadius: side * 0.2237,
                                                style: .continuous))
                    .shadow(color: .black.opacity(0.34), radius: 22, y: 14)
                    .rotationEffect(.degrees(iconRotation))
                    .scaleEffect(iconScale)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func beginCaptureWhenReady() {
#if canImport(UIKit)
        DispatchQueue.main.async {
            guard let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap(\.windows)
                .first(where: \.isKeyWindow) else { return }
            PromoCaptureController.shared.start(view: window,
                                                format: format,
                                                onStarted: director.start)
        }
#endif
    }
}

private struct PromoSpeechBubble: View {
    let text: String
    let character: AnimalCharacter
    let isPad: Bool

    var body: some View {
        Text(verbatim: text)
            .font(.system(size: isPad ? 22 : 16, weight: .heavy, design: .rounded))
            .multilineTextAlignment(.center)
            .foregroundStyle(character.deepColor)
            .padding(.horizontal, isPad ? 22 : 16)
            .padding(.vertical, isPad ? 14 : 10)
            .frame(maxWidth: isPad ? 560 : 360)
            .background {
                RoundedRectangle(cornerRadius: isPad ? 22 : 18, style: .continuous)
                    .fill(.white.opacity(0.96))
                    .shadow(color: .black.opacity(0.22), radius: 10, y: 4)
            }
            .overlay {
                RoundedRectangle(cornerRadius: isPad ? 22 : 18, style: .continuous)
                    .stroke(character.deepColor.opacity(0.18), lineWidth: 1.5)
            }
    }
}

private struct PromoNumericCountTransition: ViewModifier {
    let value: Double
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.contentTransition(.numericText(value: value))
        } else {
            content.contentTransition(.numericText())
        }
    }
}
#endif

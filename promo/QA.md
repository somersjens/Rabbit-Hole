# Rabbit Hole App Store teaser — final QA

## Deliverables

| Format | File | Final media metadata | Full decode |
| --- | --- | --- | --- |
| iPhone | `final/rabbit-hole-app-store-teaser-886x1920.mp4` | 886×1920, H.264 (`avc1`), 30.000 fps, AAC, 24.707 s | 742 video frames + 49 audio packets, completed |
| iPad | `final/rabbit-hole-app-store-teaser-1200x1600.mp4` | 1200×1600, H.264 (`avc1`), 30.000 fps, AAC, 25.843 s | 776 video frames + 51 audio packets, completed |

Both captures' `ready.json` and `done.json` report `language: en`. The app also sets the
promo language override before the first captured frame.

## Production systems reused

- `RabbitHoleArena`: entrance, normal hook swing/drop/contact/wriggle/raise/toss,
  wrong carrot, score flight, both explosions, shaft fall, particles, and upward finale.
- `RabbitHolePlayfield`: production environment layers, character/excavator rigs,
  carrot and dynamite art, terrain, shaft, shake, flash, and particles.
- `GameViewModel` / `MemoryGame`: question persistence after wrong `12`, exact round
  progression, pending score rewards, and score update only when the carrot reaches the HUD.
- Production Bunny, Octopus, Frog, Penguin themes and `app_icon_trailer`.
- Production `music_background.m4a` and production hook/contact/correct/wrong/score,
  explosion, and completion effects. Audio was rebuilt offline from gameplay cue timestamps
  because Simulator hardware screen recording contains no app-audio track. The music is one
  uninterrupted normal-rate track at 0.45 mix volume (apart from its opening/closing fades),
  so the accelerated lower-floor action does not accelerate or pitch-shift the music. The AAC
  tracks measure −19.06 dBFS RMS (iPhone) and −19.02 dBFS RMS (iPad), with music present in
  every five-second analysis window.

## Deterministic sequence verification

- First floor: `15` correct; `12` wrong while `26 − 8` remains active; then `18` and `56`.
- Trailer-only orchestration resumes the ordinary swing as soon as a correct pickup reaches
  the retracted top part, while its independent score flight continues. The question and score
  still advance only on HUD arrival. The next action begins 0.265 s after the first score;
  following the Octopus score and Frog change, `56` begins 0.816 s later on iPhone.
- A held answer is drawn in front of the excavator/character. This z-order correction also
  applies to normal gameplay; the `18` shell no longer passes behind the main character.
- Only Bunny→Octopus receives a 0.22 s light flash and exactly one production character-unlock
  sound. Frog, Penguin, and the return to Bunny receive neither effect.
- After `56`, all remaining first-floor holes, `13`, `52`, `48`, and the real dynamite stay
  untouched while the warning appears; the Penguin then deliberately collects the dynamite.
  The entire former `36 + 12` round remains absent.
- Warning duration is 2.016 s on iPhone and 2.000 s on iPad. The arrow is the same red as
  the dynamite body.
- The Penguin begins falling, changes to Bunny mid-flight, and only then reveals the new
  floor. That floor displays carrots from its first visible frame—never Penguin fish.
- Lower floor sequence is exactly `15`, `18`, `13`; only this section uses the 1.65×
  arena action rate. The action rate resets before the final production explosion/finale.
- The final explosion may begin while the last score pickup is still flying; that pickup remains
  preserved, reaches the HUD, and only then releases the upward finale.
- Normal result UI is suppressed only in DEBUG promo mode; the exact trailer icon appears
  after the production completion callback. The completion sound begins 0.300 s after icon
  animation start, when the rounded app icon is already visibly established.

Representative iPhone timestamps: first action 1.590; first score 2.940; wrong-answer
action 3.206; unlock flash/sound 4.306; Octopus action 5.822 and score 7.174; Frog action
7.990 and score 9.324; warning 9.890–11.906; Penguin dynamite action 12.372;
explosion 12.508; Bunny mid-flight 13.322; landing 14.306; rapid scores 17.507, 19.840,
21.140; final explosion 20.541; icon animation 22.327; completion sound 22.633.

Representative iPad timestamps: first score 3.076; wrong-answer action 3.340;
unlock flash/sound 4.440; Octopus score 7.642; Frog action 8.490 and score 9.826;
warning 10.407–12.407; Penguin dynamite action 12.923; explosion 13.043;
Bunny mid-flight 14.187; landing 15.340; rapid scores 18.593, 20.926, 22.259;
final explosion 21.643; icon animation 23.463; completion sound 23.772.

## Visual inspection

Thirty-five exact frames were extracted from each final MP4. The two contact sheets cover:

- first frame and Bunny entrance;
- all six questions, approaches, grabs, flights, and score handoffs;
- wrong `12` pickup and persistent `26 − 8`;
- the single short Bunny→Octopus flash and every later unflashed character/environment change;
- the `18` shell in front of the excavator during its carry;
- the unchanged first-floor pickups throughout the warning, red arrow, Penguin dynamite
  approach, explosion, mid-flight Bunny change, and carrot-only lower-floor reveal;
- all three accelerated grabs and scores;
- final explosion, upward launch, icon entry, and settled icon.

Contact sheets:

- `preview-frames/iphone-final/contact-sheet.jpg`
- `preview-frames/ipad-final/contact-sheet.jpg`

No text/target overlap, clipped launch, hard floor cut, result-screen flash, black transition,
or blurred icon was found. iPhone and iPad were rendered from independent responsive layouts,
not derived from one another.

## Build verification

Normal non-promo Release build passed:

```text
xcodebuild -project "Rabbit Hole.xcodeproj" -scheme "Rabbit Hole" \
  -configuration Release -sdk iphonesimulator \
  -derivedDataPath /tmp/rabbit-hole-release-derived \
  CODE_SIGNING_ALLOWED=NO build
** BUILD SUCCEEDED **
```

## Intentional trailer-only addition

Rabbit Hole has a production tutorial dynamite shield and dotted hook guide, but no production
warning arrow. Per the brief's fallback, DEBUG promo mode adds one red downward arrow that
tracks the real dynamite. No gameplay object or explosion was recreated.

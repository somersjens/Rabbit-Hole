# Rabbit Hole App Store teaser — final QA

## Deliverables

| Format | File | Final media metadata | Full decode |
| --- | --- | --- | --- |
| iPhone | `final/rabbit-hole-app-store-teaser-886x1920.mp4` | 886×1920, H.264 (`avc1`), 30.000 fps, AAC, 24.360 s | 731 video frames + 48 audio packets, completed |
| iPad | `final/rabbit-hole-app-store-teaser-1200x1600.mp4` | 1200×1600, H.264 (`avc1`), 30.000 fps, AAC, 23.725 s | 712 video frames + 47 audio packets, completed |

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
  tracks measure −18.94 dBFS RMS (iPhone) and −18.88 dBFS RMS (iPad), with music present in
  every five-second analysis window.

## Deterministic sequence verification

- First floor: `15` correct; `12` wrong while `26 − 8` remains active; then `18` and `56`.
  The Octopus `18` occupies the former `13` pocket, while `13` occupies the former `18`
  pocket. This gives Octopus a longer natural approach and Frog a shorter one.
- Trailer-only orchestration resumes the ordinary swing as soon as a correct pickup reaches
  the retracted top part, while its independent score flight continues. The question and score
  still advance only on HUD arrival. Score arrival never calls the old swing-resume path a
  second time, so the phase and hook position stay continuous through every character switch
  and accelerated pickup.
- A fresh entrance explicitly resets the swing clock. The first 0.18 s of the opening swing has
  a trailer-only velocity ramp, removing the missing-frame impression as the top part leaves
  the centre position toward `15`.
- A held answer is drawn in front of the excavator/character. This z-order correction also
  applies to normal gameplay; the `18` shell no longer passes behind the main character.
- Only Bunny→Octopus receives a 0.22 s light flash and exactly one production character-unlock
  sound. There is no additional approach hold after the dissolve; the ordinary swing continues
  toward the relocated `18` lane. Frog, Penguin, and the return to Bunny receive neither effect.
- After `56`, all remaining first-floor holes, `13`, `52`, `48`, and the real dynamite stay
  untouched while the warning appears; the Penguin then deliberately collects the dynamite.
  The entire former `36 + 12` round remains absent.
- The warning remains visible until the naturally swinging Penguin reaches the dynamite:
  1.850 s on iPhone and 1.867 s on iPad. The arrow is the same red as the dynamite body.
- The Penguin begins falling and changes to Bunny later in mid-flight (48% fall progress).
  The outgoing Penguin dissolves over 0.18 s while Bunny is already fully present underneath;
  this overlapping construction prevents an empty-character frame. Their background palettes
  cross-dissolve over the same beat. The new floor displays carrots from its first visible
  frame—never Penguin fish.
- Lower floor sequence is exactly `15`, `18`, `13`. The carrots are positioned along the real
  swing route: centre-left, far left, then one lane back to the right. The trailer uses the same
  production catch-angle requirement as gameplay and cannot steer or force an out-of-range
  pickup. Only this section uses the 1.65× arena action rate. The extension intervals are 1.084 s
  and 1.350 s on iPhone, and 0.950 s and 1.300 s on iPad. Each extension and item-contact sound
  is recorded on its corresponding action callback; dense frame inspection found no hook reset
  at either intervening score arrival. The action rate resets before the final production
  explosion/finale.
- The final explosion may begin while the last score pickup is still flying; that pickup remains
  preserved, reaches the HUD, and only then releases the upward finale.
- The final carrot's contact/correct transients are delayed by 0.07 s in the offline mix, placing
  them on the first frame where the claw is visibly latched (19.37 s iPhone / 18.80 s iPad).
  After the claw returns home, the normal swing continues for another 0.50 s before detonation.
  The measured visible contact-to-explosion gaps are 0.701 s and 0.734 s respectively.
- Normal result UI is suppressed only in DEBUG promo mode; the exact trailer icon appears
  after the production completion callback. The completion sound begins 0.302 s (iPhone) /
  0.310 s (iPad) after icon animation start, when the rounded app icon is visibly established.
  Its post-production mix gain is 0.22 instead of 0.10 (about +6.8 dB), so it remains clear
  above the uninterrupted music.

Representative iPhone timestamps: first action 1.858; first score 3.383; wrong-answer
action 4.075; unlock flash/sound 5.374; Octopus action 6.641 and score 8.049; Frog action
9.691 and score 11.233; warning 11.807–13.691; Penguin dynamite action 13.691;
explosion 13.834; Bunny mid-flight dissolve 15.779; landing 16.624; rapid extension starts
16.757, 17.841, 19.191; rapid scores 17.749, 18.749, 20.088; final explosion 20.000;
icon animation 21.983; completion sound 22.299.

Representative iPad timestamps: first score 3.414; wrong-answer action 4.107;
unlock flash/sound 5.424; Octopus action 6.691 and score 8.114; Frog action 9.774 and
score 11.130; warning 11.707–13.607; Penguin dynamite action 13.607; explosion 13.731;
Bunny mid-flight dissolve 15.505; landing 16.243; rapid extension starts 16.374,
17.324, 18.624; rapid scores 17.247, 18.197, 19.564; final explosion 19.464;
icon animation 21.362; completion sound 21.686.

## Visual inspection

Dense exact-frame sequences were extracted from both final MP4s. The contact sheets cover:

- first frame and Bunny entrance;
- all six questions, approaches, grabs, flights, and score handoffs;
- wrong `12` pickup and persistent `26 − 8`;
- the single short Bunny→Octopus flash and every later unflashed character/environment change;
- the `18` shell in front of the excavator during its carry;
- the unchanged first-floor pickups throughout the warning, red arrow, Penguin dynamite
  approach, explosion, gap-free overlapping mid-flight Bunny change, and carrot-only
  lower-floor reveal;
- the uninterrupted score-arrival swing frames, all three naturally aligned accelerated grabs and scores,
  and their matching extension/contact cues;
- the final carrot's corrected audio frame, the half-second post-return swing, final explosion,
  upward launch, icon entry, and settled icon.

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

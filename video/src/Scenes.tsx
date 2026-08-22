import React from 'react';
import {
  AbsoluteFill,
  Easing,
  Img,
  interpolate,
  spring,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from 'remotion';
import {Cursor, GuideCaption, ProgressRail, SceneTitle, Shortcut, fadeIn, riseIn} from './components/GuidePrimitives';
import {MacDesktop} from './components/MacDesktop';
import {SeihitsuHUD} from './components/SeihitsuHUD';
import {RedSeal, SumiEAtmosphere} from './components/SumiE';
import {fonts, palette, shadow} from './theme';

const Backdrop: React.FC<{children: React.ReactNode; variant?: number}> = ({children, variant = 0}) => (
  <AbsoluteFill
    style={{
      overflow: 'hidden',
      background:
        'radial-gradient(circle at 15% 9%, rgba(174,151,126,0.12), transparent 29%), radial-gradient(circle at 80% 73%, rgba(126,43,43,0.13), transparent 35%), radial-gradient(ellipse at 50% 112%, rgba(125,110,94,0.12), transparent 43%), linear-gradient(150deg,#080706 0%,#15120f 57%,#090807 100%)',
    }}
  >
    <SumiEAtmosphere variant={variant} />
    <div style={{position: 'absolute', inset: 0, zIndex: 1}}>{children}</div>
  </AbsoluteFill>
);

export const IntroScene: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const calligraphy = spring({frame: frame - 55, fps, config: {damping: 200}});
  return (
    <Backdrop variant={0}>
      <div
        style={{
          position: 'absolute',
          inset: 0,
          zIndex: 70,
          opacity: interpolate(frame, [0, 40, 74], [1, 1, 0], {
            extrapolateLeft: 'clamp',
            extrapolateRight: 'clamp',
            easing: Easing.inOut(Easing.cubic),
          }),
          transform: `scale(${interpolate(frame, [0, 74], [1, 1.035], {
            extrapolateLeft: 'clamp',
            extrapolateRight: 'clamp',
          })})`,
        }}
      >
        <div style={{position: 'absolute', inset: 0, background: '#0a0908'}} />
        <Img
          src={staticFile('kyze-banner-technology.png')}
          style={{position: 'absolute', inset: 0, width: '100%', height: '100%', objectFit: 'contain'}}
        />
        <div style={{position: 'absolute', inset: 0, background: 'linear-gradient(90deg,rgba(5,4,3,0.15),transparent 42%,rgba(5,4,3,0.18))'}} />
      </div>
      <div
        style={{
          position: 'absolute',
          left: 150,
          top: 185,
          width: 210,
          height: 570,
          opacity: calligraphy * 0.72,
          transform: `translateY(${(1 - calligraphy) * 46}px)`,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          color: 'rgba(222,206,183,0.72)',
          fontFamily: fonts.sans,
          fontWeight: 800,
          fontSize: 112,
          lineHeight: 0.9,
          writingMode: 'vertical-rl',
          textShadow: '0 18px 44px rgba(0,0,0,0.65)',
        }}
      >
        静謐司令
      </div>
      <div
        style={{
          position: 'absolute',
          left: 360,
          top: 150,
          width: 7,
          height: 650 * calligraphy,
          opacity: 0.48,
          transform: 'rotate(1.2deg)',
          transformOrigin: 'top',
          background: 'linear-gradient(#b74343,rgba(183,67,67,0.24),transparent)',
          clipPath: 'polygon(30% 0,100% 3%,58% 100%,0 96%)',
        }}
      />
      <div style={{position: 'absolute', left: 470, right: 150, top: 245}}>
        <SceneTitle
          eyebrow="Seihitsu Shirei · 静謐司令"
          title="Quiet AI help, right where you work."
          detail="A simple guide to asking, highlighting, reading, and speaking—without leaving your current app."
          delay={52}
        />
      </div>
      <div
        style={{
          position: 'absolute',
          left: 474,
          top: 655,
          display: 'flex',
          gap: 12,
          alignItems: 'center',
          opacity: fadeIn(frame, fps, 78),
          color: palette.cyanSoft,
          fontFamily: fonts.mono,
          fontSize: 19,
        }}
      >
        <RedSeal text="静" size={28} />
        User guide + live-style demo
      </div>
    </Backdrop>
  );
};

const SettingsPanel: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const p = spring({frame: frame - 16, fps, config: {damping: 200}});
  const fields = [
    ['OpenRouter API key', 'current default provider', true],
    ['Claude Code token', 'optional', false],
    ['OpenAI API key', 'optional', false],
  ] as const;
  const permissions = [
    ['Accessibility', 'highlight-to-act (⌥C)'],
    ['Microphone', 'voice input (⌥L)'],
    ['Screen Recording', 'read screen (⌥V)'],
  ] as const;
  return (
    <div
      style={{
        position: 'absolute',
        right: 120,
        top: 90,
        width: 730,
        height: 810,
        padding: '34px 38px',
        borderRadius: 7,
        background:
          'radial-gradient(circle at 14% 8%,rgba(255,255,255,0.35),transparent 24%),linear-gradient(145deg,#e9e0d1,#d7ccbb)',
        color: '#2c241e',
        boxShadow: shadow,
        border: '1px solid rgba(78,60,47,0.42)',
        fontFamily: fonts.sans,
        opacity: p,
        transform: `translateX(${(1 - p) * 46}px)`,
      }}
    >
      <div style={{fontSize: 30, fontWeight: 760}}>Credentials</div>
      <div style={{fontSize: 17, color: '#695f57', marginTop: 8}}>
        Stored in the macOS Keychain. Fields clear after saving.
      </div>
      <div style={{marginTop: 25, display: 'flex', flexDirection: 'column', gap: 18}}>
        {fields.map(([name, note, set]) => (
          <div key={name}>
            <div style={{display: 'flex', fontSize: 17, fontWeight: 680}}>
              {name}
              {set ? <span style={{color: '#15955d', marginLeft: 9}}>● set</span> : null}
              <span style={{flex: 1}} />
              <span style={{fontWeight: 500, color: '#74685f', fontSize: 14}}>{note}</span>
            </div>
            <div
              style={{
                height: 43,
                marginTop: 7,
                padding: '0 14px',
                borderRadius: 3,
                border: '1px solid rgba(77,61,49,0.3)',
                background: 'rgba(248,243,235,0.72)',
                display: 'flex',
                alignItems: 'center',
                color: set ? '#5b6670' : '#a1a9af',
                fontFamily: fonts.mono,
                fontSize: 16,
              }}
            >
              {set ? '••••••••  (saved)' : 'paste here'}
            </div>
          </div>
        ))}
      </div>
      <button
        style={{
          marginTop: 22,
          border: 0,
          borderRadius: 2,
          padding: '10px 21px',
          background: '#a43d3d',
          color: 'white',
          fontSize: 17,
          fontWeight: 700,
        }}
      >
        Save
      </button>
      <div style={{height: 4, background: 'linear-gradient(90deg,#312820,rgba(49,40,32,0.2),transparent)', clipPath: 'polygon(0 35%,100% 0,96% 100%,0 72%)', margin: '28px 0 22px', opacity: 0.35}} />
      <div style={{fontSize: 30, fontWeight: 760}}>Permissions</div>
      <div style={{marginTop: 13, display: 'flex', flexDirection: 'column', gap: 13}}>
        {permissions.map(([name, note], i) => {
          const granted = frame > 90 + i * 14;
          return (
            <div key={name} style={{display: 'flex', alignItems: 'center', height: 46}}>
              <span style={{fontSize: 22, color: granted ? '#1aa469' : '#e59a14'}}>{granted ? '●' : '○'}</span>
              <div style={{marginLeft: 12}}>
                <div style={{fontSize: 17, fontWeight: 700}}>{name}</div>
                <div style={{fontSize: 14, color: '#74685f'}}>{note}</div>
              </div>
              <span style={{flex: 1}} />
              <div style={{padding: '7px 14px', border: '1px solid rgba(77,61,49,0.3)', borderRadius: 2, background: 'rgba(248,243,235,0.7)'}}>Open</div>
            </div>
          );
        })}
      </div>
    </div>
  );
};

export const SetupScene: React.FC = () => (
  <Backdrop variant={1}>
    <ProgressRail scene={2} />
    <div style={{position: 'absolute', left: 100, top: 220, width: 800}}>
      <SceneTitle
        eyebrow="One-time setup"
        title="Connect one AI provider."
        detail="Open Settings from the brain icon, paste your key, and allow only the features you plan to use."
      />
      <div style={{marginTop: 48, color: palette.muted, fontFamily: fonts.sans, fontSize: 23, lineHeight: 1.55}}>
        <span style={{color: palette.green, fontWeight: 800}}>●</span> Your key is kept in macOS Keychain.
        <br />
        <span style={{color: palette.green, fontWeight: 800}}>●</span> Permission prompts should appear only once.
      </div>
    </div>
    <SettingsPanel />
    <GuideCaption step="1">Click the brain icon → <b>Settings…</b> → paste your provider key → <b>Save</b>.</GuideCaption>
  </Backdrop>
);

export const AskScene: React.FC = () => {
  const frame = useCurrentFrame();
  const question = 'Give me three priorities for this launch.';
  return (
    <AbsoluteFill>
      <MacDesktop title="Launch plan" variant={0}>
        <SeihitsuHUD
          prompt={question}
          answer={'1. Confirm the venue\n2. Finalise the guest list\n3. Send invitations'}
          status="Done"
          visibleAt={26}
          typing
        />
      </MacDesktop>
      <ProgressRail scene={3} />
      <div style={{position: 'absolute', left: 105, top: 75, opacity: interpolate(frame, [0, 25], [1, 0], {extrapolateRight: 'clamp'})}}>
        <Shortcut keys="⌥+Space" active />
      </div>
      <GuideCaption step="2" shortcut="⌥+Space" delay={10}>
        Show the panel, type a question, then press <b>Return</b>.
      </GuideCaption>
    </AbsoluteFill>
  );
};

export const HighlightScene: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const showHud = frame >= 86;
  return (
    <AbsoluteFill>
      <MacDesktop title="Planning notes" highlight="What is the capital of Japan?" variant={1}>
        {showHud ? (
          <SeihitsuHUD
            prompt="What is the capital of Japan?"
            answer="Tokyo."
            status="Done"
            visibleAt={86}
          />
        ) : null}
      </MacDesktop>
      <ProgressRail scene={4} />
      <div
        style={{
          position: 'absolute',
          right: 190,
          top: 70,
          display: 'flex',
          alignItems: 'center',
          gap: 20,
          opacity: fadeIn(frame, fps, 42),
        }}
      >
        <span style={{fontFamily: fonts.sans, color: palette.text, fontSize: 24, fontWeight: 680}}>Highlight a question</span>
        <span style={{color: palette.faint, fontSize: 24}}>→</span>
        <Shortcut keys="⌥+C" active={frame >= 64} />
      </div>
      <GuideCaption step="3" shortcut="⌥+C" delay={10}>
        Highlight a question in any app. Seihitsu answers it without copy-and-paste.
      </GuideCaption>
    </AbsoluteFill>
  );
};

export const ReadScreenScene: React.FC = () => {
  const frame = useCurrentFrame();
  const choosing = frame < 112;
  return (
    <AbsoluteFill>
      <MacDesktop appName="Training" title="Training quiz" quiz showRegion={choosing} variant={2}>
        {!choosing ? (
          <SeihitsuHUD
            prompt="Read from selected screen area"
            answer="C — £48"
            status="Done"
            mode="Brief"
            visibleAt={112}
          />
        ) : null}
      </MacDesktop>
      <ProgressRail scene={5} />
      <GuideCaption step="4" shortcut="⌥+V" delay={8}>
        For text you cannot select, set the read area once—then press Option-V.
      </GuideCaption>
      {choosing ? <Cursor from={[400, 430]} to={[1100, 610]} start={36} end={74} clickAt={74} /> : null}
    </AbsoluteFill>
  );
};

const Waveform: React.FC = () => {
  const frame = useCurrentFrame();
  return (
    <div style={{display: 'flex', alignItems: 'center', gap: 7, height: 68}}>
      {Array.from({length: 16}, (_, i) => {
        const height = 14 + Math.abs(Math.sin(frame * 0.18 + i * 0.7)) * 46;
        return <div key={i} style={{width: 6, height, borderRadius: 99, background: i % 3 === 0 ? palette.purple : palette.cyan}} />;
      })}
    </div>
  );
};

export const VoiceScene: React.FC = () => {
  const frame = useCurrentFrame();
  const listening = frame < 130;
  const transcript = 'What should I focus on first today?';
  return (
    <AbsoluteFill>
      <MacDesktop title="Today" variant={0}>
        <SeihitsuHUD
          prompt={transcript}
          answer="Finish the client proposal first, then review email."
          status={listening ? 'Listening…' : 'Done'}
          listening={listening}
          visibleAt={10}
          typing={listening}
        />
        <div
          style={{
            position: 'absolute',
            left: 300,
            top: 400,
            padding: '26px 34px',
            borderRadius: 24,
            background: 'rgba(18,15,13,0.92)',
            border: '1px solid rgba(255,255,255,0.13)',
            boxShadow: shadow,
            zIndex: 25,
            opacity: frame < 150 ? 1 : interpolate(frame, [150, 175], [1, 0], {extrapolateRight: 'clamp'}),
          }}
        >
          <Waveform />
          <div style={{fontFamily: fonts.sans, color: 'white', fontSize: 22, marginTop: 8}}>
            {listening ? 'Listening… speak naturally' : 'Question captured'}
          </div>
        </div>
      </MacDesktop>
      <ProgressRail scene={6} />
      <GuideCaption step="5" shortcut="⌥+L" delay={8}>
        Prefer to speak? Option-L starts listening. Your words appear, then the answer follows.
      </GuideCaption>
    </AbsoluteFill>
  );
};

export const SpeedScene: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const mode = frame < 70 ? 'Full' : frame < 135 ? 'Brief' : 'Blitz';
  const answer = mode === 'Full'
    ? 'Mars is known as the Red Planet because iron minerals on its surface oxidise.'
    : mode === 'Brief'
      ? 'Mars—the surface looks red because of iron oxide.'
      : 'B — Mars';
  return (
    <AbsoluteFill>
      <MacDesktop appName="Quiz" title="Timed question" quiz quizVariant="planet" variant={1}>
        <div
          style={{
            position: 'absolute',
            left: 1010,
            top: 80,
            width: 145,
            height: 66,
            borderRadius: 18,
            background: 'rgba(251,113,133,0.95)',
            color: 'white',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontFamily: fonts.mono,
            fontWeight: 800,
            fontSize: 26,
            boxShadow: shadow,
            zIndex: 25,
          }}
        >
          00:{String(Math.max(1, 9 - Math.floor(frame / fps))).padStart(2, '0')}
        </div>
        <SeihitsuHUD
          prompt="Which planet is known as the Red Planet?"
          answer={answer}
          status={`Done · ${mode}`}
          mode={mode}
          visibleAt={8}
        />
      </MacDesktop>
      <ProgressRail scene={7} />
      <GuideCaption step="6" shortcut="⌥+⇧S" delay={6}>
        Choose Full, Brief, or Blitz. Blitz returns only the answer when time is short.
      </GuideCaption>
    </AbsoluteFill>
  );
};

const PrivacyCard: React.FC<{
  label: string;
  hud: boolean;
  note: string;
  delay: number;
}> = ({label, hud, note, delay}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const p = spring({frame: frame - delay, fps, config: {damping: 200}});
  return (
    <div
      style={{
        width: 760,
        opacity: p,
        transform: `translateY(${(1 - p) * 28}px)`,
      }}
    >
      <div style={{fontFamily: fonts.mono, color: hud ? palette.cyan : palette.green, fontSize: 18, fontWeight: 800, letterSpacing: 2}}>
        {label}
      </div>
      <div
        style={{
          position: 'relative',
          height: 420,
          marginTop: 14,
          borderRadius: 8,
          overflow: 'hidden',
          border: '1px solid rgba(255,255,255,0.14)',
          boxShadow: shadow,
          background: 'linear-gradient(145deg,#3a342f,#171411)',
        }}
      >
        <div style={{position: 'absolute', left: 50, top: 65, width: 430, height: 290, borderRadius: 4, background: '#f1f0eb'}}>
          <div style={{height: 42, background: '#dedcd5'}} />
          <div style={{padding: 32, fontFamily: fonts.sans, color: '#26343d'}}>
            <b style={{fontSize: 23}}>Planning notes</b>
            <div style={{fontSize: 17, lineHeight: 1.5, marginTop: 20}}>What is the capital of Japan?</div>
          </div>
        </div>
        {hud ? (
          <div
            style={{
              position: 'absolute',
              right: 32,
              top: 88,
              width: 320,
              height: 230,
              borderRadius: 6,
              background: 'rgba(20,17,14,0.94)',
              border: '1px solid rgba(183,67,67,0.48)',
              boxShadow: shadow,
              padding: 20,
              fontFamily: fonts.mono,
              color: 'white',
            }}
          >
            <span style={{color: palette.cyan}}>◉</span> Ask…
            <div style={{height: 1, background: 'rgba(255,255,255,0.13)', margin: '18px 0'}} />
            <div style={{fontSize: 11, color: '#8b9aa5'}}>ANSWER</div>
            <div style={{fontSize: 20, marginTop: 18}}>Tokyo.</div>
          </div>
        ) : (
          <div
            style={{
              position: 'absolute',
              right: 64,
              top: 150,
              padding: '13px 18px',
              borderRadius: 3,
              color: palette.green,
              background: 'rgba(103,232,162,0.12)',
              border: '1px solid rgba(103,232,162,0.32)',
              fontFamily: fonts.mono,
              fontWeight: 700,
            }}
          >
            HUD excluded
          </div>
        )}
      </div>
      <div style={{fontFamily: fonts.sans, color: palette.muted, fontSize: 21, lineHeight: 1.4, marginTop: 18}}>{note}</div>
    </div>
  );
};

export const PrivacyScene: React.FC = () => (
  <Backdrop variant={2}>
    <ProgressRail scene={8} />
    <div style={{position: 'absolute', left: 0, right: 0, top: 55}}>
      <SceneTitle
        eyebrow="Private by design"
        title="Visible to you. Left out of ordinary capture."
        detail="The HUD uses macOS capture exclusion where the active screenshot or sharing path supports it."
        align="center"
      />
    </div>
    <div style={{position: 'absolute', left: 135, right: 135, top: 340, display: 'flex', justifyContent: 'space-between'}}>
      <PrivacyCard label="WHAT YOU SEE" hud note="The floating answer stays on your screen while you work." delay={20} />
      <PrivacyCard label="WHAT YOU SHARE" hud={false} note="OCR happens on your Mac; only recognised text is sent to your chosen AI provider." delay={36} />
    </div>
  </Backdrop>
);

const ShortcutRow: React.FC<{shortcut: string; label: string; delay: number}> = ({shortcut, label, delay}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const style = riseIn(frame, fps, delay);
  return (
    <div style={{...style, display: 'flex', alignItems: 'center', gap: 20}}>
      <Shortcut keys={shortcut} />
      <span style={{fontFamily: fonts.sans, color: palette.text, fontSize: 23}}>{label}</span>
    </div>
  );
};

export const RecapScene: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  return (
    <Backdrop variant={0}>
      <Img
        src={staticFile('kyze-banner-technology.png')}
        style={{position: 'absolute', inset: 0, width: '100%', height: '100%', objectFit: 'cover', opacity: 0.085, filter: 'grayscale(0.25) contrast(1.12)'}}
      />
      <ProgressRail scene={9} />
      <div style={{position: 'absolute', left: 178, top: 176}}>
        <RedSeal text="静" size={146} />
        <div style={{marginTop: 20, color: palette.cyanSoft, fontFamily: fonts.mono, fontSize: 18, letterSpacing: 8}}>
          KYZE
        </div>
      </div>
      <div style={{position: 'absolute', left: 410, top: 170, width: 980}}>
        <SceneTitle
          eyebrow="You are ready"
          title="Four shortcuts. One quiet copilot."
          detail="Use the brain icon whenever you forget a shortcut or want to change model, speed, screen region, or settings."
        />
      </div>
      <div
        style={{
          position: 'absolute',
          left: 410,
          top: 520,
          display: 'grid',
          gridTemplateColumns: '1fr 1fr',
          columnGap: 100,
          rowGap: 22,
        }}
      >
        <ShortcutRow shortcut="⌥+Space" label="Show or hide" delay={28} />
        <ShortcutRow shortcut="⌥+C" label="Answer selected text" delay={36} />
        <ShortcutRow shortcut="⌥+V" label="Read the chosen area" delay={44} />
        <ShortcutRow shortcut="⌥+L" label="Listen to your question" delay={52} />
      </div>
      <div
        style={{
          position: 'absolute',
          left: 410,
          top: 820,
          fontFamily: fonts.mono,
          color: palette.cyanSoft,
          fontSize: 20,
          opacity: fadeIn(frame, fps, 72),
        }}
      >
        Seihitsu Shirei · quiet command
      </div>
    </Backdrop>
  );
};

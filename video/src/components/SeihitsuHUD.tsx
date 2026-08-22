import React from 'react';
import {Easing, interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {fonts, palette, shadow} from '../theme';
import {RedSeal} from './SumiE';

type HudProps = {
  prompt?: string;
  answer?: string;
  status?: string;
  mode?: 'Full' | 'Brief' | 'Blitz';
  model?: string;
  listening?: boolean;
  visibleAt?: number;
  width?: number;
  x?: number;
  y?: number;
  typing?: boolean;
};

const ToolbarButton: React.FC<{icon: string; label: string; active?: boolean}> = ({icon, label, active}) => (
  <div
    style={{
      display: 'flex',
      alignItems: 'center',
      gap: 7,
      color: active ? palette.red : palette.cyan,
      fontFamily: fonts.mono,
      fontSize: 13,
      fontWeight: 600,
    }}
  >
    <span style={{fontSize: 16}}>{icon}</span>
    {label}
  </div>
);

export const SeihitsuHUD: React.FC<HudProps> = ({
  prompt = '',
  answer = '',
  status = 'Ready',
  mode = 'Full',
  model = 'OpenRouter (Llama 4 Scout)',
  listening = false,
  visibleAt = 0,
  width = 680,
  x = 1130,
  y = 180,
  typing = false,
}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const entrance = spring({frame: frame - visibleAt, fps, config: {damping: 200}});
  const typedPrompt = typing
    ? prompt.slice(0, Math.floor(interpolate(frame, [visibleAt + 18, visibleAt + 82], [0, prompt.length], {
        extrapolateLeft: 'clamp',
        extrapolateRight: 'clamp',
        easing: Easing.linear,
      })))
    : prompt;
  const answerStart = typing ? visibleAt + 105 : visibleAt + 32;
  const shownAnswer = answer.slice(0, Math.floor(interpolate(frame, [answerStart, answerStart + 45], [0, answer.length], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  })));
  const thinking = frame >= answerStart - 24 && frame < answerStart;

  return (
    <div
      style={{
        position: 'absolute',
        left: x,
        top: y,
        width,
        height: 510,
        padding: 20,
        borderRadius: 8,
        overflow: 'hidden',
        background:
          'linear-gradient(150deg,rgba(50,42,35,0.94),rgba(14,12,10,0.97) 60%,rgba(28,21,18,0.97))',
        backdropFilter: 'blur(24px)',
        border: '1px solid rgba(221,205,185,0.28)',
        boxShadow: `${shadow}, 0 0 55px rgba(151,55,55,0.11)`,
        color: 'white',
        zIndex: 25,
        opacity: entrance,
        transform: `translateY(${(1 - entrance) * 30}px) scale(${0.97 + entrance * 0.03})`,
      }}
    >
      <div
        style={{
          position: 'absolute',
          inset: 0,
          backgroundImage:
            'linear-gradient(115deg,rgba(255,255,255,0.055),transparent 28%),radial-gradient(rgba(226,208,184,0.14) 0.5px,transparent 0.7px)',
          backgroundSize: 'auto,6px 6px',
          pointerEvents: 'none',
        }}
      />
      <div
        style={{
          position: 'absolute',
          left: 17,
          right: 17,
          top: 55,
          height: 6,
          opacity: 0.22,
          background: 'linear-gradient(90deg,#d9c6aa 0%,rgba(217,198,170,0.55) 72%,transparent)',
          clipPath: 'polygon(0 30%,94% 0,100% 65%,91% 100%,0 72%)',
          pointerEvents: 'none',
        }}
      />
      <div style={{position: 'absolute', right: 15, top: 13, opacity: 0.58}}>
        <RedSeal text="静" size={29} />
      </div>
      <div style={{position: 'relative', height: '100%', display: 'flex', flexDirection: 'column'}}>
        <div style={{display: 'flex', alignItems: 'center', gap: 12, paddingRight: 44, fontFamily: fonts.mono, fontSize: 19}}>
          <span style={{color: palette.cyan, fontSize: 25}}>{thinking ? '◴' : '◉'}</span>
          <span style={{color: typedPrompt ? 'white' : 'rgba(255,255,255,0.45)'}}>
            {typedPrompt || 'Ask…'}
          </span>
          {thinking ? <span style={{marginLeft: 'auto', color: palette.cyan}}>•••</span> : null}
        </div>
        <div style={{display: 'flex', alignItems: 'center', marginTop: 18, gap: 18}}>
          <ToolbarButton icon="⌗" label="Capture" />
          <ToolbarButton icon="◉" label="Read" />
          <ToolbarButton icon={listening ? '■' : '●'} label={listening ? 'Stop' : 'Listen'} active={listening} />
          <div style={{flex: 1}} />
          {listening ? (
            <>
              <span style={{width: 8, height: 8, borderRadius: 99, background: palette.red}} />
              <span style={{fontFamily: fonts.mono, fontSize: 12, color: palette.red}}>rec</span>
            </>
          ) : null}
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 4,
              fontFamily: fonts.mono,
              fontSize: 12,
            }}
          >
            <span style={{color: mode === 'Blitz' ? palette.cyan : 'rgba(255,255,255,0.28)'}}>⚡</span>
            {(['Full', 'Brief', 'Blitz'] as const).map((m) => (
              <span
                key={m}
                style={{
                  padding: '4px 7px',
                  borderRadius: 6,
                  color: mode === m ? palette.cyan : 'rgba(255,255,255,0.42)',
                  background: mode === m ? 'rgba(183,67,67,0.15)' : 'transparent',
                  fontWeight: mode === m ? 800 : 500,
                }}
              >
                {m}
              </span>
            ))}
          </div>
        </div>
        <div style={{height: 3, background: 'linear-gradient(90deg,rgba(221,205,185,0.28),rgba(221,205,185,0.06),transparent)', clipPath: 'polygon(0 30%,100% 0,96% 100%,0 72%)', marginTop: 17}} />
        <div style={{display: 'flex', alignItems: 'center', marginTop: 15}}>
          <span style={{fontFamily: fonts.mono, fontSize: 11, color: 'rgba(255,255,255,0.38)', letterSpacing: 2}}>ANSWER</span>
          <div style={{flex: 1}} />
          {shownAnswer ? <span style={{fontFamily: fonts.mono, color: palette.cyan, fontSize: 12}}>▣ Copy</span> : null}
        </div>
        <div
          style={{
            marginTop: 14,
            fontFamily: fonts.mono,
            fontSize: 22,
            lineHeight: 1.48,
            color: 'rgba(255,255,255,0.94)',
            whiteSpace: 'pre-wrap',
            flex: 1,
          }}
        >
          {shownAnswer || (thinking ? 'Thinking…' : ' ')}
          {shownAnswer && shownAnswer.length < answer.length ? <span style={{color: palette.cyan}}>▌</span> : null}
        </div>
        <div style={{display: 'flex', fontFamily: fonts.mono, fontSize: 11, color: 'rgba(255,255,255,0.44)'}}>
          <span style={{color: palette.cyan}}>{model}</span>
          <span style={{margin: '0 8px'}}>·</span>
          <span>{thinking ? 'Thinking…' : status}</span>
          <div style={{flex: 1}} />
          <span>⌥Space · ⌥C · ⌥V · ⌥L</span>
        </div>
      </div>
    </div>
  );
};

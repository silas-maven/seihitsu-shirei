import React from 'react';
import {
  Easing,
  Img,
  interpolate,
  spring,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from 'remotion';
import {fonts, palette, shadow} from '../theme';

export const fadeIn = (frame: number, fps: number, delay = 0) =>
  interpolate(frame, [delay, delay + 0.55 * fps], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.out(Easing.cubic),
  });

export const riseIn = (frame: number, fps: number, delay = 0) => {
  const p = spring({frame: frame - delay, fps, config: {damping: 200}});
  return {opacity: p, transform: `translateY(${(1 - p) * 28}px)`};
};

export const AppIcon: React.FC<{size?: number}> = ({size = 82}) => (
  <div
    style={{
      position: 'relative',
      width: size,
      height: size,
      isolation: 'isolate',
    }}
  >
    <div
      style={{
        position: 'absolute',
        inset: '-14%',
        borderRadius: 999,
        background: 'radial-gradient(circle, rgba(151,42,48,0.2), rgba(135,117,96,0.1) 42%, transparent 70%)',
        filter: `blur(${size * 0.08}px)`,
      }}
    />
    <Img
      src={staticFile('seihitsu-icon.png')}
      style={{
        position: 'absolute',
        inset: 0,
        width: size,
        height: size,
        objectFit: 'cover',
        mixBlendMode: 'screen',
        maskImage:
          'radial-gradient(circle closest-side, black 0%, black 78%, rgba(0,0,0,0.72) 87%, transparent 100%)',
        WebkitMaskImage:
          'radial-gradient(circle closest-side, black 0%, black 78%, rgba(0,0,0,0.72) 87%, transparent 100%)',
        filter: `contrast(1.16) brightness(1.08) drop-shadow(0 0 ${size * 0.12}px rgba(172,68,73,0.28))`,
      }}
    />
  </div>
);

export const OpeningEye: React.FC<{width?: number; startAt?: number}> = ({width = 410, startAt = 0}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const localFrame = frame - startAt;
  const height = width * 0.52;
  const open = spring({
    frame: localFrame - 0.12 * fps,
    fps,
    durationInFrames: 1.28 * fps,
    config: {damping: 17, stiffness: 82, mass: 1.5},
  });
  const focus = spring({
    frame: localFrame - 0.95 * fps,
    fps,
    durationInFrames: 0.62 * fps,
    config: {damping: 20, stiffness: 150},
  });
  const pupilPulse = interpolate(
    localFrame,
    [1.15 * fps, 1.42 * fps, 1.85 * fps],
    [0, 1, 0],
    {extrapolateLeft: 'clamp', extrapolateRight: 'clamp', easing: Easing.inOut(Easing.sin)},
  );
  const halfOpen = height * (0.012 + open * 0.475);
  const middle = height / 2;
  const eyePath = `M 0 ${middle} Q ${width / 2} ${middle - halfOpen * 2} ${width} ${middle} Q ${width / 2} ${middle + halfOpen * 2} 0 ${middle} Z`;

  return (
    <div
      style={{
        position: 'relative',
        width,
        height,
        filter: `drop-shadow(0 18px 30px rgba(0,0,0,0.62)) drop-shadow(0 0 ${24 + pupilPulse * 18}px rgba(166,45,48,${0.16 + pupilPulse * 0.2}))`,
      }}
    >
      <svg width={0} height={0} style={{position: 'absolute'}}>
        <defs>
          <clipPath id="opening-eye-clip" clipPathUnits="userSpaceOnUse">
            <path d={eyePath} />
          </clipPath>
        </defs>
      </svg>
      <div
        style={{
          position: 'absolute',
          inset: 0,
          overflow: 'hidden',
          clipPath: 'url(#opening-eye-clip)',
          background:
            'radial-gradient(ellipse at center, #c0b7aa 0%, #91867a 38%, #514940 67%, #171310 91%)',
          boxShadow: 'inset 0 0 40px rgba(0,0,0,0.78)',
        }}
      >
        <div
          style={{
            position: 'absolute',
            left: '50%',
            top: '50%',
            transform: `translate(-50%, -50%) scale(${0.84 + focus * 0.16 + pupilPulse * 0.025})`,
            opacity: interpolate(open, [0.08, 0.34], [0, 1], {
              extrapolateLeft: 'clamp',
              extrapolateRight: 'clamp',
            }),
          }}
        >
          <AppIcon size={height * 0.98} />
        </div>
        <div
          style={{
            position: 'absolute',
            inset: 0,
            background:
              'radial-gradient(ellipse at 50% 48%, transparent 0%, transparent 42%, rgba(20,15,12,0.24) 66%, rgba(8,7,6,0.72) 100%)',
          }}
        />
      </div>

      <svg
        width={width}
        height={height}
        viewBox={`0 0 ${width} ${height}`}
        style={{position: 'absolute', inset: 0, overflow: 'visible'}}
      >
        <path
          d={eyePath}
          fill="none"
          stroke="rgba(81,66,55,0.9)"
          strokeWidth={5}
          vectorEffect="non-scaling-stroke"
        />
      </svg>

    </div>
  );
};

export const Keycap: React.FC<{children: React.ReactNode; active?: boolean}> = ({
  children,
  active = false,
}) => (
  <span
    style={{
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      minWidth: 48,
      height: 42,
      padding: '0 12px',
      borderRadius: 10,
      background: active ? 'rgba(183,67,67,0.18)' : 'rgba(221,205,185,0.08)',
      border: `1px solid ${active ? 'rgba(183,67,67,0.62)' : 'rgba(221,205,185,0.16)'}`,
      color: active ? palette.cyanSoft : palette.text,
      fontFamily: fonts.mono,
      fontSize: 21,
      fontWeight: 700,
      boxShadow: active ? '0 0 24px rgba(183,67,67,0.18)' : 'inset 0 -3px rgba(0,0,0,0.2)',
    }}
  >
    {children}
  </span>
);

export const Shortcut: React.FC<{keys: string; active?: boolean}> = ({keys, active}) => (
  <div style={{display: 'flex', gap: 7, alignItems: 'center'}}>
    {keys.split('+').map((key) => (
      <Keycap key={key} active={active}>
        {key}
      </Keycap>
    ))}
  </div>
);

export const Cursor: React.FC<{
  from: [number, number];
  to: [number, number];
  start?: number;
  end?: number;
  clickAt?: number;
}> = ({from, to, start = 0, end = 30, clickAt}) => {
  const frame = useCurrentFrame();
  const x = interpolate(frame, [start, end], [from[0], to[0]], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.inOut(Easing.cubic),
  });
  const y = interpolate(frame, [start, end], [from[1], to[1]], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.inOut(Easing.cubic),
  });
  const ring = clickAt === undefined
    ? 0
    : interpolate(frame, [clickAt, clickAt + 14], [0, 1], {
        extrapolateLeft: 'clamp',
        extrapolateRight: 'clamp',
      });
  return (
    <div style={{position: 'absolute', left: x, top: y, zIndex: 40}}>
      {clickAt !== undefined ? (
        <div
          style={{
            position: 'absolute',
            width: 50 * ring,
            height: 50 * ring,
            left: -23 * ring,
            top: -23 * ring,
            borderRadius: 999,
            border: `2px solid rgba(183,67,67,${1 - ring})`,
          }}
        />
      ) : null}
      <div
        style={{
          width: 0,
          height: 0,
          borderTop: '23px solid white',
          borderRight: '13px solid transparent',
          transform: 'rotate(-18deg)',
          filter: 'drop-shadow(0 3px 3px rgba(0,0,0,0.65))',
        }}
      />
    </div>
  );
};

export const SceneTitle: React.FC<{
  eyebrow: string;
  title: string;
  detail?: string;
  align?: 'left' | 'center';
  delay?: number;
}> = ({eyebrow, title, detail, align = 'left', delay = 5}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const brush = interpolate(frame, [delay + 6, delay + 32], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.out(Easing.cubic),
  });
  return (
    <div
      style={{
        ...riseIn(frame, fps, delay),
        textAlign: align,
        maxWidth: align === 'center' ? 1250 : 850,
        margin: align === 'center' ? '0 auto' : undefined,
      }}
    >
      <div
        style={{
          color: palette.cyan,
          fontFamily: fonts.mono,
          fontWeight: 700,
          fontSize: 19,
          letterSpacing: 3.5,
          textTransform: 'uppercase',
          marginBottom: 14,
        }}
      >
        {eyebrow}
      </div>
      <div
        style={{
          width: align === 'center' ? 240 : 180,
          height: 8,
          margin: align === 'center' ? '-4px auto 16px' : '-4px 0 16px',
          background: 'linear-gradient(90deg,rgba(183,67,67,0.96),rgba(183,67,67,0.48) 70%,transparent)',
          clipPath: 'polygon(0 30%,93% 0,100% 42%,87% 64%,98% 100%,0 77%)',
          transform: `scaleX(${brush}) rotate(-1deg)`,
          transformOrigin: align === 'center' ? 'center' : 'left',
          opacity: 0.85,
        }}
      />
      <div
        style={{
          color: palette.text,
          fontFamily: fonts.sans,
          fontWeight: 760,
          fontSize: align === 'center' ? 72 : 64,
          lineHeight: 1.02,
          letterSpacing: -2.2,
        }}
      >
        {title}
      </div>
      {detail ? (
        <div
          style={{
            color: palette.muted,
            fontFamily: fonts.sans,
            fontSize: 27,
            lineHeight: 1.35,
            marginTop: 20,
          }}
        >
          {detail}
        </div>
      ) : null}
    </div>
  );
};

export const GuideCaption: React.FC<{
  step: string;
  children: React.ReactNode;
  shortcut?: string;
  delay?: number;
}> = ({step, children, shortcut, delay = 0}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const p = spring({frame: frame - delay, fps, config: {damping: 200}});
  return (
    <div
      style={{
        position: 'absolute',
        left: 80,
        right: 80,
        bottom: 58,
        minHeight: 86,
        borderRadius: 5,
        padding: '18px 24px',
        background:
          'linear-gradient(92deg,rgba(13,11,9,0.98),rgba(26,21,17,0.96) 60%,rgba(14,12,10,0.98))',
        borderTop: '1px solid rgba(221,205,185,0.2)',
        borderBottom: '1px solid rgba(221,205,185,0.12)',
        boxShadow: shadow,
        clipPath: 'polygon(0.4% 8%,99.4% 0,100% 88%,98.7% 100%,0 93%)',
        display: 'flex',
        alignItems: 'center',
        gap: 18,
        opacity: p,
        transform: `translateY(${(1 - p) * 22}px)`,
        zIndex: 50,
      }}
    >
      <div
        style={{
          position: 'absolute',
          left: 3,
          right: 3,
          top: 9,
          height: 6,
          opacity: 0.22,
          background: 'linear-gradient(90deg,transparent,rgba(213,193,168,0.75) 14%,transparent 82%)',
          clipPath: 'polygon(0 40%,94% 0,100% 70%,4% 100%)',
        }}
      />
      <div
        style={{
          width: 42,
          height: 42,
          borderRadius: 1,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          background: 'rgba(183,67,67,0.09)',
          border: '3px solid rgba(183,67,67,0.82)',
          color: '#d85c58',
          fontFamily: fonts.mono,
          fontSize: 18,
          fontWeight: 800,
          flex: '0 0 auto',
        }}
      >
        {step}
      </div>
      <div style={{fontFamily: fonts.sans, color: palette.text, fontSize: 27, lineHeight: 1.28}}>
        {children}
      </div>
      <div style={{flex: 1}} />
      {shortcut ? <Shortcut keys={shortcut} active /> : null}
    </div>
  );
};

export const ProgressRail: React.FC<{scene: number; total?: number}> = ({scene, total = 9}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const opacity = fadeIn(frame, fps, 0);
  return (
    <div
      style={{
        position: 'absolute',
        top: 34,
        right: 50,
        display: 'flex',
        gap: 7,
        opacity,
        zIndex: 60,
      }}
    >
      {Array.from({length: total}, (_, i) => (
        <div
          key={i}
          style={{
            width: i + 1 === scene ? 15 : 9,
            height: i + 1 === scene ? 15 : 9,
            marginTop: i + 1 === scene ? -3 : 0,
            borderRadius: 1,
            transform: `rotate(${i % 2 === 0 ? -2 : 2}deg)`,
            background: i + 1 <= scene ? palette.cyan : 'transparent',
            border: `1px solid ${i + 1 <= scene ? 'rgba(183,67,67,0.88)' : 'rgba(221,205,185,0.28)'}`,
            boxShadow: i + 1 === scene ? '0 0 16px rgba(183,67,67,0.28)' : undefined,
          }}
        />
      ))}
    </div>
  );
};

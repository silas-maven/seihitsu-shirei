import React from 'react';
import {AbsoluteFill, Easing, interpolate, useCurrentFrame, useVideoConfig} from 'remotion';
import {fonts, palette} from '../theme';

const BRUSH_PATHS = [
  'M -120 780 C 270 590 510 890 870 760 S 1460 520 2070 650',
  'M -160 290 C 310 160 560 390 980 270 S 1510 80 2050 250',
  'M -80 930 C 420 760 790 1020 1160 860 S 1660 690 2030 800',
] as const;

export const SumiEAtmosphere: React.FC<{variant?: number; light?: boolean}> = ({
  variant = 0,
  light = false,
}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const drift = interpolate(frame, [0, 12 * fps], [0, 42], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.inOut(Easing.sin),
  });
  const draw = interpolate(frame, [0.25 * fps, 1.5 * fps], [2500, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.out(Easing.cubic),
  });
  const path = BRUSH_PATHS[variant % BRUSH_PATHS.length];
  const ink = light ? 'rgba(45,37,31,0.13)' : 'rgba(199,181,158,0.11)';

  return (
    <AbsoluteFill style={{pointerEvents: 'none', overflow: 'hidden', zIndex: 0}}>
      <div
        style={{
          position: 'absolute',
          inset: 0,
          opacity: light ? 0.13 : 0.24,
          backgroundImage:
            'radial-gradient(rgba(227,211,189,0.19) 0.55px, transparent 0.75px), radial-gradient(rgba(76,61,49,0.17) 0.55px, transparent 0.75px)',
          backgroundPosition: '0 0, 3px 3px',
          backgroundSize: '6px 6px',
          maskImage: 'radial-gradient(ellipse at center, black 0%, transparent 92%)',
        }}
      />
      <div
        style={{
          position: 'absolute',
          width: 880,
          height: 580,
          left: -240 + drift * 0.35,
          top: variant % 2 === 0 ? -170 : 560,
          borderRadius: '44% 56% 63% 37% / 52% 38% 62% 48%',
          background: light ? 'rgba(63,52,43,0.08)' : 'rgba(172,151,126,0.09)',
          filter: 'blur(54px)',
          transform: `rotate(${-10 + variant * 7}deg)`,
        }}
      />
      <div
        style={{
          position: 'absolute',
          width: 720,
          height: 500,
          right: -190 - drift * 0.28,
          bottom: -150,
          borderRadius: '61% 39% 43% 57% / 37% 55% 45% 63%',
          background: light ? 'rgba(103,39,39,0.05)' : 'rgba(132,42,43,0.09)',
          filter: 'blur(60px)',
          transform: `rotate(${14 - variant * 5}deg)`,
        }}
      />
      <svg
        viewBox="0 0 1920 1080"
        style={{position: 'absolute', inset: 0, width: '100%', height: '100%', opacity: light ? 0.55 : 0.72}}
      >
        <path
          d={path}
          fill="none"
          stroke={ink}
          strokeWidth={46}
          strokeLinecap="round"
          strokeDasharray={2500}
          strokeDashoffset={draw}
        />
        <path
          d={path}
          fill="none"
          stroke={light ? 'rgba(40,31,25,0.11)' : 'rgba(225,208,183,0.08)'}
          strokeWidth={5}
          strokeLinecap="round"
          strokeDasharray={2500}
          strokeDashoffset={draw + 70}
          transform="translate(0 22)"
        />
      </svg>
      <div
        style={{
          position: 'absolute',
          right: 42,
          top: 80,
          color: light ? 'rgba(30,24,20,0.05)' : 'rgba(226,209,184,0.045)',
          fontFamily: fonts.sans,
          fontWeight: 800,
          fontSize: 190,
          letterSpacing: 18,
          writingMode: 'vertical-rl',
          transform: `translateY(${drift * 0.22}px)`,
        }}
      >
        技術未来
      </div>
    </AbsoluteFill>
  );
};

export const InkSceneReveal: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  return (
    <AbsoluteFill style={{pointerEvents: 'none', zIndex: 95, overflow: 'hidden'}}>
      {Array.from({length: 6}, (_, i) => {
        const move = interpolate(frame, [i * 0.035 * fps, (0.62 + i * 0.035) * fps], [0, 2250], {
          extrapolateLeft: 'clamp',
          extrapolateRight: 'clamp',
          easing: Easing.inOut(Easing.cubic),
        });
        return (
          <div
            key={i}
            style={{
              position: 'absolute',
              left: -130,
              top: i * 190 - 45,
              width: 2220,
              height: 250,
              background:
                i % 2 === 0
                  ? 'linear-gradient(90deg,#080706 0%,#120f0d 78%,rgba(86,67,54,0.96) 100%)'
                  : 'linear-gradient(90deg,#0b0908 0%,#17120f 82%,rgba(69,54,45,0.96) 100%)',
              clipPath:
                i % 2 === 0
                  ? 'polygon(0 8%,100% 0,98% 18%,100% 34%,97% 51%,100% 72%,98% 94%,0 100%)'
                  : 'polygon(0 0,98% 6%,100% 25%,97% 42%,100% 66%,98% 84%,100% 100%,0 92%)',
              transform: `translateX(${move}px) rotate(${i % 2 === 0 ? -0.35 : 0.28}deg)`,
              boxShadow: '18px 0 28px rgba(0,0,0,0.42)',
            }}
          />
        );
      })}
    </AbsoluteFill>
  );
};

const CLOUD_PUFFS = [
  {y: -70, size: 470, offset: -110},
  {y: 80, size: 560, offset: 80},
  {y: 250, size: 430, offset: -40},
  {y: 390, size: 610, offset: 130},
  {y: 610, size: 500, offset: -90},
  {y: 780, size: 570, offset: 70},
] as const;

export const SumiCloudTransition: React.FC<{
  variant?: number;
  kanji: string;
  label: string;
}> = ({variant = 0, kanji, label}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const duration = 1.6 * fps;
  const forward = variant % 2 === 0;
  const bankX = interpolate(
    frame,
    [0, 0.78 * fps, duration],
    forward ? [-2240, -300, 2140] : [1860, -160, -2360],
    {
      extrapolateLeft: 'clamp',
      extrapolateRight: 'clamp',
      easing: Easing.inOut(Easing.cubic),
    },
  );
  const titleOpacity = interpolate(
    frame,
    [0.34 * fps, 0.62 * fps, 1.02 * fps, 1.38 * fps],
    [0, 1, 1, 0],
    {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'},
  );
  const titleScale = interpolate(frame, [0.34 * fps, 1.38 * fps], [0.88, 1.08], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.out(Easing.cubic),
  });
  const edge = forward ? 1750 : 50;

  return (
    <AbsoluteFill style={{pointerEvents: 'none', overflow: 'hidden', zIndex: 100}}>
      <div
        style={{
          position: 'absolute',
          left: bankX,
          top: -120,
          width: 2280,
          height: 1320,
          background:
            'radial-gradient(circle at 48% 45%,#302a25 0%,#1a1714 46%,#0c0a09 76%),linear-gradient(90deg,#0b0908,#302822)',
          clipPath: forward
            ? 'polygon(0 0,88% 0,96% 5%,91% 12%,99% 19%,93% 27%,100% 36%,94% 45%,99% 55%,92% 64%,100% 74%,94% 84%,98% 93%,88% 100%,0 100%)'
            : 'polygon(12% 0,100% 0,100% 100%,11% 100%,2% 94%,8% 85%,0 75%,7% 65%,1% 56%,8% 46%,0 36%,7% 27%,1% 18%,8% 9%)',
          boxShadow: `${forward ? 32 : -32}px 0 90px rgba(0,0,0,0.72)`,
        }}
      />

      {CLOUD_PUFFS.map((puff, index) => {
        const curl = Math.sin((frame / fps) * 4.2 + index * 1.31) * 28;
        const size = puff.size * (0.94 + 0.05 * Math.sin(frame * 0.08 + index));
        return (
          <div
            key={puff.y}
            style={{
              position: 'absolute',
              left: bankX + edge + puff.offset * (forward ? 1 : -1) + curl,
              top: puff.y,
              width: size,
              height: size * 0.72,
              borderRadius: '50%',
              background:
                index % 2 === 0
                  ? 'radial-gradient(ellipse at 42% 50%,rgba(141,123,103,0.92),rgba(65,54,46,0.96) 42%,rgba(19,16,14,0.92) 68%,transparent 73%)'
                  : 'radial-gradient(ellipse at 55% 46%,rgba(108,93,78,0.9),rgba(51,43,37,0.96) 46%,rgba(16,14,12,0.92) 70%,transparent 75%)',
              filter: `blur(${16 + (index % 3) * 5}px)`,
              opacity: 0.94,
              transform: `rotate(${(index - 2) * 5}deg)`,
            }}
          />
        );
      })}

      {[70, 370, 690].map((top, index) => {
        const contourDraw = interpolate(frame, [0.14 * fps, 1.22 * fps], [1280, 0], {
          extrapolateLeft: 'clamp',
          extrapolateRight: 'clamp',
          easing: Easing.out(Easing.cubic),
        });
        return (
          <svg
            key={top}
            viewBox="0 0 720 300"
            style={{
              position: 'absolute',
              left: bankX + edge + (forward ? -430 : -290),
              top,
              width: 720,
              height: 300,
              opacity: 0.34 - index * 0.045,
              transform: `${forward ? '' : 'scaleX(-1)'} rotate(${index % 2 === 0 ? -3 : 4}deg)`,
              filter: 'drop-shadow(0 10px 18px rgba(0,0,0,0.5))',
            }}
          >
            <path
              d="M18 214 C70 112 160 98 217 154 C246 54 389 36 433 150 C517 92 638 133 700 224"
              fill="none"
              stroke="rgba(221,204,181,0.66)"
              strokeWidth="8"
              strokeLinecap="round"
              strokeDasharray="1280"
              strokeDashoffset={contourDraw + index * 50}
            />
            <path
              d="M90 240 C136 184 201 180 247 214 C304 141 408 142 461 211 C522 170 597 182 654 241"
              fill="none"
              stroke="rgba(183,67,67,0.32)"
              strokeWidth="4"
              strokeLinecap="round"
              strokeDasharray="1280"
              strokeDashoffset={contourDraw + 100 + index * 40}
            />
          </svg>
        );
      })}

      {Array.from({length: 8}, (_, index) => {
        const streakX = bankX + edge + (forward ? -1 : 1) * (130 + index * 58);
        return (
          <div
            key={index}
            style={{
              position: 'absolute',
              left: streakX,
              top: 80 + index * 126,
              width: 440 + (index % 3) * 120,
              height: 18 + (index % 2) * 13,
              background: 'linear-gradient(90deg,rgba(190,169,143,0.25),rgba(79,65,53,0.38),transparent)',
              clipPath: 'polygon(0 35%,92% 0,100% 58%,84% 100%,0 72%)',
              filter: 'blur(7px)',
              opacity: 0.72,
              transform: forward ? 'none' : 'scaleX(-1)',
            }}
          />
        );
      })}

      <div
        style={{
          position: 'absolute',
          inset: 0,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          opacity: titleOpacity,
          transform: `scale(${titleScale})`,
          filter: `blur(${Math.abs(frame - 0.82 * fps) / fps * 1.5}px)`,
        }}
      >
        <div
          style={{
            color: 'rgba(225,210,190,0.72)',
            fontFamily: fonts.sans,
            fontSize: 260,
            fontWeight: 800,
            lineHeight: 0.9,
            textShadow: '0 18px 54px rgba(0,0,0,0.7)',
          }}
        >
          {kanji}
        </div>
        <div
          style={{
            marginTop: 30,
            color: palette.red,
            fontFamily: fonts.mono,
            fontSize: 20,
            fontWeight: 800,
            letterSpacing: 7,
            textTransform: 'uppercase',
          }}
        >
          {label}
        </div>
      </div>
    </AbsoluteFill>
  );
};

export const RedSeal: React.FC<{text?: string; size?: number}> = ({text = '静', size = 44}) => (
  <div
    style={{
      width: size,
      height: size,
      border: `${Math.max(2, size * 0.065)}px solid ${palette.red}`,
      color: palette.red,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      fontFamily: fonts.sans,
      fontSize: size * 0.5,
      fontWeight: 800,
      lineHeight: 1,
      transform: 'rotate(-2deg)',
      boxShadow: `inset 0 0 0 2px rgba(200,67,67,0.18)`,
      opacity: 0.94,
    }}
  >
    {text}
  </div>
);

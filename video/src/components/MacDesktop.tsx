import React from 'react';
import {interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {fonts, palette, shadow} from '../theme';
import {RedSeal, SumiEAtmosphere} from './SumiE';

type DesktopProps = {
  children?: React.ReactNode;
  appName?: string;
  title?: string;
  menuOpen?: boolean;
  highlight?: string;
  showRegion?: boolean;
  quiz?: boolean;
  quizVariant?: 'jacket' | 'planet';
  dimmed?: boolean;
  variant?: number;
};

const MenuBar: React.FC<{appName: string; menuOpen: boolean}> = ({appName, menuOpen}) => (
  <>
    <div
      style={{
        position: 'absolute',
        left: 0,
        right: 0,
        top: 0,
        height: 44,
        background: 'rgba(12,10,8,0.88)',
        borderBottom: '1px solid rgba(220,202,179,0.12)',
        backdropFilter: 'blur(20px)',
        display: 'flex',
        alignItems: 'center',
        padding: '0 24px',
        color: 'rgba(255,255,255,0.9)',
        fontFamily: fonts.sans,
        fontSize: 15,
        zIndex: 5,
      }}
    >
      <span style={{fontSize: 19, marginRight: 22}}>●</span>
      <b>{appName}</b>
      <span style={{marginLeft: 24}}>File</span>
      <span style={{marginLeft: 22}}>Edit</span>
      <span style={{marginLeft: 22}}>View</span>
      <div style={{flex: 1}} />
      <span style={{opacity: 0.75}}>◔</span>
      <span
        style={{
          marginLeft: 18,
          width: 24,
          height: 24,
          borderRadius: 8,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          background: menuOpen ? 'rgba(183,67,67,0.18)' : 'transparent',
          color: menuOpen ? palette.cyan : 'white',
          fontSize: 18,
        }}
      >
        ◉
      </span>
      <span style={{marginLeft: 20}}>Thu 20 Aug&nbsp;&nbsp;19:08</span>
    </div>
    {menuOpen ? <SeihitsuMenu /> : null}
  </>
);

export const SeihitsuMenu: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const p = spring({frame, fps, config: {damping: 200}});
  const rows = [
    ['Show / Hide HUD', '⌥Space'],
    ['Capture selection', '⌥C'],
    ['Read screen', '⌥V'],
    ['Listen', '⌥L'],
    ['Model', '›'],
    ['Speed', '›'],
    ['—', ''],
    ['Set screen region…', ''],
    ['Clear screen region', ''],
    ['—', ''],
    ['Settings…', ''],
    ['Quit Seihitsu', '⌘Q'],
  ];
  return (
    <div
      style={{
        position: 'absolute',
        right: 110,
        top: 38,
        width: 330,
        padding: 9,
        borderRadius: 14,
        background: 'rgba(29,24,20,0.98)',
        border: '1px solid rgba(220,202,179,0.18)',
        boxShadow: shadow,
        transform: `scale(${0.96 + 0.04 * p})`,
        transformOrigin: 'top right',
        opacity: p,
        zIndex: 30,
        fontFamily: fonts.sans,
      }}
    >
      {rows.map(([label, key], i) =>
        label === '—' ? (
          <div key={i} style={{height: 1, margin: '7px 4px', background: 'rgba(255,255,255,0.12)'}} />
        ) : (
          <div
            key={label}
            style={{
              height: 34,
              borderRadius: 7,
              padding: '0 10px',
              display: 'flex',
              alignItems: 'center',
              color: 'rgba(255,255,255,0.9)',
              fontSize: 15,
            }}
          >
            <span>{label}</span>
            <span style={{flex: 1}} />
            <span style={{opacity: 0.5}}>{key}</span>
          </div>
        ),
      )}
    </div>
  );
};

const NotesWindow: React.FC<{
  title: string;
  highlight?: string;
  quiz?: boolean;
  quizVariant?: 'jacket' | 'planet';
}> = ({
  title,
  highlight,
  quiz,
  quizVariant = 'jacket',
}) => (
  <div
    style={{
      position: 'absolute',
      left: 110,
      top: 104,
      width: 1110,
      height: 700,
      background:
        'radial-gradient(circle at 16% 12%,rgba(255,255,255,0.38),transparent 28%),linear-gradient(135deg,#e8dfd0,#d9cebd)',
      borderRadius: 8,
      boxShadow: shadow,
      overflow: 'hidden',
      color: '#2b241f',
      fontFamily: fonts.sans,
      border: '1px solid rgba(73,57,45,0.46)',
      zIndex: 2,
    }}
  >
    <div
      style={{
        height: 52,
        display: 'flex',
        alignItems: 'center',
        padding: '0 20px',
        background: 'rgba(191,178,159,0.72)',
        borderBottom: '1px solid rgba(84,67,54,0.25)',
      }}
    >
      <span style={{width: 13, height: 13, borderRadius: 99, background: '#ff5f57'}} />
      <span style={{width: 13, height: 13, borderRadius: 99, background: '#febc2e', marginLeft: 8}} />
      <span style={{width: 13, height: 13, borderRadius: 99, background: '#28c840', marginLeft: 8}} />
      <b style={{marginLeft: 24, fontSize: 15}}>{title}</b>
    </div>
    <div
      style={{
        position: 'absolute',
        right: 54,
        bottom: 22,
        fontSize: 210,
        fontWeight: 800,
        color: 'rgba(63,50,41,0.035)',
        writingMode: 'vertical-rl',
      }}
    >
      静謐
    </div>
    <div
      style={{
        position: 'absolute',
        left: 52,
        right: 46,
        top: 95,
        height: 19,
        opacity: 0.14,
        background: 'linear-gradient(90deg,#2a211b 0%,rgba(42,33,27,0.6) 73%,transparent)',
        clipPath: 'polygon(0 34%,94% 0,100% 44%,92% 72%,99% 100%,0 73%)',
      }}
    />
    <div style={{position: 'relative', padding: '70px 92px'}}>
      {quiz ? (
        <>
          <div style={{fontSize: 18, letterSpacing: 1.6, color: '#7b342f', fontWeight: 800}}>QUICK CHECK</div>
          <div style={{fontSize: 38, lineHeight: 1.3, marginTop: 24, fontWeight: 680}}>
            {quizVariant === 'jacket' ? (
              <>
                A jacket costs £60 and is reduced by 20%.
                <br />What is the sale price?
              </>
            ) : (
              <>Which planet is known as the Red Planet?</>
            )}
          </div>
          <div style={{display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 18, marginTop: 42}}>
            {(quizVariant === 'jacket'
              ? ['A  £40', 'B  £42', 'C  £48', 'D  £52']
              : ['A  Venus', 'B  Mars', 'C  Jupiter', 'D  Neptune']
            ).map((item) => (
              <div
                key={item}
                style={{
                  background: 'rgba(245,239,229,0.66)',
                  border: '1px solid rgba(77,60,48,0.24)',
                  borderRadius: 4,
                  padding: '19px 22px',
                  fontSize: 25,
                  fontWeight: 600,
                }}
              >
                {item}
              </div>
            ))}
          </div>
          <div style={{marginTop: 40, color: '#6f655d', fontSize: 18}}>This training window does not allow text selection.</div>
        </>
      ) : (
        <>
          <div style={{fontSize: 19, color: '#7b342f', letterSpacing: 2, fontWeight: 800}}>TEAM NOTES</div>
          <div style={{fontSize: 48, fontWeight: 760, marginTop: 18}}>Tokyo launch planning</div>
          <div style={{fontSize: 25, lineHeight: 1.6, marginTop: 38, maxWidth: 810}}>
            The team meets on Monday to confirm the venue and prepare the guest list.
            <br /><br />
            <span
              style={{
                background: highlight ? 'rgba(161,61,57,0.2)' : 'transparent',
                padding: highlight ? '4px 6px' : 0,
                borderBottom: highlight ? '3px solid rgba(143,48,47,0.62)' : undefined,
                borderRadius: 1,
              }}
            >
              {highlight ?? 'What is the capital of Japan?'}
            </span>
          </div>
          <div style={{height: 2, background: 'rgba(75,59,47,0.17)', marginTop: 54}} />
          <div style={{fontSize: 22, color: '#6f655d', marginTop: 28}}>Select any question you want help with.</div>
        </>
      )}
    </div>
  </div>
);

const RegionOverlay: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const progress = spring({frame: frame - 36, fps, config: {damping: 200}});
  const left = interpolate(progress, [0, 1], [400, 175]);
  const top = interpolate(progress, [0, 1], [430, 230]);
  const width = interpolate(progress, [0, 1], [0, 930]);
  const height = interpolate(progress, [0, 1], [0, 380]);
  return (
    <div style={{position: 'absolute', inset: 0, zIndex: 20, background: 'rgba(0,0,0,0.48)'}}>
      <div
        style={{
          position: 'absolute',
          top: 88,
          left: 0,
          right: 0,
          textAlign: 'center',
          color: 'white',
          fontFamily: fonts.mono,
          fontSize: 23,
          fontWeight: 650,
        }}
      >
        Drag the area Seihitsu should read. Esc to cancel.
      </div>
      <div
        style={{
          position: 'absolute',
          left,
          top,
          width,
          height,
          border: `3px solid ${palette.cyan}`,
          background: 'rgba(255,255,255,0.1)',
          boxShadow: '0 0 32px rgba(183,67,67,0.26)',
        }}
      />
    </div>
  );
};

export const MacDesktop: React.FC<DesktopProps> = ({
  children,
  appName = 'Notes',
  title = 'Planning notes',
  menuOpen = false,
  highlight,
  showRegion = false,
  quiz = false,
  quizVariant = 'jacket',
  dimmed = false,
  variant = 0,
}) => (
  <div
    style={{
      position: 'absolute',
      inset: 0,
      overflow: 'hidden',
      background:
        'radial-gradient(circle at 28% 10%,rgba(116,98,81,0.28),transparent 38%),linear-gradient(140deg,#29231e 0%,#100e0c 48%,#211c18 100%)',
      filter: dimmed ? 'brightness(0.55)' : undefined,
    }}
  >
    <SumiEAtmosphere variant={variant} />
    <div
      style={{
        position: 'absolute',
        width: 850,
        height: 850,
        right: -220,
        bottom: -310,
        borderRadius: 999,
        background: 'radial-gradient(circle, rgba(151,55,55,0.24), transparent 66%)',
      }}
    />
    <MenuBar appName={appName} menuOpen={menuOpen} />
    <NotesWindow title={title} highlight={highlight} quiz={quiz} quizVariant={quizVariant} />
    {children}
    {showRegion ? <RegionOverlay /> : null}
    <div style={{position: 'absolute', left: 38, bottom: 38, zIndex: 8, opacity: 0.68}}>
      <RedSeal text="静" size={34} />
    </div>
  </div>
);

import React from 'react';
import {Audio} from '@remotion/media';
import {TransitionSeries, linearTiming} from '@remotion/transitions';
import {fade} from '@remotion/transitions/fade';
import {Sequence, staticFile} from 'remotion';
import {
  AskScene,
  HighlightScene,
  IntroScene,
  PrivacyScene,
  ReadScreenScene,
  RecapScene,
  SetupScene,
  SpeedScene,
  VoiceScene,
} from './Scenes';

const TRANSITION_FRAMES = 12;
const NARRATION_DELAY_FRAMES = 15;

const SCENES = [
  {id: 'intro', frames: 270, audio: '01-intro.mp3', component: IntroScene},
  {id: 'setup', frames: 390, audio: '02-setup.mp3', component: SetupScene},
  {id: 'ask', frames: 300, audio: '03-ask.mp3', component: AskScene},
  {id: 'highlight', frames: 360, audio: '04-highlight.mp3', component: HighlightScene},
  {id: 'read-screen', frames: 390, audio: '05-read-screen.mp3', component: ReadScreenScene},
  {id: 'voice', frames: 330, audio: '06-voice.mp3', component: VoiceScene},
  {id: 'speed', frames: 300, audio: '07-speed.mp3', component: SpeedScene},
  {id: 'privacy', frames: 510, audio: '08-privacy.mp3', component: PrivacyScene},
  {id: 'recap', frames: 420, audio: '09-recap.mp3', component: RecapScene},
] as const;

export const TOTAL_FRAMES =
  SCENES.reduce((total, scene) => total + scene.frames, 0) -
  (SCENES.length - 1) * TRANSITION_FRAMES;

export const SeihitsuUserGuide: React.FC = () => (
  <TransitionSeries>
    {SCENES.map((scene, index) => {
      const Scene = scene.component;
      return (
        <React.Fragment key={scene.id}>
          <TransitionSeries.Sequence durationInFrames={scene.frames} premountFor={30}>
            <Scene />
            <Sequence from={NARRATION_DELAY_FRAMES} premountFor={30}>
              <Audio src={staticFile(`voiceover/${scene.audio}`)} volume={0.96} />
            </Sequence>
          </TransitionSeries.Sequence>
          {index < SCENES.length - 1 ? (
            <TransitionSeries.Transition
              presentation={fade()}
              timing={linearTiming({durationInFrames: TRANSITION_FRAMES})}
            />
          ) : null}
        </React.Fragment>
      );
    })}
  </TransitionSeries>
);

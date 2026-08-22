import React from 'react';
import {Composition} from 'remotion';
import {SeihitsuUserGuide, TOTAL_FRAMES} from './SeihitsuUserGuide';

export const RemotionRoot: React.FC = () => {
  return (
    <Composition
      id="SeihitsuUserGuide"
      component={SeihitsuUserGuide}
      durationInFrames={TOTAL_FRAMES}
      fps={30}
      width={1920}
      height={1080}
    />
  );
};

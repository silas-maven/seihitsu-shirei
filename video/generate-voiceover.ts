import {mkdir, writeFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const apiKey = process.env.ELEVENLABS_API_KEY;

if (!apiKey) {
  throw new Error('ELEVENLABS_API_KEY is not configured');
}

const scenes = [
  {
    id: '01-intro',
    text: 'This is Seihitsu Shirei—quiet AI help that stays beside your work, instead of pulling you into another app.',
  },
  {
    id: '02-setup',
    text: 'Start from the brain icon in your menu bar. Open Settings, add the key for your chosen AI provider, then allow only the features you want to use.',
  },
  {
    id: '03-ask',
    text: 'Press Option-Space to open the panel, type your question, and press Return. The answer appears right there in the floating window.',
  },
  {
    id: '04-highlight',
    text: 'For a faster answer, highlight a question in any app and press Option-C. Seihitsu reads the selection and answers it automatically.',
  },
  {
    id: '05-read-screen',
    text: 'If the text cannot be selected, choose Set screen region from the brain menu and draw around it. After that, Option-V reads the area and answers the question.',
  },
  {
    id: '06-voice',
    text: 'You can also press Option-L and speak naturally. Your words appear in the prompt, and Seihitsu sends the question when you finish.',
  },
  {
    id: '07-speed',
    text: 'Choose Full for detail, Brief for one or two lines, or Blitz when time is short and you only need the answer.',
  },
  {
    id: '08-privacy',
    text: 'The floating H U D is left out of ordinary screenshots and screen shares wherever macOS supports it. Screen text is recognised on your Mac, and only that text goes to your chosen AI provider.',
  },
  {
    id: '09-recap',
    text: 'Remember four shortcuts: Option-Space, Option-C, Option-V, and Option-L. Everything else remains available from the brain icon.',
  },
] as const;

const request = async (url: string, init?: RequestInit) => {
  const response = await fetch(url, {
    ...init,
    headers: {
      'xi-api-key': apiKey,
      ...init?.headers,
    },
  });

  if (!response.ok) {
    const message = await response.text();
    throw new Error(`ElevenLabs request failed (${response.status}): ${message.slice(0, 300)}`);
  }

  return response;
};

const voicesResponse = await request('https://api.elevenlabs.io/v1/voices');
const voices = (await voicesResponse.json()) as {
  voices: Array<{voice_id: string; name: string}>;
};

const selectedVoiceId = process.env.ELEVENLABS_VOICE_ID ?? '1hlpeD1ydbI2ow0Tt3EW';
const selectedVoice = voices.voices.find((voice) => voice.voice_id === selectedVoiceId);

if (!selectedVoice) {
  throw new Error('The configured narration voice was not found');
}

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const outputDirectory = path.join(scriptDirectory, 'public', 'voiceover');
await mkdir(outputDirectory, {recursive: true});

const manifest: Array<{
  id: string;
  file: string;
  text: string;
  bytes: number;
}> = [];

for (const scene of scenes) {
  process.stdout.write(`Generating ${scene.id}... `);

  const response = await request(
    `https://api.elevenlabs.io/v1/text-to-speech/${selectedVoice.voice_id}?output_format=mp3_44100_128`,
    {
      method: 'POST',
      headers: {
        Accept: 'audio/mpeg',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        text: `[calmly] ${scene.text}`,
        model_id: 'eleven_v3',
        language_code: 'en',
        voice_settings: {
          stability: 0.42,
          speed: 0.96,
        },
      }),
    },
  );

  const audio = Buffer.from(await response.arrayBuffer());
  const file = `${scene.id}.mp3`;
  await writeFile(path.join(outputDirectory, file), audio);
  manifest.push({id: scene.id, file, text: scene.text, bytes: audio.byteLength});
  console.log(`${audio.byteLength} bytes`);
}

await writeFile(
  path.join(outputDirectory, 'manifest.json'),
  `${JSON.stringify({voice: selectedVoice.name, voiceId: selectedVoice.voice_id, model: 'eleven_v3', scenes: manifest}, null, 2)}\n`,
);

console.log(`Generated ${manifest.length} clips with ${selectedVoice.name}.`);

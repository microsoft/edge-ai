import { describe, expect, it } from 'vitest'

import { buildResponseCreate, buildSessionUpdate } from './voiceLiveProtocol.js'

describe('Voice Live protocol payloads', () => {
  it('builds the configured PCM16 session update', () => {
    expect(buildSessionUpdate()).toEqual({
      type: 'session.update',
      session: {
        modalities: ['text', 'audio'],
        input_audio_format: 'pcm16',
        input_audio_transcription: { model: 'azure-speech', language: 'en' },
        input_audio_noise_reduction: { type: 'azure_deep_noise_suppression' },
        input_audio_echo_cancellation: { type: 'server_echo_cancellation' },
        output_audio_format: 'pcm16',
        voice: {
          type: 'azure-standard',
          name: 'en-US-TonyNeural',
        },
        turn_detection: {
          type: 'azure_semantic_vad',
          create_response: false,
          interrupt_response: true,
          auto_truncate: true,
        },
      },
    })
  })

  it('wraps authoritative text as a pre-generated assistant message', () => {
    expect(buildResponseCreate('Robot 7 is ready.')).toEqual({
      type: 'response.create',
      response: {
        pre_generated_assistant_message: {
          type: 'message',
          role: 'assistant',
          content: [{ type: 'text', text: 'Robot 7 is ready.' }],
        },
      },
    })
  })

  it('does not normalize response text', () => {
    expect(
      buildResponseCreate('  exact text  ').response.pre_generated_assistant_message.content[0].text,
    ).toBe('  exact text  ')
  })
})

export function buildSessionUpdate() {
  return {
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
  }
}

export function buildResponseCreate(text: string) {
  return {
    type: 'response.create',
    response: {
      pre_generated_assistant_message: {
        type: 'message',
        role: 'assistant',
        content: [
          {
            type: 'text',
            text,
          },
        ],
      },
    },
  }
}

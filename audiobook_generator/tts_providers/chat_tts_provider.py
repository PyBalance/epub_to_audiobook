import logging
import os
import requests
import shutil

from audiobook_generator.tts_providers.base_tts_provider import BaseTTSProvider
from audiobook_generator.core.audio_tags import AudioTags

logger = logging.getLogger(__name__)

class ChatTTSProvider(BaseTTSProvider):
    def __init__(self, config):
        super().__init__(config)
        self.api_url = getattr(config, 'chattts_url', "http://127.0.0.1:9966")
        self.default_params = {
            "speed": 5,
            "temperature": 0.1,
            "top_p": 0.701,
            "top_k": 20,
            "refine_max_new_token": 384,
            "infer_max_new_token": 2048,
            "text_seed": 42,
            "skip_refine": 0,
            "is_stream": 0,
            "custom_voice": 0
        }

    def validate_config(self):
        # voice_name is optional now since we have a default
        pass

    def text_to_speech(self, text, output_file, audio_tags: AudioTags):
        try:
            payload = {
                "text": text,
                "voice": self.config.voice_name or "16.pt",  # Use default if not specified
                "prompt": "[break_6]",
                **self.default_params
            }

            response = requests.post(f"{self.api_url}/tts", data=payload)
            response_data = response.json()

            if response_data.get('code') != 0:
                raise Exception(f"ChatTTS-ui API error: {response_data.get('msg', 'Unknown error')}")

            # Get the source audio file path from the response
            source_audio_path = response_data['audio_files'][0]['filename']

            # Copy the file to our target location
            shutil.copy2(source_audio_path, output_file)

            logger.info(f"Audio saved to {output_file}")

        except Exception as e:
            logger.error(f"Error in text_to_speech: {str(e)}")
            raise

    def estimate_cost(self, total_chars):
        # ChatTTS-ui is free/local, so cost is 0
        return 0

    def get_break_string(self):
        return "\n\n"

    def get_output_file_extension(self):
        return "wav"

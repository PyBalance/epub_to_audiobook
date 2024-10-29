import logging
import requests
import json
from audiobook_generator.tts_providers.base_tts_provider import BaseTTSProvider
from audiobook_generator.core.audio_tags import AudioTags

logger = logging.getLogger(__name__)

class CosyVoiceProvider(BaseTTSProvider):
    def __init__(self, config):
        super().__init__(config)
        self.api_url = getattr(config, 'cosyvoice_url', "http://localhost:9880")
        self.speaker = getattr(config, 'cosyvoice_speaker', "jok老师")

    def validate_config(self):
        # Both url and speaker are optional since we have defaults
        pass

    def text_to_speech(self, text, output_file, audio_tags: AudioTags):
        try:
            headers = {'Content-Type': 'application/json'}
            payload = {
                "text": text,
                "speaker": self.speaker,
                "streaming": 0
            }

            response = requests.post(
                self.api_url,
                data=json.dumps(payload),
                headers=headers
            )

            if response.status_code != 200:
                raise Exception(f"CosyVoice API error: Status code {response.status_code}")

            # Write the audio data directly to file
            with open(output_file, "wb") as f:
                f.write(response.content)

            logger.info(f"Audio saved to {output_file}")

        except Exception as e:
            logger.error(f"Error in text_to_speech: {str(e)}")
            raise

    def estimate_cost(self, total_chars):
        # CosyVoice is free/local, so cost is 0
        return 0

    def get_break_string(self):
        return "\n\n"

    def get_output_file_extension(self):
        return "wav"

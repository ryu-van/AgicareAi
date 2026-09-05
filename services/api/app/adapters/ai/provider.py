"""AI Provider integration adapter."""

from typing import Any


class AIProviderAdapter:
    def __init__(self, model_name: str = "gpt-4o"):
        self.model_name = model_name

    def generate_completion(self, prompt: str, **kwargs: Any) -> str:
        return f"[AI Response for model '{self.model_name}'] {prompt[:100]}"

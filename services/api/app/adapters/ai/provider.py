"""AI Provider integration adapter using Google Gemini 1.5 Flash."""

import logging
from typing import Any

import httpx

from services.api.app.core.config import get_settings

logger = logging.getLogger(__name__)


class AIProviderAdapter:
    def __init__(
        self,
        api_key: str | None = None,
        model_name: str | None = None,
        api_base: str | None = None,
        timeout: float = 20.0,
        client: httpx.Client | None = None,
    ):
        settings = get_settings()
        raw_key = api_key or (settings.gemini_api_key.get_secret_value() if settings.gemini_api_key else None)
        self.api_key = raw_key
        self.model_name = model_name or settings.gemini_model or "gemini-1.5-flash"
        self.api_base = api_base or settings.gemini_api_base or "https://generativelanguage.googleapis.com/v1beta"
        self.timeout = timeout
        self.mock_fallback = settings.ai_mock_fallback
        self._client = client

    def _get_client(self) -> httpx.Client:
        if self._client is None or self._client.is_closed:
            self._client = httpx.Client(timeout=self.timeout)
        return self._client

    def generate_completion(
        self,
        prompt: str,
        system_instruction: str | None = None,
        temperature: float = 0.2,
        context_articles: list[dict[str, Any]] | None = None,
        **kwargs: Any,
    ) -> str:
        """Generate response from Gemini 1.5 Flash API or deterministic fallback."""
        articles = context_articles or []
        if self.api_key and not self.api_key.startswith("mock_"):
            try:
                full_prompt = self._build_grounded_prompt(prompt, articles)
                return self._call_gemini_api(
                    prompt=full_prompt,
                    system_instruction=system_instruction,
                    temperature=temperature,
                )
            except Exception as exc:
                logger.warning("Gemini API call failed, using grounded fallback: %s", type(exc).__name__)
                if not self.mock_fallback:
                    raise

        return self._generate_grounded_fallback(
            prompt=prompt,
            context_articles=articles,
        )

    def _build_grounded_prompt(self, user_question: str, context_articles: list[dict[str, Any]]) -> str:
        """Format RAG context chunks and append user query."""
        if not context_articles:
            return user_question

        chunks: list[str] = ["--- TÀI LIỆU CẨM NANG NÔNG NGHIỆP THAM KHẢO ---"]
        for idx, art in enumerate(context_articles, start=1):
            title = art.get("title", "Tài liệu kỹ thuật")
            topic = art.get("topic", "")
            content = art.get("summary") or art.get("content") or ""
            chunks.append(f"[{idx}] {title} (Chuyên mục: {topic})\nNội dung: {content}")
        chunks.append("--------------------------------------------------")
        chunks.append(f"Câu hỏi của nông dân: {user_question}")
        return "\n\n".join(chunks)

    def _call_gemini_api(
        self,
        prompt: str,
        system_instruction: str | None,
        temperature: float,
    ) -> str:
        url = f"{self.api_base}/models/{self.model_name}:generateContent"
        headers = {
            "Content-Type": "application/json",
            "x-goog-api-key": self.api_key or "",
        }

        request_body: dict[str, Any] = {
            "contents": [
                {
                    "role": "user",
                    "parts": [{"text": prompt}],
                }
            ],
            "generationConfig": {
                "temperature": temperature,
                "maxOutputTokens": 1024,
            },
        }

        if system_instruction:
            request_body["system_instruction"] = {
                "parts": [{"text": system_instruction}]
            }

        client = self._get_client()
        response = client.post(url, headers=headers, json=request_body)
        response.raise_for_status()
        data = response.json()

        candidates = data.get("candidates", [])
        if not candidates:
            raise ValueError("Empty response from Gemini API")

        parts = candidates[0].get("content", {}).get("parts", [])
        if not parts:
            raise ValueError("No text content in Gemini candidate")

        return parts[0].get("text", "").strip()

    def _generate_grounded_fallback(
        self,
        prompt: str,
        context_articles: list[dict[str, Any]],
    ) -> str:
        """Deterministic grounded fallback implementing the 4 mandatory blocks."""
        if not context_articles:
            return (
                "Chưa có nguồn kiến thức đã duyệt phù hợp với câu hỏi này. "
                "Bạn hãy bổ sung triệu chứng, giai đoạn sinh trưởng và điều kiện nuôi trồng, "
                "hoặc liên hệ chuyên gia để được hỗ trợ."
            )

        top = context_articles[0]
        title = top.get("title", "Cẩm nang kỹ thuật nông nghiệp")
        content = top.get("summary") or top.get("content") or "Biện pháp kỹ thuật đang cập nhật."

        return (
            f"Theo nguồn kiến thức nội bộ '{title}': {content} "
            "Đây là thông tin tham khảo, không phải chẩn đoán xác định hay chỉ định thuốc. "
            "Nếu dấu hiệu nặng lên, hãy liên hệ chuyên gia thú y hoặc cán bộ khuyến nông."
        )

    def close(self) -> None:
        if self._client is not None and not self._client.is_closed:
            self._client.close()

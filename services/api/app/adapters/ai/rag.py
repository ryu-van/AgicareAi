"""RAG (Retrieval-Augmented Generation) search & context grounding adapter."""

from typing import Any


class RAGAdapter:
    def retrieve_context(self, query: str, domain: str) -> list[dict[str, Any]]:
        return [
            {
                "article_id": "10000000-0000-4000-8000-000000000001",
                "title": "Tài liệu kỹ thuật nông nghiệp",
                "score": 0.85,
            }
        ]

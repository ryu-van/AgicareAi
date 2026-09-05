"""File upload & cloud object storage client."""


class StorageClientAdapter:
    def upload_file(self, file_bytes: bytes, filename: str) -> str:
        return f"https://storage.agricare.ai/uploads/{filename}"

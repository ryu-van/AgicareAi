from pydantic import BaseModel, ConfigDict, Field


class RegisterRequest(BaseModel):
    identifier: str = Field(min_length=3, max_length=120, description="Số điện thoại hoặc email")
    password: str = Field(min_length=6, max_length=128, description="Mật khẩu tài khoản")
    display_name: str | None = Field(default=None, max_length=120)
    phone: str | None = Field(default=None, max_length=32)


class LoginRequest(BaseModel):
    identifier: str = Field(min_length=1, max_length=120, description="Số điện thoại hoặc email")
    password: str = Field(min_length=1, max_length=128, description="Mật khẩu")


class RefreshTokenRequest(BaseModel):
    refresh_token: str = Field(min_length=1, description="Refresh token")


class TokenResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    user_id: str
    display_name: str | None = None


class AuthUserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    display_name: str | None = None
    phone: str | None = None
    roles: list[str] = []
    created_at: str

from datetime import date as date_type
from sqlalchemy import String, Integer, Boolean, Date, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPrimaryKey


class NamazLog(UUIDPrimaryKey, TimestampMixin, Base):
    __tablename__ = "namaz_logs"

    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    log_date: Mapped[date_type] = mapped_column(Date, nullable=False)
    fajr: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    dhuhr: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    asr: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    maghrib: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    isha: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    xp_earned: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

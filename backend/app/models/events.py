from datetime import date as date_type
from sqlalchemy import String, Integer, Date, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPrimaryKey


class DayEvent(UUIDPrimaryKey, TimestampMixin, Base):
    __tablename__ = "day_events"

    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    event_date: Mapped[date_type] = mapped_column(Date, nullable=False, index=True)
    event_type: Mapped[str] = mapped_column(String(20), nullable=False)  # 'positive' | 'negative'
    category: Mapped[str] = mapped_column(String(50), nullable=False)
    description: Mapped[str] = mapped_column(String(300), nullable=False)
    points: Mapped[int] = mapped_column(Integer, nullable=False)  # positive or negative int

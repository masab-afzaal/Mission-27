from datetime import date
from typing import Optional
from pydantic import BaseModel, Field
from app.models.ielts import IELTSSkill


class IELTSProfileResponse(BaseModel):
    id: str
    target_band: float
    exam_date: Optional[date] = None
    current_band_estimate: float
    readiness_score: float
    reading_band: float
    listening_band: float
    writing_band: float
    speaking_band: float
    model_config = {"from_attributes": True}


class IELTSProfileUpdate(BaseModel):
    target_band: Optional[float] = Field(None, ge=0.0, le=9.0)
    exam_date: Optional[date] = None


class StudySessionCreate(BaseModel):
    skill: IELTSSkill
    duration_minutes: int = Field(ge=5, le=480)
    session_date: date
    topics_covered: Optional[list[str]] = None
    notes: Optional[str] = None
    quality_rating: int = Field(default=3, ge=1, le=5)


class StudySessionResponse(BaseModel):
    id: str
    skill: IELTSSkill
    duration_minutes: int
    session_date: date
    topics_covered: Optional[list[str]] = None
    notes: Optional[str] = None
    quality_rating: int
    xp_earned: int
    model_config = {"from_attributes": True}


class MockTestCreate(BaseModel):
    test_date: date
    reading_score: Optional[float] = Field(None, ge=0.0, le=9.0)
    listening_score: Optional[float] = Field(None, ge=0.0, le=9.0)
    writing_score: Optional[float] = Field(None, ge=0.0, le=9.0)
    speaking_score: Optional[float] = Field(None, ge=0.0, le=9.0)
    notes: Optional[str] = None
    weak_areas: Optional[list[str]] = None


class MockTestResponse(MockTestCreate):
    id: str
    overall_band: Optional[float] = None
    model_config = {"from_attributes": True}


class VocabCreate(BaseModel):
    word: str = Field(min_length=1, max_length=100)
    definition: str
    example_sentence: Optional[str] = None
    tags: Optional[list[str]] = None


class VocabResponse(VocabCreate):
    id: str
    mastery_level: int
    review_count: int
    next_review_date: Optional[date] = None
    model_config = {"from_attributes": True}


class IELTSCommandCenterResponse(BaseModel):
    profile: IELTSProfileResponse
    recent_sessions: list[StudySessionResponse]
    recent_mock_tests: list[MockTestResponse]
    vocabulary_count: int
    days_to_exam: Optional[int] = None
    band_8_probability: float

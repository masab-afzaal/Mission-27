from datetime import date, timedelta
import math
from typing import Annotated

from fastapi import APIRouter, Depends, status
from pydantic import BaseModel, Field
from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.ielts import VocabularyEntry
from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.schemas.ielts import (
    IELTSCommandCenterResponse,
    IELTSProfileUpdate,
    MockTestCreate,
    MockTestResponse,
    StudySessionCreate,
    StudySessionResponse,
    VocabCreate,
    VocabResponse,
)
from app.services.achievement_service import AchievementService
from app.services.ielts_service import IELTSService

router = APIRouter(prefix="/ielts", tags=["ielts"])


class VocabReviewSubmit(BaseModel):
    word_id: str
    quality: int = Field(ge=0, le=5, description="0-2=failed recall, 3=hard, 4=good, 5=perfect")


class VocabReviewResponse(BaseModel):
    id: str
    word: str
    definition: str
    next_review_date: date | None = None
    mastery_level: int
    interval_days: int

    model_config = {"from_attributes": True}


def _sm2(ease_factor: float, interval: int, quality: int) -> tuple[float, int]:
    if quality < 3:
        new_interval = 1
        new_ef = max(1.3, ease_factor - 0.2)
    else:
        if interval <= 1:
            new_interval = 6
        else:
            new_interval = round(interval * ease_factor)
        new_ef = ease_factor + 0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)
        new_ef = max(1.3, new_ef)
        new_interval = new_interval
    return new_ef, new_interval


@router.get("", response_model=IELTSCommandCenterResponse)
async def get_command_center(
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
):
    return await IELTSService(db).get_command_center(str(current_user.id))


@router.post("/sessions", response_model=StudySessionResponse, status_code=status.HTTP_201_CREATED)
async def log_study_session(
    payload: StudySessionCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
):
    result = await IELTSService(db).log_study_session(str(current_user.id), payload)
    await AchievementService(db).check_and_grant(str(current_user.id), "ielts_session_logged")
    return result


@router.post("/mock-tests", response_model=MockTestResponse, status_code=status.HTTP_201_CREATED)
async def log_mock_test(
    payload: MockTestCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
):
    result = await IELTSService(db).log_mock_test(str(current_user.id), payload)
    await AchievementService(db).check_and_grant(str(current_user.id), "ielts_mock_test_logged")
    return result


@router.post("/vocabulary", response_model=VocabResponse, status_code=status.HTTP_201_CREATED)
async def add_vocabulary(
    payload: VocabCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
):
    result = await IELTSService(db).add_vocabulary(str(current_user.id), payload)
    await AchievementService(db).check_and_grant(str(current_user.id), "vocab_added")
    return result


@router.get("/vocabulary/due", response_model=list[VocabReviewResponse])
async def get_due_vocabulary(
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
):
    """Return vocabulary words due for review today (SM-2 scheduled)."""
    today = date.today()
    rows = (await db.execute(
        select(VocabularyEntry).where(
            VocabularyEntry.user_id == str(current_user.id),
            VocabularyEntry.next_review_date <= today,
        ).order_by(VocabularyEntry.next_review_date.asc()).limit(30)
    )).scalars().all()

    # Also include words never reviewed (next_review_date is None)
    unreviewed = (await db.execute(
        select(VocabularyEntry).where(
            VocabularyEntry.user_id == str(current_user.id),
            VocabularyEntry.next_review_date.is_(None),
        ).limit(10)
    )).scalars().all()

    all_due = list(rows) + [w for w in unreviewed if w not in rows]
    return [VocabReviewResponse.model_validate(w) for w in all_due[:20]]


@router.post("/vocabulary/review", response_model=VocabReviewResponse)
async def submit_vocab_review(
    payload: VocabReviewSubmit,
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
):
    """Submit SM-2 review result for a vocabulary word."""
    entry = (await db.execute(
        select(VocabularyEntry).where(
            VocabularyEntry.id == payload.word_id,
            VocabularyEntry.user_id == str(current_user.id),
        )
    )).scalar_one_or_none()
    if not entry:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Vocabulary entry not found")

    new_ef, new_interval = _sm2(entry.ease_factor, entry.interval_days, payload.quality)
    entry.ease_factor = round(new_ef, 3)
    entry.interval_days = new_interval
    entry.next_review_date = date.today() + timedelta(days=new_interval)
    entry.last_review_date = date.today()
    entry.review_count += 1

    # Update mastery level: 0→5 based on interval
    if new_interval >= 21:
        entry.mastery_level = 5
    elif new_interval >= 14:
        entry.mastery_level = 4
    elif new_interval >= 7:
        entry.mastery_level = 3
    elif new_interval >= 3:
        entry.mastery_level = 2
    elif new_interval >= 1:
        entry.mastery_level = max(entry.mastery_level, 1)

    # XP: 2 per review
    user_repo = UserRepository(db)
    await user_repo.add_xp(current_user, 2)
    await db.commit()
    await db.refresh(entry)
    return VocabReviewResponse.model_validate(entry)


class VocabGenerateRequest(BaseModel):
    topic: str


@router.post("/vocabulary/generate", response_model=list[VocabResponse])
async def generate_vocabulary(
    body: VocabGenerateRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: AsyncSession = Depends(get_db),
):
    import os
    import json
    import httpx
    from app.models.ielts import VocabularyEntry

    api_key = settings.GROQ_API_KEY or os.getenv("GROQ_API_KEY")
    if not api_key:
        from fastapi import HTTPException
        raise HTTPException(
            status_code=400,
            detail="Groq API Key is not configured on the backend. Please add it to your environment."
        )

    system_prompt = f"""You are an IELTS preparation expert. Generate exactly 10 advanced, Band 8-9 vocabulary words related to the topic: '{body.topic}'.
For each word, provide:
1. The word itself
2. A clear definition
3. A contextual sample sentence illustrating its correct usage

You MUST return your response as a valid JSON array of objects, where each object has key-value pairs matching this exact structure:
[
  {{
    "word": "ubiquitous",
    "definition": "Present, appearing, or found everywhere.",
    "example_sentence": "Cell phones are now ubiquitous in modern society."
  }}
]

Return only the raw JSON. Do not include markdown code block syntax (like ```json). Ensure it is completely valid JSON."""

    payload = {
        "model": "llama-3.1-70b-versatile",
        "messages": [
            {"role": "user", "content": system_prompt}
        ],
        "temperature": 0.7
    }

    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{settings.GROQ_BASE_URL.rstrip('/')}/chat/completions",
                json=payload,
                headers={"Authorization": f"Bearer {api_key}"},
                timeout=30.0
            )
            response.raise_for_status()
            res_content = response.json()["choices"][0]["message"]["content"].strip()
            
            # Sanitize output (remove backticks or extra text if any)
            if res_content.startswith("```"):
                res_content = res_content.split("```")[1]
                if res_content.startswith("json"):
                    res_content = res_content[4:]
            res_content = res_content.strip()

            words_data = json.loads(res_content)
    except Exception as e:
        # Fallback to llama-3.1-8b-instant
        try:
            payload["model"] = "llama-3.1-8b-instant"
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{settings.GROQ_BASE_URL.rstrip('/')}/chat/completions",
                    json=payload,
                    headers={"Authorization": f"Bearer {api_key}"},
                    timeout=30.0
                )
                response.raise_for_status()
                res_content = response.json()["choices"][0]["message"]["content"].strip()
                if res_content.startswith("```"):
                    res_content = res_content.split("```")[1]
                    if res_content.startswith("json"):
                        res_content = res_content[4:]
                res_content = res_content.strip()
                words_data = json.loads(res_content)
        except Exception as inner_e:
            from fastapi import HTTPException
            raise HTTPException(status_code=500, detail=f"Failed to generate vocabulary using AI: {str(e)}")

    service = IELTSService(db)
    profile = await service.get_or_create_profile(str(current_user.id))

    new_entries = []
    for item in words_data:
        entry = VocabularyEntry(
            profile_id=profile.id,
            user_id=str(current_user.id),
            word=item.get("word", ""),
            definition=item.get("definition", ""),
            example_sentence=item.get("example_sentence", ""),
            tags=[body.topic]
        )
        db.add(entry)
        new_entries.append(entry)

    await db.commit()
    return [VocabResponse.model_validate(w) for w in new_entries]


from fastapi import UploadFile, File

class SpeakingEvaluationResponse(BaseModel):
    band_estimate: float
    fluency_feedback: str
    lexical_feedback: str
    grammar_feedback: str
    coherence_feedback: str
    transcript: str


@router.post("/speaking/submit", response_model=SpeakingEvaluationResponse)
async def submit_speaking_response(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    import os
    import tempfile
    import json
    import httpx

    api_key = settings.GROQ_API_KEY or os.getenv("GROQ_API_KEY")
    if not api_key:
        from fastapi import HTTPException
        raise HTTPException(
            status_code=400,
            detail="Groq API Key is not configured on the backend. Please add it to your environment."
        )

    # Write UploadFile to a temporary local file
    suffix = os.path.splitext(file.filename or "")[1] or ".wav"
    with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
        content = await file.read()
        tmp.write(content)
        tmp_path = tmp.name

    transcript = ""
    try:
        # 1. Transcribe audio with Groq Whisper-large-v3
        with open(tmp_path, "rb") as audio_file:
            files = {"file": (file.filename or f"audio{suffix}", audio_file, file.content_type or "audio/wav")}
            data = {"model": "whisper-large-v3"}
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{settings.GROQ_BASE_URL.rstrip('/')}/audio/transcriptions",
                    files=files,
                    data=data,
                    headers={"Authorization": f"Bearer {api_key}"},
                    timeout=60.0
                )
                response.raise_for_status()
                transcript = response.json().get("text", "")
    except Exception as e:
        from fastapi import HTTPException
        raise HTTPException(status_code=500, detail=f"Speech transcription failed: {str(e)}")
    finally:
        if os.path.exists(tmp_path):
            os.remove(tmp_path)

    if not transcript.strip():
        from fastapi import HTTPException
        raise HTTPException(status_code=400, detail="Audio file contains no recognizable speech.")

    # 2. Evaluate with Llama 3.1
    system_prompt = """You are an official IELTS Speaking examiner. Evaluate this student's response transcript.
Provide feedback on four criteria:
1. Fluency and Coherence
2. Lexical Resource (Vocabulary)
3. Grammatical Range and Accuracy
4. Pronunciation estimate (based on coherence and transcript structure)

Also assign an overall estimated IELTS Band score (from 0 to 9.0, in half-band increments).

Return your evaluation as a JSON object matching this exact structure:
{
  "band_estimate": 7.5,
  "fluency_feedback": "Critique and suggestions regarding coherence, filler words, and speed.",
  "lexical_feedback": "Lexical range critique: identify good vocabulary and areas of improvement.",
  "grammar_feedback": "Grammar critiques: point out errors and comment on structure variety.",
  "coherence_feedback": "General comments on logical structures, transitions, and question alignment.",
  "transcript": "The verbatim transcribed text of the student."
}
Ensure it is a valid JSON. Do not include markdown code block syntax (like ```json) or any conversational text surrounding the JSON."""

    payload = {
        "model": "llama-3.1-70b-versatile",
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": f"The student's response transcript is: '{transcript}'"}
        ],
        "temperature": 0.3
    }

    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{settings.GROQ_BASE_URL.rstrip('/')}/chat/completions",
                json=payload,
                headers={"Authorization": f"Bearer {api_key}"},
                timeout=30.0
            )
            response.raise_for_status()
            res_content = response.json()["choices"][0]["message"]["content"].strip()
            
            if res_content.startswith("```"):
                res_content = res_content.split("```")[1]
                if res_content.startswith("json"):
                    res_content = res_content[4:]
            res_content = res_content.strip()
            
            evaluation = json.loads(res_content)
    except Exception as e:
        # Fallback to llama-3.1-8b-instant
        try:
            payload["model"] = "llama-3.1-8b-instant"
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{settings.GROQ_BASE_URL.rstrip('/')}/chat/completions",
                    json=payload,
                    headers={"Authorization": f"Bearer {api_key}"},
                    timeout=30.0
                )
                response.raise_for_status()
                res_content = response.json()["choices"][0]["message"]["content"].strip()
                if res_content.startswith("```"):
                    res_content = res_content.split("```")[1]
                    if res_content.startswith("json"):
                        res_content = res_content[4:]
                res_content = res_content.strip()
                evaluation = json.loads(res_content)
        except Exception as inner_e:
            from fastapi import HTTPException
            raise HTTPException(status_code=500, detail=f"Failed to evaluate response: {str(e)}")

    # Add the transcript back to the evaluation structure to guarantee consistency
    evaluation["transcript"] = transcript

    # Award the user 20 XP for completing a speaking test
    from app.services.ielts_service import IELTSService
    from app.services.achievement_service import AchievementService
    
    service = IELTSService(db)
    profile = await service.get_or_create_profile(str(current_user.id))
    
    # Save a mock test log entry for Speaking
    from app.models.ielts import IELTSMockTest
    test = IELTSMockTest(
        profile_id=profile.id,
        user_id=str(current_user.id),
        test_date=date.today(),
        speaking_score=evaluation.get("band_estimate", 0.0),
        notes=f"AI Speaking Simulation: {evaluation.get('fluency_feedback', '')[:200]}...",
        overall_band=evaluation.get("band_estimate", 0.0)
    )
    db.add(test)
    
    user_repo = UserRepository(db)
    await user_repo.add_xp(current_user, 20)
    await db.commit()
    
    await AchievementService(db).check_and_grant(str(current_user.id), "ielts_mock_test_logged")
    
    return SpeakingEvaluationResponse.model_validate(evaluation)


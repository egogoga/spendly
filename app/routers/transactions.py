from fastapi import APIRouter, HTTPException
from app.schemas.transaction import ParseRequest, ParseResponse
from app.services.llm_service import process_text

router = APIRouter(prefix="/transactions", tags=["Траты"])

@router.post("/parse", response_model=ParseResponse)
def parse_transaction(request: ParseRequest):
    if not request.text:
        raise HTTPException(status_code=400, detail="Текст не может быть пустым")
        
    # Отправляем текст в сервис (нейросеть или словарь)
    parsed_data = process_text(request.text)
    
    if not parsed_data:
        raise HTTPException(status_code=500, detail="Не удалось распознать траты")
        
    return ParseResponse(
        original_text=request.text,
        parsed_data=parsed_data
    )
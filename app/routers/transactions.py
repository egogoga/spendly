from fastapi import APIRouter, HTTPException
from app.schemas.transaction import ParseRequest
from app.services.llm_service import process_text

router = APIRouter(tags=["Траты"])

# Меняем путь на /expenses/parse, как ждет Саша
@router.post("/expenses/parse")
def parse_transaction(request: ParseRequest):
    if not request.text:
        raise HTTPException(status_code=400, detail="Текст не может быть пустым")
        
    parsed_data = process_text(request.text)
    
    if not parsed_data:
        raise HTTPException(status_code=500, detail="Не удалось распознать траты")
        
    # Возвращаем в формате, который ждет Саша: {"items": [...]}
    # В его коде элементы называются amount, category, note. 
    # Наши траты как раз так и называются, так что просто пакуем их в items.
    return {"items": parsed_data}
from pydantic import BaseModel
from typing import List

# То, что присылает Флаттер (текст фразы)
class ParseRequest(BaseModel):
    text: str

# Одна трата в ответе
class ParsedTransaction(BaseModel):
    amount: int
    category: str
    note: str

# То, что мы возвращаем Флаттеру (список трат)
class ParseResponse(BaseModel):
    original_text: str
    parsed_data: List[ParsedTransaction]
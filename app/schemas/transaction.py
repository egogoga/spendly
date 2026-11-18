from pydantic import BaseModel

class ParseRequest(BaseModel):
    text: str

class ParsedTransaction(BaseModel):
    amount: int
    category: str
    note: str
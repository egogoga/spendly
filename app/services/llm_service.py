import os
import json
import re
from dotenv import load_dotenv
from gigachat import GigaChat

load_dotenv()

# Инициализируем клиент GigaChat
client = GigaChat(
    credentials=os.getenv("GIGACHAT_CREDENTIALS"),
    scope="GIGACHAT_API_PERS",
    verify_ssl_certs=False, # TODO: Пофиксить перед защитой!
    model="GigaChat-2"
)

PROMPT = """Ты — финансовый ассистент приложения Spendly. 
Пользователь рассказывает о своих тратах. Твоя задача — извлечь из текста все траты.
Верни ТОЛЬКО JSON-массив. Никакого текста до или после. Формат:
[
  {{"amount": 1000, "category": "Развлечения", "note": "игровой клуб"}},
  {{"amount": 500, "category": "Еда", "note": "шаурма"}}
]
Категории строго из списка: Еда, Транспорт, Развлечения, Жилье, Здоровье, Прочее.
Учитывай сленг: штукарь=1000, пятихатка=500, косарь=1000, полтос=50, чирик=10.
Текст пользователя: {user_text}
"""

def parse_with_gigachat(text: str):
    try:
        response = client.chat(PROMPT.format(user_text=text))
        raw_text = response.choices[0].message.content
        
        # Очищаем ответ от возможного мусора (ищем квадратные скобки)
        json_str = re.search(r'\[.*\]', raw_text, re.DOTALL).group()
        return json.loads(json_str)
    except Exception as e:
        print(f"Ошибка GigaChat: {e}")
        return None

def parse_with_fallback(text: str):
    # Тут будет твоя логика на регулярках (пока оставим заглушку)
    return [{"amount": 0, "category": "Прочее", "note": "Fallback в разработке"}]

def process_text(text: str):
    # Пытаемся распарсить через нейросеть
    result = parse_with_gigachat(text)
    
    # Если нейросеть упала, включаем наш словарь
    if not result:
        result = parse_with_fallback(text)
        
    return result
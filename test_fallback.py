import json
import re
import os

SLANG_PATH = os.path.join("app", "data", "slang.json")

def fallback_parse(text):
    with open(SLANG_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    slang_dict = data["сленг"]
    categories = data["категории_слова"]
    
    text_lower = text.lower()
    results = []
    
    # Разбиваем текст на куски
    chunks = re.split(r'\s+и\s+|,\s*', text_lower)
    
    for chunk in chunks:
        found_amount = None
        found_word = None
        
        # 1. Ищем сленг (по корню слова)
        for word, amount in slang_dict.items():
            root = word[:-1] 
            if root in chunk:
                found_amount = amount
                found_word = word
                break
                
        # 2. Ищем цифры
        if not found_amount:
            numbers = re.findall(r'\b\d+\b', chunk)
            if numbers:
                found_amount = int(numbers[0])
                found_word = "цифра"
                
        # 3. Ищем категорию (тоже по корням слов)
        if found_amount:
            category = "Прочее"
            for cat, keywords in categories.items():
                # Берем корень каждого ключевого слова (отрезаем последнюю букву)
                if any(kw[:-1] in chunk for kw in keywords):
                    category = cat
                    break
            
            results.append({
                "amount": found_amount, 
                "category": category, 
                "note": f"найдено: {found_word}"
            })
            
    return results

# Тестируем
test_phrase = "Сегодня оставил штукарь в игровом клубе и пятихатку на шаурму"
print(f"Тестируем фразу: {test_phrase}")
print("Результат работы словаря:")

parsed = fallback_parse(test_phrase)
print(json.dumps(parsed, ensure_ascii=False, indent=2))
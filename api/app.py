from flask import Flask, request, jsonify
from flask_cors import CORS
import joblib
import pandas as pd
import re
from difflib import get_close_matches
import numpy as np
import os

app = Flask(__name__)
CORS(app)  # Flutter'dan gelen isteklere izin ver

# Model ve helper data'yı yükle
def load_model():
    """Model ve helper data'yı yükler"""
    try:
        # Dosya yollarını kontrol et
        model_path = 'kalori_model.pkl'
        helper_path = 'helper_data.pkl'
        
        if not os.path.exists(model_path):
            print(f"❌ Model dosyası bulunamadı: {model_path}")
            print(f"   Mevcut dizin: {os.getcwd()}")
            print(f"   Dosyalar: {os.listdir('.')}")
            return None, {}, {}, {}, []
        
        if not os.path.exists(helper_path):
            print(f"❌ Helper data dosyası bulunamadı: {helper_path}")
            return None, {}, {}, {}, []
        
        model = joblib.load(model_path)
        helper_data = joblib.load(helper_path)
        food_db = helper_data['food_db']
        unit_map = helper_data['unit_map']
        cooking_effects = helper_data['cooking_effects']
        feature_names = helper_data['feature_names']
        print("✅ Model ve veriler başarıyla yüklendi!")
        print(f"   Besin sayısı: {len(food_db)}")
        print(f"   Feature sayısı: {len(feature_names)}")
        return model, food_db, unit_map, cooking_effects, feature_names
    except Exception as e:
        import traceback
        print(f"❌ Model yüklenirken hata: {e}")
        print(f"   Hata detayı: {traceback.format_exc()}")
        return None, {}, {}, {}, []

model, food_db, unit_map, cooking_effects, feature_names = load_model()

def nlp_analiz_motoru(cumle):
    """Kullanıcı girdisini analiz eder ve besin bilgilerini çıkarır"""
    if not model:
        return []
    
    cumle = cumle.lower().replace('ı', 'i').replace('ü', 'u').replace('ö', 'o').replace('ş', 's').replace('ç', 'c').replace('ğ', 'g')
    
    bulunanlar = []
    
    # 1. Regex ile Sayı + Birim + Kelime yakalama
    pattern = r'(\d+)\s*(\w+)?\s*(\w+)'
    matches = re.findall(pattern, cumle)
    
    # 2. Pişirme Yöntemi Tespiti
    yontem = 'haslama'
    for m in cooking_effects.keys():
        if m in cumle:
            yontem = m
            break

    for miktar, birim, kelime in matches:
        # Kelime hatalarını düzelt (Bulanık Eşleme)
        en_yakin_yemek = get_close_matches(kelime, food_db.keys(), n=1, cutoff=0.6)
        
        if en_yakin_yemek:
            yemek_adi = en_yakin_yemek[0]
            miktar = int(miktar)
            
            # Gramaj Hesaplama
            if birim in unit_map:
                if unit_map[birim] == 'db_den_al':
                    toplam_gram = miktar * food_db[yemek_adi]['birim_gr']
                else:
                    toplam_gram = miktar * unit_map[birim]
            else:
                toplam_gram = miktar  # Birim yoksa gram varsay
                
            bulunanlar.append({
                'yemek': yemek_adi,
                'gramaj': toplam_gram,
                'yontem': yontem
            })
            
    return bulunanlar

@app.route('/health', methods=['GET'])
def health():
    """API sağlık kontrolü"""
    return jsonify({
        'status': 'ok',
        'model_loaded': model is not None,
        'food_count': len(food_db)
    })

@app.route('/predict', methods=['POST'])
def predict():
    """Kullanıcı girdisinden kalori tahmini yapar"""
    if not model:
        return jsonify({
            'error': 'Model yüklenemedi',
            'success': False
        }), 500
    
    try:
        data = request.get_json()
        user_input = data.get('input', '').strip()
        
        if not user_input:
            return jsonify({
                'error': 'Boş girdi',
                'success': False
            }), 400
        
        # NLP analizi
        analiz_listesi = nlp_analiz_motoru(user_input)
        
        if not analiz_listesi:
            return jsonify({
                'success': False,
                'message': 'Üzgünüm, ne yediğinizi tam anlayamadım. Lütfen "2 adet yumurta" gibi daha açık bir şekilde yazın.',
                'details': [],
                'total_calories': 0
            })
        
        toplam_kalori = 0
        toplam_protein = 0
        toplam_yag = 0
        toplam_karb = 0
        detaylar = []
        
        for item in analiz_listesi:
            base = food_db[item['yemek']]
            ratio = item['gramaj'] / 100.0
            
            # Besin değerlerini hesapla
            protein = base['protein'] * ratio
            yag = (base['yag'] + cooking_effects[item['yontem']]['ek_yag']) * ratio
            karb = base['karb'] * ratio
            
            # Feature setini oluştur (Eğitimdeki sütun sırasıyla aynı olmalı)
            input_data = pd.DataFrame(0, index=[0], columns=feature_names)
            input_data['Protein'] = protein
            input_data['Yag'] = yag
            input_data['Karb'] = karb
            
            # Yöntem sütununu aktif et
            method_col = f"Yontem_{item['yontem']}"
            if method_col in input_data.columns:
                input_data[method_col] = 1
                
            tahmin = model.predict(input_data)[0]
            
            # Toplam değerleri güncelle
            toplam_kalori += tahmin
            toplam_protein += protein
            toplam_yag += yag
            toplam_karb += karb
            
            detaylar.append({
                'food': item['yemek'],
                'amount': item['gramaj'],
                'method': item['yontem'],
                'calories': round(tahmin, 1),
                'protein': round(protein, 1),
                'fat': round(yag, 1),
                'carbs': round(karb, 1)
            })
        
        return jsonify({
            'success': True,
            'input': user_input,
            'details': detaylar,
            'total_calories': round(toplam_kalori, 1),
            'total_protein': round(toplam_protein, 1),
            'total_fat': round(toplam_yag, 1),
            'total_carbs': round(toplam_karb, 1),
            'message': f'Toplam {round(toplam_kalori, 1)} kcal'
        })
        
    except Exception as e:
        import traceback
        return jsonify({
            'error': str(e),
            'traceback': traceback.format_exc(),
            'success': False
        }), 500

@app.route('/foods', methods=['GET'])
def get_foods():
    """Mevcut besin listesini döndürür"""
    foods = [{'name': name, 'unit_gr': data['birim_gr']} for name, data in food_db.items()]
    return jsonify({
        'success': True,
        'foods': foods,
        'count': len(foods)
    })

if __name__ == '__main__':
    # Geliştirme için
    app.run(host='0.0.0.0', port=5000, debug=True)
    # Production için:
    # app.run(host='0.0.0.0', port=5000, debug=False)


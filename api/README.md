# Kalori Tahmin API

Bu API, Flutter uygulaması için makine öğrenmesi tabanlı kalori tahmin servisi sağlar.

## Kurulum

1. Python 3.8+ yüklü olduğundan emin olun
2. Gerekli paketleri yükleyin:
```bash
pip install -r requirements.txt
```

3. Model dosyalarını bu klasöre kopyalayın:
   - `kalori_model.pkl`
   - `helper_data.pkl`

4. API'yi başlatın:
```bash
python app.py
```

API `http://localhost:5000` adresinde çalışacaktır.

## Endpoint'ler

### GET /health
API sağlık kontrolü

### POST /predict
Kullanıcı girdisinden kalori tahmini yapar.

**Request:**
```json
{
  "input": "2 adet yumurta ve 1 dilim ekmek yedim"
}
```

**Response:**
```json
{
  "success": true,
  "input": "2 adet yumurta ve 1 dilim ekmek yedim",
  "details": [
    {
      "food": "yumurta",
      "amount": 100,
      "method": "haslama",
      "calories": 155.2
    },
    {
      "food": "ekmek",
      "amount": 25,
      "method": "haslama",
      "calories": 65.5
    }
  ],
  "total_calories": 220.7,
  "message": "Toplam 220.7 kcal"
}
```

### GET /foods
Mevcut besin listesini döndürür.


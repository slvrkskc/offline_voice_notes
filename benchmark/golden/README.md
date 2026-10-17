# Altın Ses Seti

> Projenin kalite ölçümünün temeli (bkz. [ARCHITECTURE.md §14](../../ARCHITECTURE.md#14-kalite-ölçümü-ve-hedef-metrikler)).
> **S1 spike'ının ön koşulu.** Hiçbir koda bağlı değil — bugün başlayabilirsin.

---

## ⚠️ Ses dosyaları bu repoda değil ve asla olmayacak

Ses kaydı **kişisel veridir**. Repoda yalnızca şunlar bulunur:

- `manifest.json` — klip künyeleri, hash'ler, kategoriler
- `reference/*.txt` — elle yazılmış referans transkriptler
- bu README

Ses dosyaları `audio/` altında, **yalnızca senin makinende** durur ve `.gitignore` tarafından engellenir. Bir kez push edilen ses dosyası, commit geçmişinden silinse bile klonlarda ve önbelleklerde kalır — geri dönüşü yoktur.

---

## Neden bu sete ihtiyacımız var

`ARCHITECTURE.md §14.3`'teki hedef metriklerin **hiçbiri ölçülmedi**. "WER ≤ %15" şu an bir temenni. Bu set, onu ölçüme çevirecek tek araç. Ayrıca S1'in çıktısı doğrudan iki mimari kararı belirliyor:

- `small` mı `large-v3-turbo` mu? (ADR-002)
- Hedef metrikler gerçekçi mi, yoksa hedef cihaz tanımı mı değişmeli?

---

## Kayıt planı — 54 klip

| Kategori | Adet | Ne kaydedilecek |
|---|---|---|
| `tr-clean` | 8 | Sessiz oda, normal hız. Yarısı okunan metin, yarısı doğaçlama |
| `tr-noisy` | 6 | Kafe, araba içi, açık pencere, uzaktan konuşma |
| `tr-spontaneous` | 6 | Duraklamalar, "şey", kendini düzeltme, yarım cümleler |
| `en-clean` | 4 | Sessiz oda |
| `en-noisy` | 4 | Gürültülü ortam |
| **`mixed`** | **10** | **Türkçe konuşurken İngilizce teknik terim.** En değerli kategori — İngilizce bölümleri manifest'te işaretlenecek |
| `short` | 6 | 3–10 saniye. Dil tespitinin güvenilirliğini ölçmek için |
| `long` | 4 | 1×5 dk, 1×15 dk, 1×30 dk, 1×60 dk |
| `hard` | 6 | Sayılar, tarihler, para tutarları, özel isimler, kısaltmalar, e-posta adresi |

### Kayıt ayarları

- **16 kHz, mono, WAV** olursa ideal (Whisper'ın beklediği format; dönüştürme kaybı olmaz)
- Telefonun ses kaydedicisi yeterli — çıktı `.m4a` ise sonra dönüştürürüz
- Her klip tek dosya; klipleri birbirine yapıştırma
- Dosya adı doğrudan `id` olsun: `tr-clean-001.wav`

### Rıza — atlanmayacak adım

Kendi sesin dışında birini kaydedeceksen **önce söyle**: ne için kaydedildiğini, nerede saklanacağını (sadece senin bilgisayarın), paylaşılmayacağını ve istediği zaman sildirebileceğini. Manifest'te `"consent"` alanı bunu kayıt altına alır.

---

## Referans transkriptler

Her klip için `reference/<id>.txt` dosyasına **duyduğunu birebir** yaz:

- Noktalama ve büyük/küçük harf **normal** yazılır (ASR çıktısıyla karşılaştırma öncesi otomatik normalize edilecek)
- Sayılar **söylendiği gibi**: "yirmi üç" deniyorsa `yirmi üç`, "23" denmiyorsa `23` yazma
- Duraklama, "şey", "ıı" gibi dolgu sesleri **yazılır** — ASR bunları üretirse hata sayılmamalı
- Anlaşılmayan yer: `[anlaşılmıyor]`

> **Bu iş sıkıcı ama pazarlıksız.** Referans transkript yoksa WER hesaplanamaz, WER yoksa §14.3'teki hiçbir sayı doğrulanamaz ve proje "ölçtüm" diyemez — ki portföydeki en güçlü iddiası o.

---

## `manifest.json` formatı

```jsonc
{
  "version": 1,
  "clips": [
    {
      "id": "tr-clean-001",
      "file": "audio/tr-clean-001.wav",   // repoda yok, yerelde
      "sha256": "a1b2c3...",              // dosya değişirse ölçüm geçersizdir
      "duration_ms": 42000,
      "language": "tr",                   // tr | en | mixed
      "category": "tr-clean",
      "environment": "quiet_room",        // quiet_room | cafe | car | outdoor
      "speech_style": "read",             // read | spontaneous
      "speaker": "self",                  // self | volunteer-01 ...
      "consent": "self",                  // self | verbal | written
      "reference": "reference/tr-clean-001.txt",
      "code_switch_spans": []
    },
    {
      "id": "mixed-003",
      "file": "audio/mixed-003.wav",
      "sha256": "d4e5f6...",
      "duration_ms": 58000,
      "language": "mixed",
      "category": "mixed",
      "environment": "quiet_room",
      "speech_style": "spontaneous",
      "speaker": "self",
      "consent": "self",
      "reference": "reference/mixed-003.txt",
      "code_switch_spans": [
        { "start_ms": 12000, "end_ms": 14500, "lang": "en", "text": "pull request" },
        { "start_ms": 31200, "end_ms": 33000, "lang": "en", "text": "deployment" }
      ]
    }
  ]
}
```

### `code_switch_spans` neden ayrı

`ARCHITECTURE.md §14.2` İngilizce bölümler için **ayrı WER** raporlanmasını istiyor. Genel WER iyi görünürken teknik terimlerin tamamı yanlış yazılmış olabilir — bu alan o körlüğü engelliyor ve S6'nın (terim sözlüğü) etkisini ölçmeyi mümkün kılıyor.

### `sha256` neden gerekli

Ölçüm sonucu bir dosyaya bağlıdır. Klip sonradan yeniden kaydedilir veya kırpılırsa eski WER rakamı geçersiz olur ama kimse fark etmez. Hash bunu yakalar.

---

## Kamuya açık setlerle tamamlama

Kendi kayıtların yanında, **başkalarının sonuçlarını tekrar edebilmesi** için açık veri setlerinden küçük bir alt küme kullanmak iyi olur:

| Set | Lisans | Not |
|---|---|---|
| Mozilla Common Voice (tr, en) | CC0 | Paylaşılabilir, repoda id listesi tutulabilir |
| FLEURS (tr) | ⚠️ lisansı doğrulanmalı | Kullanmadan önce kontrol et ([THIRD-PARTY.md](../../docs/THIRD-PARTY.md)) |

---

## Sıradaki adım

1. Kayıtları yap (en kolayı: `short` ve `tr-clean` ile başla, `long` en sona)
2. Referans transkriptleri yaz
3. `manifest.json`'ı doldur
4. S1'de harness bu manifest'i okuyup WER/CER/RTF raporu üretecek

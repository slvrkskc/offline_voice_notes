# Öğrenme Planı — Spike'lar Üzerinden

> Bu doküman [`../ARCHITECTURE.md`](../ARCHITECTURE.md)'nin eşlikçisi. Mimari **ne yapacağımızı**, bu doküman **hangi sırayla öğreneceğimizi** anlatıyor.
> **Tarih:** 17 Ekim 2026

---

## Temel fikir: spike'lar öğrenme planının kendisi

Mimari dokümanı okurken "bilmediğim çok şey var" hissi normal ve beklenen. Ama o doküman bilerek şöyle kurgulandı: **hiçbir aşamada her şeyi birden bilmen gerekmiyor.**

14 spike'ın tamamı tek bir soruya cevap arayan, 1 saat ile 2 hafta arasında süren, **birbirinden izole** parçalar. Her biri tek bir yeni beceri öğretiyor ve o beceri öğrenilmeden sonraki spike'a geçilmiyor.

Yani: **spike listesi aynı zamanda müfredat.**

Üç şeyi ayırmak işi çok kolaylaştırıyor:

| | Ne | Örnek |
|---|---|---|
| ✅ **Zaten biliyorsun** | Transfer edilebilir bilgi | Model/quantization kavramları, WER, katmanlı mimari, SQL, repository deseni, süreç orkestrasyonu (RPA deneyimi burada doğrudan işe yarıyor — pipeline + iş kuyruğu tam olarak o) |
| 🟡 **Şimdi öğreneceksin** | Spike'lara dağıtılmış | Android temelleri, manifest/paketleme, JNI+CMake, cihaz üstü inference runtime'ları, Android kripto, FTS5, mobil ölçüm disiplini |
| ⛔ **Şimdi öğrenmeyeceksin** | Bilinçli olarak sonraya | KMP, Swift/iOS, embedding & vektör arama, Zemberek/morfoloji, diarization |

Son satır en az diğerleri kadar önemli. **Şu anda KMP veya Swift öğrenmek israf** — Mac yok, iOS v2'de ve o zamana kadar her şey değişebilir.

---

## Aşama 0 — Android temelleri (spike'lardan önce, ~1 hafta)

Bu aşama olmadan hiçbir spike koşamaz, çünkü her spike bir Android projesi içinde çalışıyor.

| Konu | Neden gerekli | Minimum yeterli seviye |
|---|---|---|
| Kotlin: coroutines + `Flow` | Pipeline ve UI güncellemeleri tamamen bunlara dayanıyor | `suspend fun`, `withContext`, `Flow` topla/yay |
| Compose temel modeli | `state → UI` akışı | Basit liste + buton + state hoisting |
| **Gradle multi-module** | §9'daki tüm modül yapısı buna dayanıyor; projenin iskeleti bu | 3–4 modüllü boş bir proje kurup birbirine bağlamak |
| Lifecycle + izinler | Kayıt ekranı mikrofon izni istiyor | `Activity`/`Application` ömrü, runtime permission akışı |
| `adb` | Her ölçüm ve hata ayıklama buradan geçiyor | `adb logcat`, `adb shell`, `adb push`, `adb install` |

**Bitiş kriteri:** "Boş ama çok modüllü bir uygulamayı derleyip kendi cihazıma kurabiliyorum ve logcat'i okuyabiliyorum."

> **Tavsiye:** Compose'da derinleşme. Bu projenin zorluğu UI'da değil. "Çalışan, çirkin UI" şu aşamada yeterli ve doğru tercih.

---

## Aşama 1 — S2: izin ve paketleme (2–3 gün)

### Ne öğretiyor: *build sistemi nasıl düşünür*

| Beceri | Neden önemli |
|---|---|
| **AndroidManifest merger** | Kütüphanelerin kendi manifest'leri seninkiyle birleşir — bir bağımlılık `INTERNET` iznini sessizce geri getirebilir. Çoğu Android geliştiricisinin farkında olmadığı, ama **bu projenin temel iddiasının dayandığı** mekanizma |
| `tools:node="remove"` + merger report okuma | İzni aktif olarak reddetmek |
| `apkanalyzer` / `aapt2` | Derlenmiş APK'nın içine bakmak — "kaynak kodda yok" ile "üretilen APK'da yok" farkı |
| Gradle'da build-time assertion | Kontrolü CI'da kilitlemek: izin geri gelirse build kırılır |
| AAB vs APK, asset pack yapısı | Modellerin nasıl paketlendiği |

### Neden ilk sırada
- **Cihaz gerektirmiyor**, ucuz (2–3 gün)
- Projenin en güçlü iddiasını (**"ağa hiç çıkamaz"**) ya doğruluyor ya çürütüyor
- Çürütürse ADR-004 değişir → mimari kararı etkiler, bu yüzden geç kalmamalı

**Bitiş kriteri:** "Uygulamamın ağ erişimi olmadığını derlenmiş APK üzerinden kanıtlayabiliyorum ve bu kanıtı CI'da kilitledim."

---

## Aşama 2 — S3: şifreli depolama + arama (3–5 gün)

### Ne öğretiyor: *veri katmanı*

| Beceri | Tanıdıklık |
|---|---|
| Room: entity, DAO, migration | 🟢 Web'den SQL biliyorsun → en tanıdık kısım |
| SQLCipher'ı Room'a takmak | 🟡 Yeni ama mekanik |
| `PRAGMA compile_options` ile derleme seçeneği sorgulamak | 🟡 "Kütüphane gerçekten ne destekliyor" sorusunu cevaplama alışkanlığı |
| Android Keystore | 🔴 Yeni: anahtar üretimi, `setUserAuthenticationRequired`, StrongBox, anahtarın dışa çıkarılamazlığı |
| Google Tink streaming AEAD | 🔴 Yeni: büyük dosyayı akış halinde şifreleme |
| FTS5 | 🟡 external content tabloları, tokenizer seçenekleri, BM25, prefix indeksi |
| **Türkçe locale tuzağı** | 🟡 İ/ı için parametrize testler yazmak — testleri `tr-TR` locale'de de koşturmak |

### Neden ikinci sırada
ASR'dan **önce**, çünkü ASR'ın çıktısını bir yere yazman gerekiyor. "Yazdığım yer şifreli ve doğru şekilde aranabilir" özelliği pipeline'ın geri kalanının zemini. Ayrıca S3 başarısız olursa (FTS5 yoksa) arama planı değişir — bunu ASR'a 2 hafta harcadıktan sonra öğrenmek istemezsin.

**Bitiş kriteri:** "Şifreli bir veritabanına Türkçe metin yazıp, Türkçe karakter ve ek sorunları olmadan arayabiliyorum."

---

## Aşama 3 — S1: ASR (1–2 hafta) ⬅️ en büyük sıçrama

### Ne öğretiyor: *C++ dünyasına geçiş + ölçüm disiplini*

| Beceri | Zorluk |
|---|---|
| CMake + NDK: `externalNativeBuild`, ABI filtreleri (`arm64-v8a`), git submodule | 🔴 Yeni |
| **JNI**: Kotlin ↔ C++ veri geçişi, `ByteBuffer`, native thread, hata ve iptal yönetimi | 🔴🔴 **Bu projenin en zor teknik parçası** |
| whisper.cpp API: model yükleme, `whisper_full_params`, VAD, timestamp, `initial_prompt` | 🟡 Dokümante ve örnekli |
| ggml quantize seviyeleri (q5_1, q8_0) ve gerçek etkileri | 🟢 ML bilginle örtüşüyor |
| **Ölçüm:** RTF hesabı, `dumpsys meminfo` ile tepe RSS, `jiwer` ile WER/CER | 🟢 ML bilginle örtüşüyor |

### JNI için somut tavsiye
**Sıfırdan JNI yazmaya çalışma.** whisper.cpp'nin kendi deposundaki Android örneğini (`examples/whisper.android`) klonla, önce onu olduğu gibi cihazında çalıştır. Çalıştığını gördükten sonra adım adım kendi C API'ne (`vn_core.h`) dönüştür. Bu, haftalarca sürebilecek bir öğrenmeyi günlere indirir.

### Neden üçüncü sırada
En büyük parça ve en çok yeni şey burada. Ama aynı zamanda projenin kalbi: S1'in sonucu §14.3'teki tüm hedef metrikleri ve `small` vs `large-v3-turbo` kararını belirliyor.

**Bitiş kriteri:** "Türkçe bir ses dosyasını cihazda metne çevirip WER/CER ve RTF'ini ölçebiliyorum."

---

## Aşama 4 — S4 + S5 + S6: LLM (1–2 hafta)

### Ne öğretiyor: *cihazda LLM çalıştırmak*

| Beceri | Not |
|---|---|
| llama.cpp API: `llama_context`, KV cache, `n_ctx` bütçesi, mmap | 🟡 JNI'ı S1'de öğrendiğin için burada tekrar öğrenmiyorsun — sadece yeni bir kütüphane |
| **GBNF grammar ile kısıtlı decode** | 🟢 AI/ML bilginle en çok örtüşen ve en ilgi çekici kısım. Portföy görüşmesinde anlatılacak şey |
| **1.7B ölçeğinde prompt mühendisliği** | 🔴 Ayrı bir beceri. Büyük modellere yazdığın prompt burada çalışmıyor: kısa, tekrarlı, örnekli ve çok daha katı olmak gerekiyor |
| Map-reduce özetleme + token bütçesi hesabı | 🟡 Mimari dokümanda hazır (§6), uygulaması mekanik |
| Türkçe dil kayması ölçümü (S5) | 🟡 Basit n-gram tespiti yeterli |

### Neden dördüncü sırada
S1'den gelen transkript olmadan özetlenecek bir şey yok. Ayrıca JNI öğrenme maliyeti S1'de bir kez ödendi.

**Bitiş kriteri:** "Cihazda Türkçe özet ve şema garantili JSON etiket üretebiliyorum; dil kayması oranını biliyorum."

---

## Aşama 5 — S7 + arka plan işleme (~1 hafta)

### Ne öğretiyor: *mobil gerçeklik*

- Foreground service tipleri, `mediaProcessing`, `onTimeout`, WorkManager ≥2.10
- Thermal API (`getCurrentThermalStatus`, listener), Battery Historian
- Checkpoint'li iş kuyruğu, kesinti sonrası devam

### Neden en son
Pipeline ön planda çalışmadan arka plana taşımanın anlamı yok. **Önce çalıştır, sonra arka plana taşı.** Tersi, hata ayıklaması çok daha zor bir süreç.

**Bitiş kriteri:** "60 dakikalık bir kayıt, uygulama kapalıyken, termal çökme olmadan işlenebiliyor; süreç öldürülürse kaldığı yerden devam ediyor."

---

## Hemen başlayabileceğin, teknik bilgi gerektirmeyen iş

> ⚡ **Altın ses setini kaydetmeye bugün başlayabilirsin** (§14.1).

S1'in kritik yolunda ve hiçbir koda bağlı değil. Telefonunun ses kaydedicisiyle 54 klibi toplayıp referans transkriptlerini elle yazmak **günler sürer** — bunu S1'e gelince yapmaya kalkarsan S1 beklemede kalır.

Paralelde yapılabilecek diğer işler:
- Referans transkriptleri yazmak (sıkıcı ama S1'in ön koşulu)
- Kanonik etiket setini kesinleştirmek (§12.4) — kendi gerçek notlarını düşünerek
- İngilizce teknik terim sözlüğünün ilk halini çıkarmak (§12.2, S6 için)

---

## Spike çalışma yöntemi

| Kural | Neden |
|---|---|
| Her spike için **ayrı branch** ve `docs/spikes/S<N>-sonuc.md` | Spike'ın çıktısı kod değil **karar ve ölçüm**. Yazılmamış spike, koşulmamış spike'tır |
| **Spike kodu atılacak koddur** | Temiz olmasına, test yazmaya, soyutlamaya çalışma. Amaç tek bir soruya cevap bulmak |
| Her spike'ın **tek bir sorusu var** | O soruya cevap bulduğun an spike biter. "Biraz daha iyileştirsem" tuzağına düşme |
| Sonucu mimari dokümana geri yaz | ⚠️ işaretli varsayımları ✅'e çevirmek — v0.2'de S11/S12/V11/V12 için yaptığımız gibi |

> **Portföy notu:** `docs/spikes/` klasörü, işe alım görüşmesinde kodun kendisinden daha etkili olabilir. "Ölçtüm, yazdım, karar verdim, kararı belgeledim" döngüsü kıdemli mühendis davranışıdır ve çoğu projede eksiktir.

---

## Özet: sıra ve süre

| Sıra | Aşama | Süre | Yeni beceri yoğunluğu |
|---|---|---|---|
| 0 | Android temelleri | ~1 hafta | 🔴 Yüksek |
| 1 | **S2** — izin + paketleme | 2–3 gün | 🟡 Orta |
| 2 | **S3** — şifreli depolama + FTS5 | 3–5 gün | 🟡 Orta |
| 3 | **S1** — ASR | 1–2 hafta | 🔴🔴 **En yüksek (JNI)** |
| 4 | **S4/S5/S6** — LLM | 1–2 hafta | 🟡 Orta (JNI zaten biliniyor) |
| 5 | **S7** + arka plan | ~1 hafta | 🟡 Orta |
| ∥ | Altın ses seti | paralel, **şimdi başla** | 🟢 Yok |

**Toplam:** ~6–8 hafta, yarı zamanlı. Bu, mimari dokümandaki MVP tahminiyle örtüşüyor.

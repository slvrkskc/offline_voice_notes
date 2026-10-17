# Üçüncü Taraf Lisans Envanteri

> **Amaç:** Projeye giren her bileşenin lisansını, doğrulama durumunu ve bize yüklediği yükümlülüğü tek yerde tutmak.
> Lisans sorunları her zaman **sonradan** ortaya çıkar — bağımlılık eklerken değil, yayınlarken veya biri sorduğunda.
> **Son güncelleme:** 17 Ekim 2026

---

## Kural: lisans kapısı

Projeye **hiçbir** kütüphane veya model, lisansı bu dosyaya yazılmadan eklenmez. Kabul edilen lisanslar:

| Durum | Lisanslar |
|---|---|
| ✅ Kabul | MIT, Apache-2.0, BSD-2/3-Clause, ISC, kamu malı (public domain) |
| ⚠️ Tartış | MPL-2.0, LGPL (dinamik bağlama ile mümkün ama mobilde zahmetli) |
| ❌ Reddet | GPL/AGPL (uygulamanın tamamını kapsar), CC BY-NC (ticari kullanım yasak), "özel şartlar" içeren model lisansları |

**Neden bu kadar katı:** Apache-2.0 bir uygulamada GPL bir kütüphane kullanmak, uygulamanın tamamını GPL yapma yükümlülüğü doğurabilir. Portföy projesinde bunu fark etmek kolay, düzeltmek zordur.

---

## Doğrulama durumu ne demek

| İşaret | Anlamı |
|---|---|
| ✅ | Bu oturumda **kaynağından** doğrulandı (LICENSE dosyası veya resmî model kartı okundu) |
| ⚠️ | Yaygın olarak bilinen lisans, ama bu projede henüz birincil kaynaktan doğrulanmadı — **bağımlılık olarak eklenmeden önce doğrula** |

---

## Çalışma zamanı bağımlılıkları (uygulamaya giren kod)

| Bileşen | Lisans | Durum | Yükümlülüğümüz |
|---|---|---|---|
| **whisper.cpp** (ggml-org) | MIT | ⚠️ | Telif + izin bildirimini dağıtıma dahil et |
| **llama.cpp** (ggml-org) | MIT | ⚠️ | Aynı |
| **Silero VAD** (snakers4) | MIT | ✅ `LICENSE` okundu: "Copyright (c) 2020-present Silero Team" | Aynı |
| **SQLCipher** (Zetetic) | **BSD-3-Clause** | ✅ "Copyright (c) 2025, ZETETIC LLC" | Telif bildirimini **ikili dağıtımın dokümantasyonunda** yeniden üret. Ayrıca Zetetic'in adını ürünü desteklemek/tanıtmak için **yazılı izin olmadan kullanma** |
| SQLite (SQLCipher içinde gömülü) | Kamu malı | ✅ | Yok |
| **Google Tink** | Apache-2.0 | ⚠️ | Telif + NOTICE (varsa) dahil et |
| AndroidX / Jetpack / Compose | Apache-2.0 | ⚠️ | Aynı |
| Kotlin stdlib + coroutines | Apache-2.0 | ⚠️ | Aynı |

### ⚠️ Bundan doğan somut iş: "Açık Kaynak Lisansları" ekranı

Hem MIT hem BSD-3-Clause, **ikili dağıtımda** telif ve izin bildiriminin kullanıcıya sunulan materyallerde yer almasını şart koşuyor. Android'de bunun karşılığı, Ayarlar içinde bir **"Açık Kaynak Lisansları"** ekranıdır.

- Bu, MVP'nin kapsamına girmeli — yayın öncesi değil, baştan.
- Google'ın `oss-licenses-gradle-plugin`'ini **kullanmıyoruz**: `play-services` bağımlılıkları getiriyor ve bu, minimum bağımlılık politikamıza (ARCHITECTURE.md §13.3, P4) aykırı.
- Bunun yerine: bu dosyadan beslenen, elle bakılan basit bir ekran. Denetlenebilir ve sıfır bağımlılık.

---

## Model ağırlıkları (repoda **yok**, cihaza PAD ile gider)

Model ağırlıklarını **yeniden dağıtmıyoruz** — bu, lisans yükümlülüklerinin büyük kısmını baştan ortadan kaldırıyor. Yine de kullandığımız her modelin şartı bizi bağlar.

| Model | Lisans | Durum | Not |
|---|---|---|---|
| **Whisper** (kod + ağırlıklar) | MIT | ✅ OpenAI README: "Whisper's code and model weights are released under the MIT License" | Varsayılan ASR modelimiz. **Ağırlıklar da MIT** — bu, bu alanda nadir ve bizim için çok değerli |
| **Qwen3-1.7B** | Apache-2.0 | ✅ Resmî model kartı | Varsayılan özetleyici (ADR-003) |
| **Silero VAD** ağırlıkları | MIT | ✅ | — |
| ~~Gemma 3 1B~~ | **Gemma Terms of Use** | ✅ HF kartı lisansı "gemma" | ❌ **Varsayılan olarak kullanılmıyor.** Apache/MIT değil; kullanım kısıtlamaları ve şartları aşağıya aktarma yükümlülüğü var |
| Gemma 4 (E2B/E4B) | Apache-2.0 | ✅ Google resmî duyurusu | Opsiyonel "yüksek seviye" aday — lisansı temiz |
| ~~EmbeddingGemma~~ | Gemma Terms | ⚠️ | v2'de değerlendirilecek; Apache-2.0 alternatif aranmalı |

> **ADR-003'ün sessiz gerekçesi:** Varsayılan özetleyici olarak Qwen3'ü seçmemizin bir nedeni de buydu. Gemma 3 1B boyut olarak daha uygundu (529 MB vs 1.28 GB) ama Gemma Terms, Apache-2.0 değil.

---

## Altın ses seti — lisanstan çok **kişisel veri** meselesi

Bu, projenin en kolay gözden kaçan hukuki riski. Ses kaydı **kişisel veridir**.

| Kaynak | Durum | Kural |
|---|---|---|
| Kendi sesin | ✅ Serbest | Yine de repoya konmaz (bkz. aşağı) |
| Başkasının sesi | ⚠️ **Açık rıza gerekir** | Ne için kaydedildiğini, nerede saklanacağını ve silinebileceğini söyle. Yazılı olması iyi olur |
| **Mozilla Common Voice** (TR/EN) | ✅ CC0 | Paylaşılabilir; referans sonuçları başkalarının tekrar etmesini sağlar |
| **FLEURS** | ⚠️ | Kullanmadan önce lisansını doğrula |

**Kesin kural, `.gitignore`'da zaten uygulanıyor:** hiçbir ses dosyası repoya girmez. Repoda yalnızca manifest, SHA-256 hash'leri ve referans transkriptler bulunur. Bir kez push edilen ses dosyası, commit geçmişinden silinse bile klonlarda kalır.

---

## Değiştiremediğimiz sözleşmeler

Bunlar katılma sözleşmesidir — kabul edilir veya o platformda geliştirilmez. Müzakere edilemez, bu yüzden "risk yönetimi" konusu da değildir.

| Sözleşme | Ne zaman | Dikkat edilecek tek şey |
|---|---|---|
| **Android SDK License Agreement** (28 Nisan 2026) | Android Studio kurulumunda | Madde 6: SDK telemetrisi **onay ister**; kurulumda reddediyoruz (docs/SETUP.md). Madde 4.1: Google uygulaman üzerinde hiçbir hak elde etmez |
| Google Play Developer Distribution Agreement | Yayınlarsan | Geliştirici hesabı tek seferlik ücretli; gizlilik politikası ve Data Safety formu zorunlu |
| Apple Developer Program License Agreement | iOS'a geçersek (v2) | Yıllık ücretli |

### Play Store'a çıkarsak gerekecekler

- **Gizlilik politikası** (zorunlu) — bizim durumumuzda yazması en kolay olan tür: hiçbir veri toplanmıyor
- **Data Safety formu** — "No data collected" işaretlenebilir, ve bu iddia `tools/verify-no-network.sh` ile **kanıtlanabilir**; çoğu uygulama bunu yapamaz
- Hedef API seviyesi şartları (Play periyodik olarak yükseltir)

---

## Bizim lisansımız

Proje **Apache-2.0** ([LICENSE](../LICENSE)). MIT yerine seçilme nedeni açık patent hakkı tanımı. Yukarıdaki tüm kabul edilen lisanslarla uyumlu.

---

## Özet: gerçek riskler, sırayla

1. **Lisansı uygun olmayan bir model yayınlamak** → yukarıdaki lisans kapısı kuralı engelliyor
2. **Rızasız ses kaydını repoya koymak** → `.gitignore` ve "ses repoya girmez" kuralı engelliyor
3. **Açık kaynak bildirim ekranını unutmak** → MVP kapsamına alındı (yukarıda)
4. Android SDK sözleşmesi → müzakere edilemez, standart, pratikte risk değil

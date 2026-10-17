# Geliştirme Ortamı Kurulumu

> Bu doküman Aşama 0'ın (bkz. [LEARNING-PLAN.md](LEARNING-PLAN.md)) kurulum kısmıdır ve **S2'nin ön koşuludur**.
> **Tarih:** 17 Ekim 2026

---

## 1. Makinenin şu anki durumu (ölçüldü)

| Bileşen | Durum | Gereken |
|---|---|---|
| JDK | ⚠️ **Java 1.8.0_202** | **JDK 17+** — AGP 9.x minimum ve varsayılan olarak JDK 17 istiyor |
| `JAVA_HOME` | ❌ tanımsız | Android Studio'nun bundle'ladığı JBR yeterli |
| Gradle | ❌ yok | Gradle **9.6.0** (AGP 9.4 minimum ve varsayılanı) — wrapper ile gelecek |
| Android SDK | ❌ yok | Android Studio ile gelir |
| `adb` | ❌ yok | SDK platform-tools ile gelir |
| Git | ✅ 2.54.0 | — |

**Sonuç:** Makinede Android geliştirme ortamı yok. Bu yüzden iskeletin sürüme bağlı dosyaları (`build.gradle.kts`, `gradle/libs.versions.toml`) **bilerek yazılmadı** — aşağıdaki 3. adıma bakın.

---

## 2. Android Studio kurulumu

Android Studio tek başına şunların hepsini getiriyor: **JDK 17+ (bundled JBR)**, Android SDK, `adb`, emülatör, NDK + CMake (S1 için gerekli) ve **sync ettiği bilinen bir AGP/Kotlin sürüm kombinasyonu**.

1. [developer.android.com/studio](https://developer.android.com/studio) → Windows installer
2. Kurulumda **Android SDK**, **SDK Platform-Tools** ve **Android Virtual Device** seçili kalsın
3. İlk açılışta SDK Manager'dan ek olarak kur:
   - **NDK (Side by side)** — S1'de whisper.cpp derlemek için zorunlu
   - **CMake** — aynı sebep
   - **Android SDK Command-line Tools** — `apkanalyzer` buradan geliyor, **S2'nin doğrulama aracı**

### Ortam değişkenleri (PowerShell, kalıcı)

```powershell
[Environment]::SetEnvironmentVariable("ANDROID_HOME", "$env:LOCALAPPDATA\Android\Sdk", "User")
```

Sonra `PATH`'e şunları ekle (Ayarlar → Sistem → Hakkında → Gelişmiş sistem ayarları → Ortam Değişkenleri):

```
%LOCALAPPDATA%\Android\Sdk\platform-tools
%LOCALAPPDATA%\Android\Sdk\cmdline-tools\latest\bin
```

**Doğrulama** (yeni bir terminal açıp):

```bash
adb version && apkanalyzer --version
```

İkisi de sürüm yazdırıyorsa Aşama 0'ın kurulum kısmı bitti.

---

## 3. ⚠️ Gradle baseline'ını alma — dikkatli yapılmalı

Bu projede `settings.gradle.kts` (26 modül) ve `gradle.properties` **hazır**. Eksik olan iki dosya: kök `build.gradle.kts` ve `gradle/libs.versions.toml`.

**Neden bunları yazmadım:** AGP 9.x Kotlin'i artık dahili olarak uyguluyor, yani plugin tanımları AGP 8.x'ten farklı. Derleyip doğrulayamadığım sürüm kombinasyonlarını yazmak, senin saatlerini benim tahminlerimi ayıklamakla geçirmen anlamına gelirdi. Android Studio'nun ürettiği baseline **sync ettiği garantili** bir kombinasyon veriyor; doğru kaynak o.

### ❌ Yapma: Android Studio'yu doğrudan bu klasöre proje kurmaya bırakma

Android Studio'nun "New Project" şablonu `app/src/main/AndroidManifest.xml` dosyasını **üzerine yazar**. O dosya bu projenin en kritik dosyası (`INTERNET` izni reddi). Kaybedersen tüm gizlilik iddiası sessizce kaybolur.

### ✅ Yap: baseline'ı ayrı bir klasörde üret, sonra kopyala

1. Android Studio → **New Project** → **Empty Activity** (Compose)
2. Konum: **`C:\Users\kiska\Desktop\_as-baseline`** (geçici, bu projenin dışında)
3. Gradle sync'in bitmesini bekle — **hata vermeden bittiğini gör**
4. Şu dosyaları `_as-baseline`'dan bu projeye kopyala:

   | Kopyala | Neden |
   |---|---|
   | `gradlew`, `gradlew.bat` | Gradle wrapper script'leri |
   | `gradle/wrapper/` | `gradle-wrapper.jar` + properties — ikili dosya, elle üretilemez |
   | `gradle/libs.versions.toml` | Çalıştığı doğrulanmış sürüm kataloğu |
   | `build.gradle.kts` (kök) | Plugin tanımları |

   **Kopyalama:** `gradle.properties` ve `settings.gradle.kts` **kopyalanmayacak** — bu projedekiler kalacak.

5. `_as-baseline` klasörünü sil
6. Android Studio'da **bu** klasörü aç (`File → Open`) ve sync et

Bu noktada sync, modüllerin `build.gradle.kts` dosyaları olmadığı için hata verecek — **beklenen durum**. Modül build dosyalarını birlikte yazacağız; `settings.gradle.kts` içindeki `include` satırlarını geçici olarak yorum satırına alıp `:app` ile başlayabilirsin.

---

## 4. Test cihazını hazırla

1. Telefonda: **Ayarlar → Telefon hakkında → Yapı numarası**na 7 kez dokun (Geliştirici seçenekleri açılır)
2. **Geliştirici seçenekleri → USB hata ayıklama**'yı aç
3. USB ile bağla, telefondaki izin dialogunda **İzin ver**

**Doğrulama ve cihaz künyesi** — bu çıktı `ARCHITECTURE.md` §14.3'ün başına "referans cihaz" olarak yazılacak (açık soru **Q1b**):

```bash
adb devices && adb shell getprop ro.product.model && adb shell getprop ro.board.platform && adb shell getprop ro.build.version.release && grep MemTotal /proc/meminfo
```

Son komut cihazda çalışmalı:

```bash
adb shell cat /proc/meminfo | grep MemTotal
```

> **Neden önemli:** Hedef metrikler ancak belirli bir cihaza bağlandığında anlam taşır. "RTF ≤ 0.6" cümlesi, hangi cihazda olduğu yazılmadan ölçüm değil temennidir.

---

## 5. S2'yi koşmaya hazır olduğunu nasıl anlarsın

Aşağıdakilerin hepsi geçiyorsa S2'ye geçebiliriz:

```bash
# 1. Araçlar
adb version
apkanalyzer --version

# 2. Cihaz bağlı
adb devices          # listede bir cihaz görünmeli, "unauthorized" değil

# 3. Gradle wrapper çalışıyor
./gradlew --version  # Gradle 9.6+ ve JDK 17+ yazmalı

# 4. S2 script'i çalıştırılabilir (henüz APK yok, "not a file" hatası normal)
bash tools/verify-no-network.sh
```

### Sürüm beklentileri (sync sonrası kontrol et)

| Bileşen | Beklenen | Not |
|---|---|---|
| AGP | **9.4.x** | 9.4.0 Eylül 2026; 9.4.1 muhtemelen güncel ⚠️ release notes ile doğrula |
| Gradle | **9.6.0+** | AGP 9.4'ün minimum ve varsayılanı |
| JDK | **17** | AGP 9.4'ün minimum ve varsayılanı |
| `compileSdk` | ≤ **37** | AGP 9.4'ün desteklediği maksimum API seviyesi |
| `minSdk` | **31** | Android 12 — mimari kararı (§2) |

Android Studio bunlardan farklı bir şey üretirse **onun ürettiği doğrudur** — tablo bir kontrol listesi, emir değil.

---

## 6. Sırada ne var

1. ✅ Dizin ağacı + git deposu + manifest + S2 script'i (bu oturumda yapıldı)
2. ⬅️ **Şu an:** Android Studio kurulumu + baseline + cihaz bağlantısı
3. Modül `build.gradle.kts` dosyaları + convention plugin'ler → derlenebilir boş uygulama
4. **S2** — `INTERNET` izni doğrulaması, CI gate'i (2–3 gün)
5. **S3** — SQLCipher + FTS5 + Tink (3–5 gün)

Paralelde, hiçbir kuruluma bağlı olmayan iş: **altın ses setini kaydetmeye başla** (§14.1). S1'in kritik yolunda ve günler sürüyor.

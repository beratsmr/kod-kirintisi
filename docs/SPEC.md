# Kod Kırıntısı — Ürün Spesifikasyonu

> v1.0 · Tamamen offline iOS uygulaması · Hedef: 3–4 haftada App Store'da yayında

---

## 1. Tek Cümlelik Tanım

Her gün ana ekran widget'ında bir Swift/algoritma mini bulmacası çıkaran, **uygulamayı hiç açmadan kullanılabilen** öğrenme uygulaması.

## 2. Problem

Geliştiriciler "her gün biraz pratik yapayım" der ama:

- **Uygulama açma sürtünmesi** en büyük engel. LeetCode/Duolingo tarzı uygulamalar 15–30 dakikalık oturum ister; kimse her gün bunu yapmaz.
- Mülakat hazırlığı **kriz moduna** sıkışır: 6 ay hiç bakılmaz, sonra bir haftada 200 soru çözülmeye çalışılır.
- Mevcut çözümler ya çok ağır (LeetCode), ya dil-agnostik (Duolingo tarzı genel programlama), ya da Swift'e özel değil.

**Çekirdek içgörü:** Alışkanlık kurmak için kullanıcıyı uygulamaya çekmek değil, **içeriği kullanıcının zaten baktığı yere koymak** gerekir. Ortalama kullanıcı telefonunun kilidini günde 80+ kez açıyor; ana ekran zaten görülüyor.

## 3. Çözüm

Ana ekranda duran bir widget. Günde bir soru. Şıklara widget üzerinden dokunuyorsun, doğru/yanlış anında görünüyor. Merak edersen açıklamayı okumak için uygulamaya giriyorsun — ama zorunlu değil.

**Etkileşim maliyeti: ~4 saniye/gün.**

## 4. Hedef Kitle

| Segment | Neden kullanır |
|---|---|
| **Birincil:** iOS geliştirmeye yeni başlayan/junior geliştiriciler | Dil detaylarını (ARC, `mutating`, value semantics, `@escaping`) pratikle oturtmak |
| **İkincil:** Mülakata hazırlanan mid-level iOS geliştiriciler | Unuttuğu konuları düşük efor ile canlı tutmak |
| **Üçüncül:** Bootcamp/üniversite öğrencileri | Günlük mikro-tekrar |

Global pazar Türkiye'den çok daha büyük — **uygulama dili İngilizce olmalı**, Türkçe lokalizasyon ikinci dil olarak eklenmeli. (İçerik İngilizce, arayüz iki dilli.)

## 5. MVP Kapsamı (v1.0)

Kesin sınır: aşağıdakiler var, **başka hiçbir şey yok**.

### 5.1 Widget (ürünün kalbi)

- [ ] **Small widget** — günün sorusunun başlığı + kategori rozeti + streak sayacı. Dokunma → uygulama açılır.
- [ ] **Medium widget** — soru metni + 2–4 şık, her şık **interaktif buton** (AppIntent). Cevaplandığında widget yerinde doğru/yanlış gösterir, uygulama açılmaz.
- [ ] **Lock screen `accessoryRectangular`** — soru başlığı + "cevaplandı/cevaplanmadı" durumu.
- [ ] **Control Center kontrolü (`ControlWidget`)** — "Bugünkü Soru" butonu.
- [ ] Timeline gece yarısı yenilenir; günün sorusu deterministik olarak hesaplanır.

### 5.2 Uygulama

- [ ] **Bugün** — soru kartı, şıklar, cevap sonrası açıklama (kod örnekli), "neden diğerleri yanlış" notu, kaynak linki.
- [ ] **Arşiv** — geçmiş sorular; kategori/zorluk filtresi, arama, doğru-yanlış işareti.
- [ ] **İstatistik** — streak, toplam doğru oranı, kategori bazlı başarı grafiği (Swift Charts).
- [ ] **Ayarlar** — günlük bildirim saati, dahil edilecek kategoriler, ilerlemeyi sıfırla, hakkında.

### 5.3 Sistem entegrasyonları

- [ ] **App Intents** — `ShowTodaysPuzzleIntent`, `AnswerPuzzleIntent`, `RevealAnswerIntent` + `AppShortcutsProvider` (Siri: "Bugünkü kod kırıntısı").
- [ ] **Spotlight (CoreSpotlight)** — tüm sorular sistem aramasından bulunabilir; sonuca dokununca ilgili soru açılır.
- [ ] **Local notification** — kullanıcının seçtiği saatte günlük hatırlatma (opsiyonel, varsayılan kapalı).

### 5.4 İçerik

- [ ] **120 soru** uygulamaya gömülü JSON (4 aylık günlük içerik).
- [ ] Kategoriler: `swift-language`, `concurrency`, `memory-arc`, `swiftui`, `foundation`, `algorithms`, `ios-platform`.
- [ ] Zorluk: 1 (temel) / 2 (orta) / 3 (ileri).

### ❌ v1.0'a GİRMEYECEKLER

Kullanıcı hesabı · Backend · Cihazlar arası senkronizasyon · Sosyal/liderlik tablosu · Kullanıcı soru gönderimi · Çoklu dil içerik · Satın alma · Analytics SDK'sı · Kod editörü/çalıştırıcı

## 6. Ana Kullanıcı Akışları

**Akış A — Widget'ta cevaplama (birincil, %80 kullanım)**
Kullanıcı ana ekrana bakar → soruyu okur → bir şıka dokunur → widget doğru/yanlış gösterir + streak artar → biter.

**Akış B — Derinleşme**
Widget'ta yanlış cevap verir → merak eder → widget'a dokunur → uygulama Bugün ekranında açılır → açıklamayı ve kod örneğini okur.

**Akış C — Toplu tekrar**
Mülakat öncesi uygulamayı açar → Arşiv → "yanlış cevapladıklarım" filtresi → seri halinde tekrar eder.

## 7. İçerik Modeli

```jsonc
{
  "id": "swift-value-semantics-001",       // kalıcı slug, asla değişmez
  "category": "swift-language",
  "difficulty": 2,                          // 1..3
  "title": "Struct kopyalandığında ne olur?",
  "question": "Aşağıdaki kod ne yazdırır?",
  "codeSnippet": "struct P { var x = 0 }\nvar a = P(); var b = a; b.x = 5\nprint(a.x)",
  "language": "swift",
  "choices": ["0", "5", "nil", "Derlenmez"],
  "correctIndex": 0,
  "explanation": "Struct value type'tır...",
  "whyOthersWrong": ["...", "...", "..."],  // choices ile aynı uzunlukta, correctIndex boş string
  "reference": { "title": "Swift Book — Structures", "url": "https://..." },
  "tags": ["value-type", "struct"]
}
```

Şıklar **widget'a sığmalı**: her şık ≤ 24 karakter, soru metni ≤ 120 karakter, kod parçası ≤ 6 satır. Bu kısıt içeriğin kendisini de disipline eder.

## 8. Günün Sorusu Nasıl Seçilir

Backend olmadığı için seçim **deterministik ve saf bir fonksiyon** olmalı — aynı gün, aynı cihaz, her zaman aynı soru; widget ve uygulama bağımsız hesaplayınca aynı sonucu bulmalı.

1. Kurulumda bir `installSeed: UInt64` üretilip App Group'a yazılır (her kullanıcı farklı sırada görür).
2. `installSeed` ile SplitMix64 tabanlı deterministik shuffle → soru indekslerinin sabit bir permütasyonu.
3. `dayIndex = epoch (2026-01-01) ile bugün arasındaki gün farkı`
4. `puzzle = permutation[dayIndex % bank.count]`

Sonuç: banka tükenene kadar tekrar yok, ağ yok, saat dilimi kullanıcının takvimine göre, %100 test edilebilir.

## 9. Gelir Modeli

v1.0 **tamamen ücretsiz ve reklamsız**. Amaç para değil, portföy + kullanıcı.

v1.1+ opsiyonları (CV'ye StoreKit 2 eklemek istersen):
- **Kırıntı Paketleri** — tek seferlik satın alma ile tematik soru paketleri (SwiftUI Derinlemesine, Concurrency, Sistem Tasarımı).
- **Pro** — sınırsız arşiv tekrarı + özel widget temaları, yıllık abonelik.

## 10. Farklılaşma

| | Kod Kırıntısı | LeetCode | Duolingo tarzı | Diğer quiz app'leri |
|---|---|---|---|---|
| Uygulama açmadan kullanım | ✅ | ❌ | ❌ | ❌ |
| Günlük efor | ~4 sn | 20–40 dk | 5–10 dk | 5 dk |
| Swift'e özel | ✅ | ❌ | ❌ | kısmen |
| Offline | ✅ | ❌ | ❌ | değişken |

**Neden şimdi:** İnteraktif widget'lar (iOS 17+), Control Center kontrolleri ve App Intents ekosistemi bu ürünü ancak son iki yılda mümkün kıldı. "Uygulamasız uygulama" fikri artık teknik olarak uygulanabilir.

## 11. Başarı Kriterleri (CV perspektifi)

Bu proje işe alım açısından şu sinyalleri vermeli:

1. **App Store'da yayında** — tamamlama sinyali, en kritik faktör.
2. **Yeşil CI rozeti** olan public GitHub reposu.
3. **Core katmanında %80+ test kapsamı** — mühendislik disiplini.
4. **README'de mimari diyagramı** + widget'ın ekran kaydı (GIF).
5. Mülakatta konuşulacak somut teknik kararlar: deterministik seçim algoritması, Linux'ta test edilebilir çekirdek, XcodeGen ile kod-tabanlı proje tanımı, widget timeline bütçesi.

## 12. Yol Haritası

| Sürüm | Kapsam |
|---|---|
| **v1.0** | Yukarıdaki MVP, 120 soru, offline |
| v1.1 | CloudKit senkronizasyonu, ilerleme cihazlar arası taşınır |
| v1.2 | Watch komplikasyonu, Türkçe içerik lokalizasyonu |
| v1.3 | StoreKit 2 ile soru paketleri |

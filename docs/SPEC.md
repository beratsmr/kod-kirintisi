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
- [ ] **Arşiv** — geçmiş sorular; kategori/zorluk/durum filtresi, arama, doğru-yanlış işareti. Durum filtresi Akış C'nin ihtiyacı: "hepsi / yanlış cevapladıklarım / cevaplanmamışlar".
- [ ] **İstatistik** — streak, toplam doğru oranı, kategori bazlı başarı grafiği (Swift Charts).

> **Streak kuralı:** Streak **yalnızca doğru cevaplanan günleri** sayar.
> - **Yanlış cevap seriyi anında kırar.** Cevap verildiği an streak 0 olur, gece yarısını beklemez — kullanıcı kaybettiği seriyi gün boyu ayakta görmemeli.
> - **Cevaplanmamış bugün seriyi bitirmez**; gün henüz dolmadı. İki gün üst üste boş geçince sıfırlanır.
> - Bu ikisi farklı durumlardır, bu yüzden `StreakCalculator` hem doğru hem yanlış cevaplanan gün kümesini alır. Sonucu yalnızca **bugünün** yanlış kümesinde olması değiştirir; geçmiş yanlış günler zaten doğru kümesinde olmadıkları için seriyi kendiliğinden durdurur.
> - Gün sınırı kullanıcının takvimine göre (`startOfDay`), yaz saati geçişlerinde de gün tam olarak bir artar.
- [ ] **Ayarlar** — günlük bildirim saati, ilerlemeyi sıfırla, hakkında.

> **Kategori seçimi neden yok:** §8 günün sorusunu tarihin saf fonksiyonu
> sayıyor; uygulama ile widget sunucu olmadan aynı sonuca varabildiği için
> böyle. Kategori dışlaması bu hesabı ayarlara bağımlı kılar ve kullanıcı bir
> kategoriyi kapattığında geçmiş günlerin soruları da değişir — yani arşiv
> yeniden yazılır. Günde tek soru gösteren 120 soruluk bir bankada filtrenin
> getirisi bu bedeli karşılamıyor.

### 5.3 Sistem entegrasyonları

- [ ] **App Intents** — `ShowTodaysPuzzleIntent`, `AnswerPuzzleIntent`, `RevealAnswerIntent` + `AppShortcutsProvider` (Siri: "Bugünkü kod kırıntısı").
  `RevealAnswerIntent` **cevap kaydetmez**: açıklamayı gösterir, gün cevaplanmamış kalır, streak'e ve doğruluk oranına dokunmaz. Açıklama açıkken şıklar tıklanamaz olur, yani "gör, sonra doğruyu işaretle" mümkün değil.
- [ ] **Spotlight (CoreSpotlight)** — **açılmış günlerin** soruları sistem aramasından bulunabilir; sonuca dokununca soru Arşiv'de açılır.
  İlk taslak "tüm sorular" diyordu; bu, henüz günü gelmemiş soruları sızdırırdı — Arşiv'in uyduğu spoiler kuralı burada da geçerli. İndekse yalnızca başlık, soru metni ve etiketler girer; **açıklama, şıklar ve doğru cevap asla girmez**.
- [ ] **Local notification** — kullanıcının seçtiği saatte günlük hatırlatma (opsiyonel, varsayılan kapalı).
  Metin sabittir ("bugünün sorusu hazır"), sorunun kendisi değil: tekrarlayan tetikleyici tek kayıttan aylarca ateşlenir, gömülü soru metni bayatlar ve kilit ekranı günü sızdırmak için yanlış yerdir.

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

1. Kurulumda bir `installSeed: UInt64` **ve** kurulum günü (`installedOn`) üretilip App Group'a yazılır. Seed her kullanıcının soruları farklı sırada görmesini sağlar.
2. Banka **30'luk bloklar hâlinde** shuffle edilir. Her blok kendi tohumundan (`installSeed ^ (blokBaşı × altın oran sabiti)`) beslenir ve yalnızca kendi aralığındaki indeksleri karıştırır. Bloklar sırayla birleştirilince ortaya bankanın tam bir permütasyonu çıkar.
3. `dayIndex = installedOn ile bugün arasındaki gün farkı`
4. `puzzle = permutation[dayIndex % bank.count]`

**Neden blok blok?** Tek seferde tüm bankayı karıştırmak eşdeğer görünüyor ama değil: Fisher-Yates'te her çekiliş üreteci ilerletir ve çekiliş sayısı `bank.count`'a bağlıdır. Bankayı 120'den 150'ye çıkarmak, ölçtüğümüzde **geçmiş 120 günün 120'sini birden** değiştiriyordu — kullanıcı güncellemeden sonra uygulamayı açıp dünkü sorusunu bambaşka bulurdu. Blok yaklaşımında bir bloğun sırası yalnızca seed'e ve bloğun başladığı yere bağlıdır, toplam soru sayısına değil; dolayısıyla yeni içerik yayınlamak daha önceki her bloğu — ve yaşanmış her günü — olduğu gibi bırakır. Bunun karşılığında banka **her zaman 30'un tam katı** olmalıdır (`PuzzleBankIntegrityTests` zorlar), yoksa yarım kalan bir blok sonraki sürümde tamamlanır ve içindeki günler kayar.

**Neden kurulum günü?** Epoch eskiden sabit bir takvim günüydü (2026-01-01). Bu, aylar sonra kuran bir kullanıcının arşivini baştan tamamen açılmış hâlde bulması ve geri dönmek için bir sebebinin kalmaması demekti. Kuruluma sabitlemek herkese gerçek bir "1. gün" verir. `installedOn` alanı olmayan eski dosyalar en erken cevabın tarihinden, hiç cevap yoksa eski sabit epoch'tan devralır.

Epoch'tan önceki tarihler (cihaz saati geriye alınmışsa) 0. güne sabitlenir; widget asla boş kalmaz.

Sonuç: banka tükenene kadar tekrar yok, ağ yok, saat dilimi kullanıcının takvimine göre, banka büyüdükçe geçmiş bozulmuyor, %100 test edilebilir.

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

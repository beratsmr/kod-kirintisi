# CLAUDE.md

Bu dosya bu repoda çalışan her AI ajanı için bağlayıcıdır. Kod yazmadan önce oku.

## Proje

**Codestion** — iOS uygulaması. Her gün ana ekran widget'ında bir Swift/algoritma mini bulmacası gösterir. Kullanıcı soruyu **uygulamayı açmadan**, widget üzerindeki interaktif butonlarla cevaplar.

Detaylar: `docs/SPEC.md` (ürün) · `docs/ARCHITECTURE.md` (teknik) · `docs/SETUP.md` (ortam)

## Ortam — Bunu Anlamadan Kod Yazma

Geliştirici makinesinde **Xcode 26.6 kurulu** (2026-08-25 itibarıyla). iOS 26.5 SDK ve simülatörler mevcut, `xcodebuild` ile derleyip test koşabiliyoruz. Buna rağmen üç kural değişmedi:

1. **`.xcodeproj` / `.pbxproj` dosyasını elle oluşturma veya düzenleme, asla commit etme.** Proje `project.yml`'den XcodeGen ile üretilir ve `.gitignore`'dadır — `App/Info.plist`, `Widget/Info.plist` ve `.entitlements` dosyaları da öyle. Bir target'a dosya eklemen gerekiyorsa dosyayı doğru klasöre koy; `project.yml` yol bazlı çalıştığı için çoğu durumda başka bir şey gerekmez. `xcodegen generate` çalıştırmak serbesttir.

2. **`Core/` paketi Linux'ta derlenmeli ve test edilmeli.** Bu bir ortam kısıtı değil, mimari bir karar: hızlı ve platformsuz doğrulama döngüsü. `Core/Sources` altında şu import'lar **YASAK**: `UIKit`, `SwiftUI`, `WidgetKit`, `AppIntents`, `CoreSpotlight`, `UserNotifications`, `Combine`. Sadece `Foundation`. SwiftLint'te bunu zorlayan bir kural var.

3. **UI katmanı yine de ince olmalı.** Hesaplama, karar ve dönüşüm `Core`'a taşınır; view'lar `Core`'un ürettiği değerin saf bir fonksiyonu olur. Artık derleyerek doğrulayabiliyoruz ama SwiftUI'da derlenen kod doğru görünen kod demek değil — simülatörde gözle bak.

## Komutlar

```bash
swift build --package-path Core          # çekirdeği derle
swift test  --package-path Core          # çekirdeği test et  ← ana doğrulama döngüsü
swiftformat .                            # formatla
swiftlint lint                           # denetle
xcodegen generate                        # SADECE Xcode'lu makinede
```

## Kodlama Kuralları

- **Swift 6 dil modu, strict concurrency = complete.** `@unchecked Sendable` yasak; gerekiyorsa önce sor.
- **Sıfır üçüncü parti bağımlılık.** Yeni bir paket eklemek istiyorsan önce gerekçesiyle birlikte sor.
- **Kod ve yorumlar İngilizce.** Kullanıcıya görünen metinler `String(localized:)` ile, `en` ve `tr` lokalizasyonu.
- **Force unwrap (`!`) ve `try!` yasak.** Test kodunda dahi. `#require` veya `throws` kullan.
- **`print` yerine `os.Logger`.**
- Erişim seviyeleri açık yazılır. `Core`'da dışa açılan her şey `public`, geri kalanı `internal`.
- Bir dosya = bir ana tip. Dosya adı tipin adı.
- Model tipleri `struct` + `Sendable` + `Codable`. Sınıf sadece gerçekten referans semantiği gerektiğinde.
- Zaman ve rastgelelik **asla doğrudan okunmaz** — parametre olarak enjekte edilir (`Date`, `Calendar`, `seed`). Bu testlerin temeli.

## Test Kuralları

- Framework: **swift-testing** (`import Testing`, `@Test`, `#expect`, `#require`). XCTest sadece iOS target testlerinde.
- `Core`'a eklenen her public fonksiyonun testi olur. İstisna yok.
- Testler tarih/rastgelelik enjekte eder; `Date()` çağırmaz.
- Sınır durumlarını test et: yaz saati geçişi, yılbaşı, boş banka, tek elemanlı banka, saat dilimi değişimi.
- Hedef: `Core` için %80+ satır kapsamı.

## Definition of Done

Bir milestone'u bitirdim demeden önce hepsi sağlanmalı:

- [ ] `swift build --package-path Core` uyarısız geçiyor
- [ ] `swift test --package-path Core` tamamen yeşil
- [ ] `swiftformat --lint .` ve `swiftlint lint` temiz
- [ ] Yeni public API'lerin doc comment'i var
- [ ] Davranış değiştiyse `docs/` güncellendi
- [ ] Commit mesajı Conventional Commits formatında (`feat:`, `fix:`, `test:`, `refactor:`, `docs:`, `chore:`)

## Çalışma Şekli

1. Bir milestone'a başlamadan önce **3–5 maddelik planını yaz ve onay bekle.**
2. Milestone'ları sırayla yap, atlama. Her milestone kendi içinde çalışır durumda bitmeli.
3. Bir milestone içinde birden fazla commit yap; her commit tek bir işi yapsın.
4. Emin olmadığın ürün kararlarını **uydurma, sor.** (Örn. "streak yanlış cevapta kırılır mı?" → SPEC'te yoksa sor.)
5. Kapsam dışı iyileştirme yapma. Refactor önerin varsa söyle, onay al, sonra yap.

## Milestone'lar

Sırayla ilerle.

### M1 — Core domain (Xcode gerekmez)
`Core/Sources/KodKirintisiCore/Models/` altında `Puzzle`, `PuzzleCategory`, `Difficulty`, `AnswerRecord`, `UserProgress`.
`Bank/PuzzleBank.swift` — `Bundle.module`'den `puzzles.json` yükler, decode eder, **doğrular** (benzersiz id, geçerli `correctIndex`, `whyOthersWrong` uzunluğu, widget karakter limitleri).
Testler: decode, her doğrulama hatası için bir vaka, `puzzles.json` bütünlük testi.

### M2 — Seçim ve istatistik motoru (Xcode gerekmez)
`Scheduling/SeededRandom.swift` (SplitMix64) + `Scheduling/DailyPuzzleSelector.swift` — `docs/ARCHITECTURE.md §5`'teki algoritma.
`Stats/StreakCalculator.swift`, `Stats/StatsCalculator.swift`.
Testler: determinizm, `bank.count` gün boyunca tekrarsızlık, saat dilimi/DST sınırları, streak sınır durumları.

### M3 — Kalıcılık (Xcode gerekmez)
`Progress/ProgressStore.swift` — `ProgressPersisting` protokolü + `actor ProgressStore`.
`Progress/FileProgressStore.swift` — verilen bir `URL`'e atomik JSON yazma. Konteyner yolunu **kendisi bulmaz**, dışarıdan alır.
Testler: geçici klasörde yazma/okuma, bozuk dosyadan kurtulma, eşzamanlı yazma.

**M1–M3 bittiğinde uygulamanın tüm beyni hazır ve %100 test edilmiş olmalı. Buraya kadar Xcode'a hiç ihtiyaç yok.**

### M4 — İçerik
`Core/Sources/KodKirintisiCore/Resources/puzzles.json` dosyasını 120 soruya tamamla. Şema: `docs/puzzles.schema.json`. Kategori dağılımı dengeli olsun, zorluk 1/2/3 oranı kabaca 40/50/30.
Her soru `PuzzleBankIntegrityTests`'ten geçmeli.

### M5 — Widget
`Widget/Sources/` — `DailyPuzzleTimelineProvider` (iki entry: şimdi + gece yarısı), small / medium / accessoryRectangular görünümleri, `ControlWidget`.
`Shared/Intents/AnswerPuzzleIntent.swift` — widget'tan cevaplama, sonra `WidgetCenter.shared.reloadTimelines`.

### M6 — Uygulama ekranları
Bugün, Arşiv, İstatistik (Swift Charts), Ayarlar. `Shared/DesignSystem/` içinde ortak kart görünümü.

### M7 — Sistem entegrasyonları
App Intents + `AppShortcutsProvider`, CoreSpotlight indeksleme, günlük local notification.

### M8 — Yayına hazırlık
App icon, App Store ekran görüntüleri, gizlilik bildirimi (veri toplamıyoruz), README'ye mimari diyagramı ve widget GIF'i, CI rozeti.

## Bilinen Tuzaklar

- **App Group id her iki target'ta aynı olmalı:** `group.com.beratsumer.kodkirintisi`. Uyuşmazsa widget boş görünür ve hata vermez.
- **Widget yenileme bütçesi sınırlı.** Timeline provider'da ağır iş yapma, ağ çağrısı yapma (zaten yok), banka yüklemesini cache'le.
- **İnteraktif widget butonları yalnızca `AppIntent` ile çalışır**, kapanış (closure) ile değil. `Button(intent:)` kullan.
- **`Bundle.module` widget extension içinde de çalışır** çünkü SPM kaynak paketi extension'a da gömülür — ama target bağımlılığının `project.yml`'de tanımlı olduğundan emin ol.
- **Widget stringlerini kendi bundle'ında arar, uygulamanınkinde değil.** `Text("...")` ve `LocalizedStringResource` `Bundle.main`'e çözülür; extension içinde `Bundle.main` widget'ın kendi bundle'ıdır. Bu yüzden `Shared/Localizable.xcstrings` her iki target'ın da kaynağıdır (ikisi de `- path: Shared` içerdiği için otomatik) ve widget'ın Info.plist'i de `CFBundleLocalizations`'ı ayrıca beyan eder. Eksik bırakılırsa uygulama Türkçe, widget İngilizce olur — **hata vermeden**, tıpkı App Group tuzağı gibi. Yeni bir kullanıcı metni eklerken catalog'a girdiğini simülatörde Türkçe dilde doğrula.
- **Gün sınırı kullanıcının takvimine göre.** `Calendar.current` enjekte edilir; UTC varsayma.
- **Bankaya soru sadece SONA ve 30'ar 30'ar eklenir.** Ortaya ekleme veya silme, kullanıcıların geçmiş günlerinin sorusunu değiştirir. Sona eklemek ise ancak banka 30'un (`DailyPuzzleSelector.blockSize`) tam katı kaldığı sürece güvenlidir: takvim blok blok karıştırılır, yarım kalan bir blok sonraki sürümde tamamlanınca içindeki günler kayar. `PuzzleBankIntegrityTests` bunu zorlar. Gerekçe: `docs/SPEC.md` §8.

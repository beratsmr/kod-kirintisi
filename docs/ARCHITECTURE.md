# Mimari

## 1. Temel Karar: "Linux'ta Test Edilebilir Çekirdek"

Elimizde Xcode'suz bir Mac var. Bu bir kısıt gibi görünüyor ama **iyi bir mimariyi zorluyor**:

> Tüm iş mantığı, UIKit/SwiftUI/WidgetKit'e dokunmayan saf bir Swift paketinde (`Core/`) yaşar. Bu paket Linux'ta derlenir ve test edilir. Xcode sadece **ekranı çizmek** için gerekir.

Pratik sonuçları:

- Xcode olmadan `swift test --package-path Core` çalışır → günlük geliştirme döngüsü VS Code'da tamamlanır.
- CI'da Ubuntu üzerinde testler saniyeler içinde koşar (ücretsiz ve hızlı).
- Mülakatta anlatacak somut bir mimari gerekçe olur: "platform bağımsız çekirdek + ince UI katmanı".

**Kural:** `Core/Sources` altında `import UIKit`, `import SwiftUI`, `import WidgetKit`, `import AppIntents`, `import CoreSpotlight` **yasak**. Sadece `Foundation`.

## 2. Katmanlar

```
┌──────────────────────────────────────────────────────────┐
│  KodKirintisi (iOS App)          KodKirintisiWidget      │
│  SwiftUI ekranları               WidgetKit timeline'ları │
│  Swift Charts                    İnteraktif AppIntent'ler│
│  CoreSpotlight indeksleme        ControlWidget           │
│  Bildirimler                                             │
└───────────────┬──────────────────────────┬───────────────┘
                │      Shared/ (iOS)       │
                │  AppGroup.swift          │
                │  AppIntents (paylaşımlı) │
                │  DesignSystem/           │
                └────────────┬─────────────┘
                             │
                ┌────────────▼─────────────┐
                │  KodKirintisiCore (SPM)  │
                │  · Model'ler (Codable)   │
                │  · PuzzleBank (yükleyici)│
                │  · DailyPuzzleSelector   │
                │  · StreakCalculator      │
                │  · StatsCalculator       │
                │  · ProgressStore (actor) │
                │  Foundation'dan başka    │
                │  hiçbir bağımlılık yok   │
                └──────────────────────────┘
```

## 3. Klasör Yapısı

```
kod-kirintisi/
├── CLAUDE.md                  # Claude Code'un uyacağı kurallar
├── README.md
├── project.yml                # XcodeGen — .xcodeproj bundan üretilir
├── .gitignore                 # *.xcodeproj git'e GİRMEZ
├── .swiftlint.yml
├── .swiftformat
├── .github/workflows/ci.yml
├── docs/
│   ├── SPEC.md
│   ├── ARCHITECTURE.md
│   └── SETUP.md
├── Core/                      # ← Platform bağımsız SPM paketi
│   ├── Package.swift
│   ├── Sources/KodKirintisiCore/
│   │   ├── Models/
│   │   │   ├── Puzzle.swift
│   │   │   ├── PuzzleCategory.swift
│   │   │   ├── Difficulty.swift
│   │   │   ├── AnswerRecord.swift
│   │   │   └── UserProgress.swift
│   │   ├── Bank/
│   │   │   ├── PuzzleBank.swift          # JSON yükleme + doğrulama
│   │   │   └── PuzzleBankError.swift
│   │   ├── Scheduling/
│   │   │   ├── DailyPuzzleSelector.swift # deterministik seçim
│   │   │   └── SeededRandom.swift        # SplitMix64
│   │   ├── Progress/
│   │   │   ├── ProgressStore.swift       # actor + protokol
│   │   │   └── FileProgressStore.swift   # atomik yazma
│   │   ├── Stats/
│   │   │   ├── StreakCalculator.swift
│   │   │   └── StatsCalculator.swift
│   │   └── Resources/
│   │       └── puzzles.json              # 120 soru
│   └── Tests/KodKirintisiCoreTests/
│       ├── DailyPuzzleSelectorTests.swift
│       ├── StreakCalculatorTests.swift
│       ├── StatsCalculatorTests.swift
│       ├── ProgressStoreTests.swift
│       └── PuzzleBankIntegrityTests.swift  # gerçek bankayı doğrular
├── Shared/                    # App + Widget target'larının ikisine de girer
│   ├── AppGroup.swift
│   ├── Intents/
│   │   ├── AnswerPuzzleIntent.swift
│   │   ├── RevealAnswerIntent.swift
│   │   ├── ShowTodaysPuzzleIntent.swift
│   │   └── AppShortcuts.swift
│   └── DesignSystem/
│       ├── Theme.swift
│       └── PuzzleCardView.swift
├── App/
│   ├── Sources/
│   │   ├── KodKirintisiApp.swift
│   │   ├── Features/Today/
│   │   ├── Features/Archive/
│   │   ├── Features/Stats/
│   │   ├── Features/Settings/
│   │   ├── Services/SpotlightIndexer.swift
│   │   └── Services/NotificationScheduler.swift
│   ├── Resources/Assets.xcassets
│   └── Tests/                 # sadece iOS'a bağımlı testler
└── Widget/
    └── Sources/
        ├── KodKirintisiWidgetBundle.swift
        ├── DailyPuzzleWidget.swift
        ├── DailyPuzzleTimelineProvider.swift
        ├── Views/
        └── TodaysPuzzleControl.swift    # Control Center
```

## 4. Veri Akışı ve Paylaşım

Uygulama ve widget **ayrı process'ler**. Ortak durum App Group konteynerinde bir dosyada tutulur.

```
App Group: group.com.beratsumer.kodkirintisi
└── progress.json    ← FileProgressStore (atomik yazma, actor ile serileştirilmiş)
```

- `Core` bu konteynerin nerede olduğunu **bilmez**; kendisine bir `URL` verilir (dependency injection). Testlerde geçici klasör verilir → Linux'ta çalışır.
- Widget cevap yazdığında `WidgetCenter.shared.reloadTimelines(ofKind:)` çağırır; uygulama öne geldiğinde store'u yeniden okur.
- Yazma çakışmasını önlemek için `ProgressStore` bir `actor`; dosyaya yazma `Data.write(to:options: .atomic)` ile yapılır.

**Neden SwiftData/Core Data değil?** İki process'in aynı store'a yazması ek karmaşıklık getirir, üstelik Linux'ta test edilemez. Veri hacmi küçük (birkaç yüz kayıt). v1.1'de CloudKit senkronizasyonu eklenirken bu katman değişebilir; `ProgressPersisting` protokolü o değişimi izole ediyor.

## 5. Kritik Bileşenler

### `DailyPuzzleSelector` (saf fonksiyon)

```swift
public struct DailyPuzzleSelector: Sendable {
    public static let epoch = DateComponents(year: 2026, month: 1, day: 1)

    public init?(seed: UInt64, puzzleCount: Int)   // boş banka → nil
    public func index(for date: Date, calendar: Calendar) -> Int
    public func dayIndex(for date: Date, calendar: Calendar) -> Int
}
```

Başlatıcı `init?`: boş bir banka üzerinde seçilecek soru yoktur, bu yüzden geçersiz durum çağrı anında elenir ve `index(for:)` opsiyonel dönmek zorunda kalmaz.

Karıştırma `shuffled(using:)` ile değil, elle yazılmış Fisher-Yates ile yapılır — standart kütüphane karıştırma algoritmasının sürümler arası sabit kalacağına söz vermiyor; değişseydi her kullanıcının takvimi bir güncellemeden sonra sessizce kayardı.

Yan etkisi yok, zaman okumuyor (tarih parametre olarak geliyor), rastgelelik tohumlu. **Test edilmesi çok kolay** — bu yüzden bu şekilde tasarlandı.

Test edilmesi gerekenler: aynı gün → aynı sonuç · ardışık `bank.count` gün → tekrar yok · saat dilimi değişimi gün sınırını kaydırmalı · `bank.count` değişince eski günler bozulmamalı (bankaya soru **sadece sona eklenir**).

### `StreakCalculator`

```swift
public enum StreakCalculator {
    public static func day(for date: Date, calendar: Calendar) -> DateComponents
    public static func correctDays(
        from records: some Sequence<AnswerRecord>, calendar: Calendar
    ) -> Set<DateComponents>
    public static func currentStreak(
        correctlyAnsweredDays: Set<DateComponents>, today: Date, calendar: Calendar
    ) -> Int
    public static func longestStreak(
        correctlyAnsweredDays: Set<DateComponents>, calendar: Calendar
    ) -> Int
}
```

Parametre `answeredDays` değil `correctlyAnsweredDays`: SPEC §5.2'deki karara göre yanlış cevap streak'i kırar, yani kümeye yalnızca doğru cevaplanan günler girer. Ad bunu çağrı yerinde görünür kılıyor — yanlış kümeyi geçirmek aksi halde fark edilmesi çok zor bir hata olurdu. Küme anahtarları `day(for:calendar:)` ile üretilmeli.

Sınır durumları: bugün cevaplanmadı ama dün cevaplandı → streak korunur · iki gün boşluk → sıfırlanır · yaz saati geçişi · yılbaşı.

### `PuzzleBank`

`Bundle.module` üzerinden `puzzles.json`'u yükler, `Puzzle` dizisine decode eder ve **doğrular**: `id` benzersiz mi, `correctIndex` sınırlar içinde mi, `whyOthersWrong` uzunluğu `choices` ile eşleşiyor mu, widget karakter limitleri aşılmış mı. Doğrulama hatası `PuzzleBankError` fırlatır ve `PuzzleBankIntegrityTests` bunu CI'da yakalar — yani bozuk içerik asla App Store'a çıkamaz.

### Widget timeline

`DailyPuzzleTimelineProvider` yalnızca **iki entry** üretir: şimdi ve bir sonraki gece yarısı. Sistem widget yenilemelerini kısıtlıyor; günde iki entry bütçeye rahat sığar. Provider içinde ağır iş yapılmaz — banka yüklemesi `PuzzleBank.shared` üzerinden lazy ve cache'lidir.

## 6. Eşzamanlılık

Swift 6 dil modu, `SWIFT_STRICT_CONCURRENCY = complete`.

- `Core`'daki tüm model tipleri `Sendable` (değer tipleri, `let` alanlar).
- Paylaşımlı mutasyon sadece `ProgressStore` actor'ünde.
- `@unchecked Sendable` kullanımı yasak — gerekiyorsa önce tartışılır.
- UI tipleri `@MainActor`.

## 7. Test Stratejisi

| Katman | Araç | Nerede koşar | Hedef |
|---|---|---|---|
| Core iş mantığı | `swift-testing` (`import Testing`) | Linux + macOS | %80+ kapsam, zorunlu |
| Banka bütünlüğü | `swift-testing` | Linux + macOS | 120 sorunun tamamı doğrulanır |
| App/Widget | XCTest | sadece macOS | smoke seviyesi, opsiyonel |
| Snapshot | — | — | v1.0 kapsamı dışında |

Karar: **Sadece Core testleri zorunlu.** UI testleri yavaş, kırılgan ve Mac gerektiriyor; bu projede getirisi maliyetini karşılamıyor.

## 8. Proje Dosyası Yönetimi

`.xcodeproj` **git'e girmez**, `project.yml`'den üretilir:

```bash
xcodegen generate
```

`project.yml`'in `info:` ve `entitlements:` blokları da dosya üretir — `App/Info.plist`, `Widget/Info.plist` ve iki `.entitlements` dosyası. Bunlar da türetilmiş çıktıdır ve `.gitignore`'dadır; elle düzenlenmez, kaynakları `project.yml`'dir.

Bunun anlamı:
- Yeni dosya eklemek için Xcode'u açmak gerekmez — dosyayı doğru klasöre koy, `sources` yol bazlı olduğu için çoğu durumda yeter.
- `.pbxproj` merge çakışması diye bir sorun yok.
- Proje yapısı okunabilir ve code review edilebilir.

**Claude Code asla `.xcodeproj` veya `.pbxproj` oluşturmayacak/düzenlemeyecek.**

## 9. Sürüm Hedefleri

| | Değer | Gerekçe |
|---|---|---|
| Deployment target | **iOS 18.0** | `ControlWidget` (Control Center) iOS 18 ile geldi; interaktif widget iOS 17. iOS 26 çıktıktan sonra iOS 18 tabanı kullanıcıların neredeyse tamamını kapsıyor. |
| Swift | 6.x (Xcode 26.x ile gelen) | Strict concurrency, `swift-testing` yerleşik |
| Xcode | 26.x | Güncel App Store gereksinimi |
| Bağımlılık | **Sıfır** | Üçüncü parti paket yok. Sadece Apple framework'leri. |

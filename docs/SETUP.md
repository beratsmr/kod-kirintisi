# Kurulum

Bu proje iki farklı doğrulama döngüsü kullanır:

| Döngü | Neyi doğrular | Gereken |
|---|---|---|
| `swift test --package-path Core` | Uygulamanın tüm mantığı | Sadece Swift toolchain (saniyeler sürer) |
| `xcodebuild` + simülatör | Widget, ekranlar, sistem entegrasyonları | Xcode |

Günlük geliştirmenin çoğu birincisinde geçer. İkincisi bir milestone'u kapatmadan önce çalıştırılır.

---

## Adım 1 — Swift Toolchain

Xcode kuruluysa toolchain de var, ekstra bir şey gerekmez. Değilse Command Line Tools yeterli:

```bash
xcode-select --install
swift --version   # Swift 6.x görmelisin
```

> **Not:** Bu makinede Xcode 26.6 kurulu (2026-08-25). `/usr/bin/swift` CLT 6.3.3'e bakıyor ve `Core/` paketi için yeterli.
> Geçmişte `~/.zshrc` içinde `DEVELOPER_DIR` ve `XCODE_DEFAULT_TOOLCHAIN_OVERRIDE` değişkenleri Command Line Tools'a sabitlenmişti; bunlar `xcodebuild`'i tamamen bozuyordu ve kaldırıldı. Benzer bir şey eklemeden önce iki kez düşün.

## Adım 2 — Yardımcı Araçlar

```bash
brew install xcodegen swiftlint swiftformat gh
```

| Araç | Ne işe yarıyor |
|---|---|
| `xcodegen` | `project.yml`'den `.xcodeproj` üretir — proje dosyası git'te tutulmadığı için şart |
| `swiftlint` | Kod stil denetimi |
| `swiftformat` | Otomatik formatlama |
| `gh` | GitHub CLI (repo oluşturma, PR) |

**Homebrew yoksa** (bu makinede yok) XcodeGen'i kaynaktan kurabilirsin:

```bash
git clone https://github.com/yonaskolb/XcodeGen.git /tmp/XcodeGen
cd /tmp/XcodeGen && swift build -c release
mkdir -p ~/.local/bin ~/.local/share/xcodegen
cp .build/release/xcodegen ~/.local/bin/
cp -R SettingPresets ~/.local/share/xcodegen/
```

`make install` kullanma — universal binary üretmeye çalışır ve `xcbuild` gerektirir, güncel Xcode'da yok. `~/.local/bin`'in `PATH`'te olduğundan emin ol.

## Adım 3 — VS Code Eklentileri

```bash
code --install-extension swiftlang.swift-vscode
code --install-extension vknabel.vscode-swiftformat
code --install-extension GitHub.vscode-github-actions
code --install-extension anthropic.claude-code
```

`swiftlang.swift-vscode` içinde SourceKit-LSP var: otomatik tamamlama, "go to definition", hata gösterimi, test çalıştırma. `Core/` paketi için fazlasıyla yeterli.

**VS Code ayarı** (`.vscode/settings.json` — repoda hazır):
```json
{
  "swift.autoGenerateLaunchConfigurations": false,
  "swift.searchSubfoldersForPackages": true,
  "editor.formatOnSave": true
}
```

## Adım 4 — Repoyu Kur

```bash
cd ~/Developer
cd kod-kirintisi

git init
git add .
git commit -m "chore: project scaffold, spec and tooling"

gh repo create kod-kirintisi --public --source=. --push
```

> Repoyu **public** yap — CV'de link vereceğin şey bu. Public repolarda GitHub Actions'ın macOS runner'ları da ücretsiz.

## Adım 5 — Çalıştığını Doğrula

```bash
swift build --package-path Core
swift test  --package-path Core

xcodegen generate
xcodebuild -project KodKirintisi.xcodeproj -scheme KodKirintisi \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

---

## Günlük Geliştirme Döngüsü

```bash
swift test --package-path Core     # mantığı doğrula — ana döngü, hızlı
swiftformat . && swiftlint lint    # temizle
git commit -m "..."
```

Bir milestone'u kapatmadan önce ayrıca:

```bash
xcodegen generate
xcodebuild -project KodKirintisi.xcodeproj -scheme KodKirintisi \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

`xcodegen generate` her `project.yml` değişikliğinden ve her `git pull`'dan sonra çalıştırılmalı — `.xcodeproj` git'te tutulmuyor.

## Simülatörde Gözle Doğrulama

Derlenen kod doğru **görünen** kod demek değil. Widget'ı ve ekranları en az bir kere gerçekten gör:

```bash
xcodebuild -project KodKirintisi.xcodeproj -scheme KodKirintisi \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
open -a Simulator
```

Sonra simülatörde:
1. Uygulamayı bir kez çalıştır (App Group konteynerini oluşturur).
2. Ana ekranda boş bir alana uzun bas → **+** → "Codestion" → small ve medium boyutları ekle.
3. Kilit ekranı için: Ayarlar → Duvar Kâğıdı → Özelleştir → widget alanı → accessoryRectangular'ı ekle.
4. Widget üzerindeki bir şıkka dokun. Doğru/yanlış işareti belirmeli, butonlar kaybolmalı, seri sayacı güncellenmeli.
5. Uygulamayı aç ve widget'ta verilen cevabın orada da göründüğünü doğrula (App Group paylaşımının asıl testi bu).

> Widget boş görünüyorsa ve hata yoksa: App Group id'si iki target'ta uyuşmuyordur. Bkz. CLAUDE.md "Bilinen Tuzaklar".

### Türkçe Arayüzü Doğrulamak

Arayüz iki dilli (`Shared/Localizable.xcstrings`), soru içeriği İngilizce.
Yeni bir kullanıcı metni eklediğinde Türkçesinin gerçekten göründüğünü
doğrula — catalog'a girmemiş bir string sessizce İngilizce kalır, derleme
uyarı vermez.

Tek bir çalıştırma için cihazın dilini değiştirmeye gerek yok:

```bash
xcrun simctl launch <device> com.beratsumer.kodkirintisi \
  -AppleLanguages "(tr)" -AppleLocale "tr_TR"
```

Dört ekranı birden Türkçe görmek için ekran görüntüsü scriptini o dilde koş:

```bash
./scripts/make-screenshots.sh "iPhone 17 Pro" tr
```

Çıktı geçici bir klasöre yazılır ve yolu ekrana basılır; mağaza listesi İngilizce
olduğu için `docs/screenshots/` sadece `en` koşusuyla güncellenir.

> `-testLanguage tr` **işe yaramaz.** XCTest onu `launchArguments`'a enjekte
> ediyor, test kendi `-AppleLanguages`'ını sonradan ekliyor ve argüman alanında
> son yazan kazanıyor — bayrak sessizce yutuluyor. Bu yüzden her dilin ayrı bir
> test metodu var ve script `-only-testing:` ile birini seçiyor.

Widget ayrı bir mesele: stringleri **kendi** bundle'ından okur ve uygulamanın
launch argümanlarını görmez. Onu Türkçe görmek için cihazın dilini değiştirmek
gerekir:

```bash
xcrun simctl spawn booted defaults write .GlobalPreferences AppleLanguages -array tr
xcrun simctl spawn booted defaults write .GlobalPreferences AppleLocale -string tr_TR
xcrun simctl shutdown booted && xcrun simctl boot <device>
```

Yeniden başlatma ana ekran düzenini sıfırlar, yani widget'ı tekrar yerleştirmen
gerekir — `simctl`'de karşılığı olmayan adım bu. Dili geri almak için aynı
komutları `en` / `en_US` ile çalıştır.

Çevirinin widget bundle'ına gerçekten girdiğini gözle bakmadan da
doğrulayabilirsin; sessiz İngilizce'ye düşme tuzağı tam olarak burada yakalanır:

```bash
plutil -p "$(find ~/Library/Developer/Xcode/DerivedData/KodKirintisi-*/Build/Products/\
Debug-iphonesimulator -name KodKirintisiWidget.appex)/tr.lproj/Localizable.strings"
```

## Yayın Görsellerini Üretmek

App Store'a giden her görsel repodaki bir script tarafından üretilir; hiçbiri elle çizilmez. Böylece çıktı da kaynak kodu gibi gözden geçirilebilir ve tekrar üretilebilir olur.

```bash
./scripts/make-app-icon.swift        # ikonu yeniden çizer (PNG commit'lenir)
./scripts/make-screenshots.sh        # App Store ekran görüntüleri → docs/screenshots/
./scripts/record-widget.sh           # README için widget GIF'i → docs/widget.gif
```

Ekran görüntüleri, uygulamayı gerçekten çalıştıran bir UI testinden alınır — sahte view'lardan değil. Temiz bir kurulumda arşivde tek satır, istatistiklerde sıfır göründüğü için test uygulamayı `-KodKirintisiDemoContent` bayrağıyla başlatır; `DemoContent` de 42 günlük makul bir cevap geçmişini gerçek konteynere yazar. Bu tipin gövdesi yalnızca `DEBUG` altında derlenir, dolayısıyla App Store binary'sinde hiç bulunmaz.

`record-widget.sh` tek bir manuel adım içerir: widget'ı ana ekrana yerleştirmek. `simctl`'de bunun karşılığı yok, o yüzden script durup sorar. GIF dönüşümü ffmpeg değil AVFoundation + ImageIO kullanır; ek kurulum gerekmez.

Ekran görüntüsü şeması (`Screenshots`) bilerek `KodKirintisi` şemasından ayrı tutuldu: booted bir simülatör gerektiriyor ve dakikalar sürüyor, günlük test döngüsü ve CI bunun bedelini ödememeli.

## İmzalama

`project.yml`'de `DEVELOPMENT_TEAM` boş. Simülatör için gerekmez. Gerçek cihaza atmak istediğinde Xcode'da **Signing & Capabilities** → Team seç (ücretsiz Apple ID yeterli); App ve Widget target'larının ikisinde de.

---

## Sorun Giderme

**`swift: command not found`** → `xcode-select -p` yanlış yeri gösteriyor. `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`

**`xcodebuild` "unable to find utility" veya SDK bulamıyor diyor** → `env | grep -i developer_dir`. `DEVELOPER_DIR` Command Line Tools'a sabitlenmişse `xcodebuild` hiç çalışmaz; kaldır.

**`could not build Objective-C module '_Builtin_float'`** → Eski bir toolchain (örn. swiftly ile kurulmuş 6.0.x) yeni SDK'yı derlemeye çalışıyor. `which swift` ile kontrol et; `/usr/bin/swift` kullan.

**`Could not find test host for KodKirintisiTests`** → `PRODUCT_NAME` hâlâ "Kod Kırıntısı" (boşluklu) ve XcodeGen'in türettiği varsayılan `TEST_HOST` yolu tutmuyor. `project.yml`'de açıkça yazılı; silme. Uygulamanın **görünen** adı Codestion, ama o ayrı bir alan (`CFBundleDisplayName`) — diskteki `.app` eski adı taşımaya devam ediyor ve betikler o yola bakıyor.

**İmzalama hatası veriyor** → `DEVELOPMENT_TEAM` `project.yml`'de tanımlı; Xcode'un Signing sekmesinden seçme, orada yapılan seçim ilk `xcodegen generate`'te silinir. Sertifika yoksa Xcode → Settings → Accounts'tan Apple ID ile giriş yap.

**VS Code'da SwiftUI dosyalarında yüzlerce hata** → Beklenen. SourceKit-LSP macOS SDK'sına bakıyor, iOS-only API'leri göremiyor. Bu hatalar sahte; gerçek doğrulama `xcodebuild` ile. `Core/` içinde hata görürsen o gerçektir.

**CI'da Linux job'ı `import Testing` bulamıyor** → Docker imajını daha yeni bir Swift sürümüne yükselt (`.github/workflows/ci.yml`).

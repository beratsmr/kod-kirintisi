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
2. Ana ekranda boş bir alana uzun bas → **+** → "Kod Kırıntısı" → small ve medium boyutları ekle.
3. Kilit ekranı için: Ayarlar → Duvar Kâğıdı → Özelleştir → widget alanı → accessoryRectangular'ı ekle.
4. Widget üzerindeki bir şıkka dokun. Doğru/yanlış işareti belirmeli, butonlar kaybolmalı, seri sayacı güncellenmeli.
5. Uygulamayı aç ve widget'ta verilen cevabın orada da göründüğünü doğrula (App Group paylaşımının asıl testi bu).

> Widget boş görünüyorsa ve hata yoksa: App Group id'si iki target'ta uyuşmuyordur. Bkz. CLAUDE.md "Bilinen Tuzaklar".

## İmzalama

`project.yml`'de `DEVELOPMENT_TEAM` boş. Simülatör için gerekmez. Gerçek cihaza atmak istediğinde Xcode'da **Signing & Capabilities** → Team seç (ücretsiz Apple ID yeterli); App ve Widget target'larının ikisinde de.

---

## Sorun Giderme

**`swift: command not found`** → `xcode-select -p` yanlış yeri gösteriyor. `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`

**`xcodebuild` "unable to find utility" veya SDK bulamıyor diyor** → `env | grep -i developer_dir`. `DEVELOPER_DIR` Command Line Tools'a sabitlenmişse `xcodebuild` hiç çalışmaz; kaldır.

**`could not build Objective-C module '_Builtin_float'`** → Eski bir toolchain (örn. swiftly ile kurulmuş 6.0.x) yeni SDK'yı derlemeye çalışıyor. `which swift` ile kontrol et; `/usr/bin/swift` kullan.

**`Could not find test host for KodKirintisiTests`** → Ürün adı "Kod Kırıntısı" (boşluklu), XcodeGen'in türettiği varsayılan `TEST_HOST` yolu tutmuyor. `project.yml`'de açıkça yazılı; silme.

**`xcodegen generate` "Team not found" hatası veriyor** → Normal. `DEVELOPMENT_TEAM` boş; imzalamayı Xcode'da elle seç.

**VS Code'da SwiftUI dosyalarında yüzlerce hata** → Beklenen. SourceKit-LSP macOS SDK'sına bakıyor, iOS-only API'leri göremiyor. Bu hatalar sahte; gerçek doğrulama `xcodebuild` ile. `Core/` içinde hata görürsen o gerçektir.

**CI'da Linux job'ı `import Testing` bulamıyor** → Docker imajını daha yeni bir Swift sürümüne yükselt (`.github/workflows/ci.yml`).

# Kurulum — Xcode'suz Mac + VS Code Akışı

Senin durumun: **Mac var, Xcode kurulu değil, VS Code var.** İyi haber — bu projenin %90'ını Xcode olmadan yazıp test edebilirsin. Xcode sadece uygulamayı simülatörde çalıştırmak ve App Store'a yüklemek için gerekiyor.

---

## Adım 1 — Command Line Tools (Xcode DEĞİL)

Bu ~2 GB, Xcode ise ~20 GB. Sana Swift derleyicisini ve `swift` CLI'ı veriyor:

```bash
xcode-select --install
```

Kurulum bitince doğrula:

```bash
swift --version   # Swift 6.x görmelisin
```

> `swift` komutu çalışıyorsa `Core/` paketini derleyebilir ve test edebilirsin. Günlük geliştirmenin tamamı burada geçecek.

## Adım 2 — Homebrew ve Araçlar

```bash
# Homebrew yoksa:
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew install xcodegen swiftlint swiftformat gh
```

| Araç | Ne işe yarıyor |
|---|---|
| `xcodegen` | `project.yml`'den `.xcodeproj` üretir — Xcode'suz proje tanımlamanı sağlayan şey bu |
| `swiftlint` | Kod stil denetimi |
| `swiftformat` | Otomatik formatlama |
| `gh` | GitHub CLI (repo oluşturma, PR) |

## Adım 3 — VS Code Eklentileri

```bash
code --install-extension swiftlang.swift-vscode
code --install-extension vknabel.vscode-swiftformat
code --install-extension GitHub.vscode-github-actions
code --install-extension anthropic.claude-code
```

`swiftlang.swift-vscode` içinde SourceKit-LSP var: otomatik tamamlama, "go to definition", hata gösterimi, test çalıştırma. Xcode'a benzemez ama Core paketi için fazlasıyla yeterli.

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
cd ~/Developer          # ya da nerede tutuyorsan
# bu paketi buraya açtıysan:
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
```

İlk çalıştırmada `Core/Sources` boş olduğu için hata alabilirsin — bu normal, ilk görev orayı doldurmak (bkz. CLAUDE.md, M1).

## Adım 6 — Claude Code ile Başla

```bash
cd kod-kirintisi
claude
```

İlk mesajın şu olsun:

```
CLAUDE.md, docs/SPEC.md ve docs/ARCHITECTURE.md dosyalarını oku.
Sonra M1 (Core domain) milestone'unu uygula.
Kod yazmadan önce 3-5 maddelik planını söyle ve onayımı bekle.
```

Claude Code `CLAUDE.md`'yi otomatik okur, ama ilk turda açıkça belirtmek işi garantiye alır.

---

## Günlük Geliştirme Döngüsü (Mac, Xcode yok)

```bash
swift test --package-path Core     # mantığı doğrula
swiftformat . && swiftlint         # temizle
git add -A && git commit -m "..."  # kaydet
git push
```

Bu döngü M1–M3 arasındaki tüm işi kapsıyor. UI yazarken de kod yazabilirsin, sadece **görsel doğrulamayı** ertelersin.

## Xcode'lu Makinede Doğrulama

Diğer bilgisayarda, ilk seferde:

```bash
git clone https://github.com/<kullanıcı-adın>/kod-kirintisi.git
cd kod-kirintisi
brew install xcodegen
xcodegen generate
open KodKirintisi.xcodeproj
```

Sonraki her seferde:

```bash
git pull && xcodegen generate && open KodKirintisi.xcodeproj
```

Xcode'da yapılacaklar (bir kereye mahsus):
1. **Signing & Capabilities** → Team seç (ücretsiz Apple ID yeterli, test için).
2. App ve Widget target'larının ikisinde de **App Groups** capability'sinin `group.com.beratsumer.kodkirintisi` ile eşleştiğini doğrula.
3. Simülatörde çalıştır, ana ekrana widget ekle, test et.

Bulduğun sorunları not al, kendi makinene dön, VS Code'da düzelt, push et.

> ⚠️ Xcode'lu makinede **kod yazma**. Orada sadece derle ve test et. İki makinede paralel değişiklik yaparsan merge işkencesi başlar.

## Xcode'u Kendi Makinene Kurmak İstersen

Er ya da geç kuracaksın (App Store'a yüklemek için şart). En kolay yol:

```bash
brew install --cask xcodes
xcodes install --latest
```

`xcodes` sürüm yönetimini kolaylaştırır ve App Store'dan indirmekten daha hızlıdır. ~20 GB boş alan gerekiyor.

---

## Sorun Giderme

**`swift: command not found`** → Command Line Tools kurulmamış veya `xcode-select -p` yanlış yeri gösteriyor. `sudo xcode-select --switch /Library/Developer/CommandLineTools`

**`xcodegen generate` "Team not found" hatası veriyor** → Normal. `project.yml`'de `DEVELOPMENT_TEAM` boş; imzalamayı Xcode'da elle seç.

**VS Code'da SwiftUI dosyalarında yüzlerce hata** → Beklenen. SourceKit-LSP macOS SDK'sına bakıyor, iOS-only API'leri göremiyor. Bu hatalar sahte; gerçek derleme Xcode'da yapılıyor. `Core/` içinde hata görürsen o gerçektir.

**CI'da Linux job'ı `import Testing` bulamıyor** → Docker imajını daha yeni bir Swift sürümüne yükselt (`.github/workflows/ci.yml`).

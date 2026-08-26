# Privacy Policy — Kod Kırıntısı

**Effective 26 August 2026.**

Kod Kırıntısı collects nothing. There is no account, no server, no analytics
and no advertising. The app contains no networking code at all: every puzzle
ships inside the app bundle, and every answer stays on your device.

This document describes exactly what is stored and where, so the claim above
can be checked rather than taken on trust. The source is public — the
statements below are all verifiable in it.

## What is stored on your device

| What | Where | Why |
| --- | --- | --- |
| A random number generated at install | App Group container | Decides which puzzle you get on which day, so two people installing on the same day do not get the same order. It is not derived from anything about you or your device. |
| The date you installed the app | App Group container | Day zero of your puzzle schedule. |
| For each puzzle you answered: which option you chose and when | App Group container | Powers the archive, your streak and the statistics screen. |
| Notification time, whether reminders are on, which categories you excluded | App preferences | Your settings. |
| The title, question and tags of puzzles you have unlocked | The system Spotlight index | So you can find a past puzzle from iOS search. Your answers are never indexed — only the puzzle text, which ships with the app anyway. This index is maintained by iOS on your device. |

The App Group container is an ordinary folder that belongs to the app, shared
only between the app and its widget. It is included in your device backups if
you back up your device, and it is removed when you delete the app.

## What leaves your device

Nothing that the app sends by itself.

One case is worth naming explicitly: some puzzle explanations link to official
documentation, such as the Swift book or Apple's developer site. If **you** tap
one of those links, iOS opens it in your browser, and from that point the
destination website sees an ordinary web visit the same way it would if you had
typed the address yourself. The app does not add anything to those requests and
is not involved after the link opens.

## What is never touched

No location. No contacts, photos, calendar, microphone or camera. No health
data. No advertising identifier — the app does not link the AdSupport or
AppTrackingTransparency frameworks, so it could not track you across other apps
even if it wanted to. No third-party SDKs of any kind: the app has zero
external dependencies.

## Deleting your data

Two ways, both immediate and complete:

- **Settings → Reset Progress** inside the app clears every answer you have
  recorded and starts a fresh schedule.
- **Deleting the app** removes the container and everything in it.

There is nothing to request from us, because there is nothing held anywhere
else.

## Children

The app is safe for any age. Since nothing is collected, nothing about a child
user is collected either.

## Changes

If a future version ever collected anything, this document would be updated
before that version shipped, and the change would be described in the release
notes rather than made quietly.

## Contact

Questions and privacy requests: open an issue at
<https://github.com/beratsmr/kod-kirintisi/issues>.

This is deliberately a public issue tracker rather than an email address. There
is no personal data to ask us about — nothing leaves your device — so anything
worth asking is worth answering in the open, where the next person can read it
too.

---

## App Store Connect — App Privacy answers

Kept here so the answers filed with Apple stay consistent between releases.

**"Do you or your third-party partners collect any data from this app?"**
→ **No, we do not collect data from this app.**

Apple defines collection as transmitting data off the device. Everything listed
above stays in the app's own container, so none of it is collected data and no
data types are declared.

Supporting answers elsewhere in the submission:

| Question | Answer |
| --- | --- |
| Uses the Advertising Identifier (IDFA) | No |
| Tracks users across apps or websites | No |
| Third-party analytics or ad SDKs | None |
| Encryption (`ITSAppUsesNonExemptEncryption`) | `false` — already set in the app's Info.plist |
| Account required | No |
| Content rights: third-party content | No |

---

# Gizlilik Politikası — Kod Kırıntısı

**26 Ağustos 2026 tarihinden itibaren geçerlidir.**

Kod Kırıntısı hiçbir veri toplamaz. Hesap yok, sunucu yok, analitik yok, reklam
yok. Uygulamada hiç ağ kodu bulunmuyor: bütün sorular uygulamanın içinde
geliyor, verdiğiniz bütün cevaplar cihazınızda kalıyor.

## Cihazınızda saklananlar

| Ne | Nerede | Neden |
| --- | --- | --- |
| Kurulumda üretilen rastgele bir sayı | App Group klasörü | Hangi gün hangi soruyu göreceğinizi belirler; aynı gün kuran iki kişi aynı sırayı görmesin diye. Sizinle veya cihazınızla ilgili hiçbir bilgiden türetilmez. |
| Uygulamayı kurduğunuz tarih | App Group klasörü | Soru takviminizin sıfırıncı günü. |
| Cevapladığınız her soru için: hangi şıkkı, ne zaman seçtiğiniz | App Group klasörü | Arşiv, seri ve istatistik ekranı bundan hesaplanır. |
| Bildirim saati, bildirimlerin açık olup olmadığı, kapattığınız kategoriler | Uygulama tercihleri | Ayarlarınız. |
| Açılmış soruların başlığı, metni ve etiketleri | Sistem Spotlight dizini | Geçmiş bir soruyu iOS aramasından bulabilmeniz için. Cevaplarınız dizine hiç girmez; yalnızca zaten uygulamayla birlikte gelen soru metni girer. Bu dizini iOS cihazınızda tutar. |

App Group klasörü uygulamaya ait sıradan bir klasördür; yalnızca uygulama ile
widget'ı arasında paylaşılır. Cihazınızı yedeklerseniz yedeğe dahil olur,
uygulamayı silerseniz o da silinir.

## Cihazınızdan çıkanlar

Uygulamanın kendiliğinden gönderdiği hiçbir şey yok.

Tek bir durumu açıkça belirtmek gerekir: bazı soru açıklamaları resmî
belgelere bağlantı verir. O bağlantıya **siz** dokunursanız iOS onu
tarayıcınızda açar ve o andan itibaren hedef site, adresi kendiniz yazmışsınız
gibi sıradan bir ziyaret görür. Uygulama bu isteklere hiçbir şey eklemez ve
bağlantı açıldıktan sonra sürecin parçası değildir.

## Hiç dokunulmayanlar

Konum yok. Rehber, fotoğraf, takvim, mikrofon, kamera yok. Sağlık verisi yok.
Reklam kimliği yok — uygulama AdSupport ve AppTrackingTransparency
çerçevelerini hiç kullanmıyor, dolayısıyla istese bile sizi başka uygulamalar
arasında izleyemez. Hiçbir üçüncü parti SDK yok: uygulamanın sıfır harici
bağımlılığı var.

## Verinizi silmek

İkisi de anında ve eksiksiz:

- Uygulama içindeki **Ayarlar → İlerlemeyi sıfırla**, kaydedilmiş bütün
  cevapları siler ve takvimi yeniden başlatır.
- **Uygulamayı silmek**, klasörü ve içindeki her şeyi kaldırır.

Bizden talep etmeniz gereken bir şey yok, çünkü başka hiçbir yerde tutulan bir
şey yok.

## Çocuklar

Uygulama her yaş için güvenlidir. Hiçbir şey toplanmadığı için, bir çocuk
kullanıcıya dair de hiçbir şey toplanmaz.

## Değişiklikler

İleride bir sürüm herhangi bir veri toplayacak olursa, bu belge o sürüm
yayınlanmadan **önce** güncellenir ve değişiklik sürüm notlarında açıkça
belirtilir — sessizce yapılmaz.

## İletişim

Sorularınız ve gizlilikle ilgili talepleriniz için
<https://github.com/beratsmr/kod-kirintisi/issues> adresinde bir issue açın.

Burada bilerek bir e-posta adresi yerine herkese açık bir issue takipçisi
duruyor. Size dair sorabileceğiniz kişisel bir veri yok — hiçbir şey cihazınızdan
çıkmıyor — dolayısıyla sorulmaya değer her şey, bir sonraki kişinin de
okuyabileceği bir yerde cevaplanmaya değer.

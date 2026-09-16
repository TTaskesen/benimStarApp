# Google Play yayın kontrolü

Bu belge, Yıldız Savaşı için kaynak kodunda tamamlanan kontrolleri ve AAB yüklemesinden önce kullanıcı tarafından tamamlanması gereken adımları ayırır.

## Kaynak kodunda tamamlananlar

- Yalnızca dikey (`portrait`) yön destekleniyor.
- Bölüm hedefleri kod ve mağaza metniyle aynı: 50, 75, 100 ve 75 meteor.
- Android ve iOS uygulama simgesi var; Android adaptive icon kaynakları da projede bulunuyor.
- Ağ izni, reklam, analiz ve takip SDK'sı yok.
- Gizlilik politikası URL'si yayında ve HTTP 200 dönüyor: <https://ttaskesen.github.io/benimStarApp/privacy-policy/>.
- Play Store yükleme paketi hazırlandı: `store-assets/` altında 512×512 simge, 1024×500 öne çıkan görsel ve 1080×1920 dikey ekran görselleri bulunuyor.
- `luac -p *.lua` ve `git diff --check` kontrolleri geçiyor.
- Android `versionCode` kaynakta bir sonraki güncelleme için dize biçiminde `"2"` olarak tutuluyor; sonraki her Play yüklemesinde artırılmalı.
- Mevcut AAB (12 Eylül 2026) `versionCode=1`, `versionName=0.0.10` ve uygulama etiketi `benimStarApp` içeriyor; yeni AAB oluştururken uygulama adı `Yıldız Savaşı`, sürüm kodu `2` ve sürüm adı `0.0.11` seçilmeli.

## AAB yüklemeden önce zorunlu kapılar

1. Solar2D Build for Android ekranında uygulama adı **Yıldız Savaşı**, sürüm adı `0.0.11`, sürüm kodu `2`, benzersiz paket adı ve **Google Play / Android App Bundle** hedefi seçilmeli.
2. Kullanıcının kendi upload keystore'u ile imzalı AAB üretilmeli. Keystore ve parolalar depoya konulmamalı.
3. AAB manifesti incelenerek `targetSdkVersion` güncel Play şartını karşılamalı ve paket adı Play Console'daki uygulamayla aynı olmalı.
4. `jarsigner -verify -verbose -certs app-release.aab` çıktısında debug sertifikası bulunmamalı.
5. Gerçek Android cihazda yeni kurulum, geri dönüş, arka plana alma, safe area, ses, dokunmatik kontroller ve 1–4. bölüm geçişleri test edilmeli.
6. Play Console'da içerik derecelendirmesi, hedef kitle, reklam beyanı, Veri güvenliği formu, mağaza görselleri ve gizlilik politikası bağlantısı tamamlanmalı.
7. Yeni kişisel geliştirici hesabında kapalı test şartı varsa 12 test kullanıcısı 14 gün boyunca katılımcı tutulmadan üretim erişimi alınmamalı.

12 Eylül 2026 itibarıyla Google Play, yeni uygulama ve güncellemelerde Android 16 (API 36) veya üstünü hedefliyor. Bu nedenle Solar2D sürümünün ürettiği gerçek AAB manifesti yükleme öncesi mutlaka incelenmeli.

## Play Console'da 16 Eylül 2026 kontrolü

- Kapalı test Alpha'da 4 kayıtlı test kullanıcısı görünüyor ve üretim erişimi etkin değil. Yeni kişisel geliştirici hesabı şartı uygulanıyorsa en az 12 test kullanıcısının 14 gün boyunca katılımı tamamlanmalı.
- Veri güvenliği sayfası ilk genel bakış adımında; taslak henüz kaydedilmiş bir beyan olarak görünmüyor. AAB'deki SDK ve izinler son kez doğrulandıktan sonra form Play Console'da tamamlanmalı.
- Play Integrity API isteğe bağlıdır. Oyunda faturalandırma bulunmadığından faturalandırma koruması yayın için zorunlu değildir.

## Yayın kararı

Kaynak proje mağaza varlıkları ve gizlilik politikası açısından hazırlanabilir durumda; ancak imzalı AAB, paket adı/target API doğrulaması, gerçek cihaz ekran görüntüleri ve Play Console formları tamamlanmadan “yayına hazır” kabul edilmemelidir.

## Güncel resmi doğrulamalar

- [Play Store önizleme varlıkları](https://support.google.com/googleplay/android-developer/answer/9866151): mağaza simgesi 512×512 PNG, öne çıkan görsel 1024×500 ve telefon ekran görüntüleri için boyut/oran kuralları.
- [Play Data güvenliği formu](https://support.google.com/googleplay/android-developer/answer/10787469): veri toplanmasa bile form ve gizlilik politikası bağlantısı tamamlanmalı.
- [Android hedef API şartı](https://developer.android.com/google/play/requirements/target-sdk): 31 Ağustos 2026'dan itibaren yeni uygulama ve güncellemeler için Android 16 (API 36) veya üstü.

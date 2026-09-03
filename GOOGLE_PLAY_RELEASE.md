# Google Play yayın kontrolü

Bu belge, Yıldız Savaşı için kaynak kodunda tamamlanan kontrolleri ve AAB yüklemesinden önce kullanıcı tarafından tamamlanması gereken adımları ayırır.

## Kaynak kodunda tamamlananlar

- Yalnızca dikey (`portrait`) yön destekleniyor.
- Bölüm hedefleri kod ve mağaza metniyle aynı: 50, 75, 100 ve 75 meteor.
- Android ve iOS uygulama simgesi var; Android adaptive icon kaynakları da projede bulunuyor.
- Ağ izni, reklam, analiz ve takip SDK'sı yok.
- Gizlilik politikası URL'si yayında ve HTTP 200 dönüyor: <https://ttaskesen.github.io/benimStarApp/privacy-policy/>.
- `luac -p *.lua` ve `git diff --check` kontrolleri geçiyor.
- Android `versionCode` kaynakta sayısal `1` olarak tutuluyor; her Play güncellemesinde artırılmalı.

## AAB yüklemeden önce zorunlu kapılar

1. Solar2D Build for Android ekranında uygulama adı, sürüm adı, benzersiz paket adı ve **Google Play / Android App Bundle** hedefi seçilmeli.
2. Kullanıcının kendi upload keystore'u ile imzalı AAB üretilmeli. Keystore ve parolalar depoya konulmamalı.
3. AAB manifesti incelenerek `targetSdkVersion` güncel Play şartını karşılamalı ve paket adı Play Console'daki uygulamayla aynı olmalı.
4. `jarsigner -verify -verbose -certs app-release.aab` çıktısında debug sertifikası bulunmamalı.
5. Gerçek Android cihazda yeni kurulum, geri dönüş, arka plana alma, safe area, ses, dokunmatik kontroller ve 1–4. bölüm geçişleri test edilmeli.
6. Play Console'da içerik derecelendirmesi, hedef kitle, reklam beyanı, Veri güvenliği formu, mağaza görselleri ve gizlilik politikası bağlantısı tamamlanmalı.
7. Yeni kişisel geliştirici hesabında kapalı test şartı varsa 12 test kullanıcısı 14 gün boyunca katılımcı tutulmadan üretim erişimi alınmamalı.

3 Eylül 2026 itibarıyla Google Play, yeni uygulama ve güncellemelerde Android 16 (API 36) veya üstünü hedefliyor. Bu nedenle Solar2D sürümünün ürettiği gerçek AAB manifesti yükleme öncesi mutlaka incelenmeli.

## Yayın kararı

Kaynak proje mağazaya hazırlanabilir durumda; ancak imzalı AAB, paket adı/target API doğrulaması ve gerçek cihaz/Play Console kanıtı olmadan “yayına hazır” kabul edilmemelidir.

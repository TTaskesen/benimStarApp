# Yıldız Savaşı iOS / App Store Connect hazırlığı

## Kimlik ve sürüm

- Uygulama adı: `Yıldız Savaşı`
- Bundle ID: `com.taskesen.yildizsavasi`
- İlk iOS sürümü: `1.0.0`
- İlk iOS build numarası: `1`
- Yön: yalnızca dikey (`portrait`)
- Gizlilik politikası: <https://ttaskesen.github.io/benimStarApp/privacy-policy/>
- Destek e-postası: `taskesen@msn.com`
- Geliştirici/GitHub: `Taskesen`
- App Store fiyatı: `₺19,99` (temel ülke: Türkiye)

## Hazırlanan dosyalar

`~/Desktop/Yayına Hazır Dosyalar/Yıldız Savaşı/` altında:

- `app-icon-1024.png`
- `ios-screenshots/` altında 1284×2778 iPhone görselleri
- `ipad-screenshots/` altında 2048×2732 iPad görselleri
- `README.md` ve görsel yükleme notları

## Yükleme kapıları

1. Solar2D ile iOS/Xcode projesi oluşturulmalı; Bundle ID, sürüm ve build numarası yukarıdaki değerlerle eşleşmeli.
2. Xcode'da Apple Distribution sertifikası ve App Store provisioning profile ile Archive alınmalı.
3. Archive doğrulanmalı ve TestFlight'a yüklenmeli.
4. App Store Connect'te Türkçe mağaza metinleri, yaş derecelendirmesi, App Privacy ve gizlilik URL'si tamamlanmalı.
5. iPhone ve iPad ekran görüntüleri yüklenmeli; gerçek cihazda ana menü, gemi seçimi, dört bölüm, geri düğmesi, ateş, güçlendiriciler ve gizlilik bağlantısı test edilmeli.
6. App Review Information bölümünde uygulamanın hesap istemediği ve çevrimdışı çalıştığı belirtilmeli; giriş hesabı gerektiren seçenek işaretlenmemeli.
7. İncelemeye gönderme ve otomatik/manüel yayın tercihi kullanıcı tarafından son kez kontrol edilmelidir.

## Bilinen uyarılar

- iOS mağaza ekran görüntüleri kaynak oyunun gerçek ekranlarından hazırlanmıştır; fiziksel cihaz çekimleriyle son kontrol yapılmalıdır.
- Oyun hesap açmadığı için App Review giriş hesabı sağlanmaz.

# Yıldız Savaşı — Play Console hazırlık metni

Bu dosya mağaza hesabında işlem yapmaz; imzalı AAB üretildiğinde Play Console alanlarına kopyalanabilecek taslak metni ve kontrol listesini içerir.

## Uygulama adı

Yıldız Savaşı

Önerilen ayırt edici alt başlık: **Meteor Avı: Duvarların Ötesi**

Bu alt başlık mağazada kullanılmadan önce Play araması ve marka çakışması ayrıca kontrol edilmelidir.

## Kısa açıklama (80 karakter sınırı)

Meteorları vur, hareketli duvarlardan kaç ve dört bölümü tamamla!

## Tam açıklama taslağı

Yıldız Savaşı'nda gemini sürükle, meteorları isabetli atışlarla yok et ve bölüm bölüm zorlaşan uzay parkurunda hayatta kal.

Her bölüm dalgalara ayrılır: Bölüm 1'de 50, Bölüm 2'de 75 ve Bölüm 3'te 100 meteor hedeflenir. Seri isabetlerle kombonu büyüt, daha yüksek skor kazan ve yerel başarımları aç. Bölüm 4'te aşağı doğru hareket eden duvarların boşluklarından geçerken meteor saldırılarını da yönet.

Oyunda hesap, reklam, takip veya çevrimiçi bağlantı gerekmez. Bölüm ilerlemesi, skor ve ses tercihi cihazında saklanır. Çoklu lazer, kalkan ve yavaşlatma güçlendiricilerini doğru zamanda kullan.

## Görsel ve video planı

Play Console'ın Grafikler bölümüne yüklemek üzere hazırlanan dosyalar:

| Alan | Dosya | Boyut | Alt metin / açıklama |
| --- | --- | --- | --- |
| Uygulama simgesi | `store-assets/app-icon-512.png` | 512×512 PNG, alfa | Yıldız Savaşı yıldız ve gemi simgesi |
| Öne çıkan görsel | `store-assets/feature-graphic-1024x500.png` | 1024×500 RGB PNG | Yıldız Savaşı uzay oyunu; meteorlar, gemi ve aşağı hareket eden duvarlar |
| Telefon ekranı 1 | `store-assets/android-phone/screenshot-01-menu-1080x1920.png` | 1080×1920 RGB PNG | Yıldız Savaşı ana menüsü ve oyun seçenekleri |
| Telefon ekranı 2 | `store-assets/android-phone/screenshot-02-bolum1-1080x1920.png` | 1080×1920 RGB PNG | Bölüm 1'de gemi, meteorlar, skor ve ateş kontrolü |
| Telefon ekranı 3 | `store-assets/android-phone/screenshot-03-bolum4-1080x1920.png` | 1080×1920 RGB PNG | Bölüm 4'te aşağı inen duvarlar, meteorlar ve güçlendirici |

Görseller mevcut oyunun arka plan, logo, gemi, meteor ve kontrol varlıklarıyla hazırlanmıştır. Play yüklemesinden önce aynı sahneleri gerçek imzalı AAB'nin gerçek Android cihazından yeniden yakalayıp ilk üç ekran görüntüsünün yerine koymak gerekir; cihaz çerçevesi veya bildirim çubuğu kullanılmamalıdır.

Ekran görüntüleri gerçek cihazdan alınmalı; Simulator görüntüleri mağaza görseli olarak kullanılmamalıdır.

## Veri güvenliği taslak notu

- Hesap oluşturma: Yok.
- Kişisel veri toplama: Yok.
- Konum, kişi listesi, fotoğraf, ödeme verisi: Yok.
- Reklam/analiz/takip SDK'sı: Yok.
- Oyun kayıtları: Yalnızca cihaz içi yerel JSON depolaması.
- Ağ aktarımı: Oyun döngüsünde yok.

Play Console Veri güvenliği formu için önerilen ilk yanıt: **Veri toplanmıyor** ve **Veri paylaşılmıyor**. Bu seçim yalnızca mevcut AAB ve tüm üçüncü taraf kütüphaneler incelendikten sonra gönderilmelidir; Google, beyanın uygulama davranışıyla doğru ve eksiksiz olmasını geliştiricinin sorumluluğunda tutar.

Final AAB içeriği ve kullanılan kütüphaneler incelenmeden bu beyan Play Console'da kesinleştirilmemelidir.

## AAB sonrası kontrol listesi

- Kullanıcı kontrollü upload keystore ile imzalı AAB üret.
- `jarsigner -verify -verbose -certs` ile debug imzası olmadığını doğrula.
- AAB manifestinde `targetSdkVersion` değerinin güncel Play şartını karşıladığını ve paket adının Play Console'daki uygulama ile aynı olduğunu doğrula.
- `versionCode` değerini her yeni yüklemede artır; kaynakta başlangıç değeri `1` olarak tutulur.
- Gerçek Android ve iPhone cihazlarında safe area, çoklu dokunma, arka plana alma ve uzun oynanış testlerini tamamla.
- Play Console'da içerik derecelendirmesi, hedef kitle, veri güvenliği ve gizlilik politikası URL'sini doldur.
- Gerçek cihaz ekran görüntülerini ve Bölüm 4 oynanış videosunu ekle.

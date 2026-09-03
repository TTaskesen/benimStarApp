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

1. Menü: logo, “Meteorları vur • Duvarlardan kaç” alt başlığı ve ana düğmeler.
2. Bölüm 1: gemi hareketi, ateş düğmesi ve ilk kombo.
3. Bölüm 3: “Meteorları vur, duvarlardan kaç.” hedef HUD'ı.
4. Bölüm 4: aşağı inen hareketli duvarlar ve güçlendirici.
5. Sonuç ekranı: skor, isabet oranı, kombo ve tekrar oynama düğmeleri.

Ekran görüntüleri gerçek cihazdan alınmalı; Simulator görüntüleri mağaza görseli olarak kullanılmamalıdır.

## Veri güvenliği taslak notu

- Hesap oluşturma: Yok.
- Kişisel veri toplama: Yok.
- Konum, kişi listesi, fotoğraf, ödeme verisi: Yok.
- Reklam/analiz/takip SDK'sı: Yok.
- Oyun kayıtları: Yalnızca cihaz içi yerel JSON depolaması.
- Ağ aktarımı: Oyun döngüsünde yok.

Final AAB içeriği ve kullanılan kütüphaneler incelenmeden bu beyan Play Console'da kesinleştirilmemelidir.

## AAB sonrası kontrol listesi

- Kullanıcı kontrollü upload keystore ile imzalı AAB üret.
- `jarsigner -verify -verbose -certs` ile debug imzası olmadığını doğrula.
- AAB manifestinde `targetSdkVersion` değerinin güncel Play şartını karşıladığını ve paket adının Play Console'daki uygulama ile aynı olduğunu doğrula.
- `versionCode` değerini her yeni yüklemede artır; kaynakta başlangıç değeri `1` olarak tutulur.
- Gerçek Android ve iPhone cihazlarında safe area, çoklu dokunma, arka plana alma ve uzun oynanış testlerini tamamla.
- Play Console'da içerik derecelendirmesi, hedef kitle, veri güvenliği ve gizlilik politikası URL'sini doldur.
- Gerçek cihaz ekran görüntülerini ve Bölüm 4 oynanış videosunu ekle.

# Yıldız Savaşı

Solar2D ile geliştirilen, yalnızca dikey modda çalışan mobil uzay oyunu. Oyuncu gemiyi meteorların arasından yönlendirir, lazerle meteorları vurur ve her bölümde daha zorlu dalgaları tamamlar.

![benimStarApp logosu](benimStarApp-logo.png)

## Oyun akışı

- Meteorları vurarak skor ve kombo kazanılır.
- Gemi meteor veya duvarla çarpıştığında bir can kaybeder ve kısa bir tamir sürecine girer.
- Bölüm tamamlanınca sonraki bölüm otomatik açılır.
- Yerel kayıt, yüksek skorlar, başarımlar ve günlük görevler cihazda tutulur.

## Bölümler

| Bölüm | Hedef meteor | Dalga | Özel kural |
| --- | ---: | ---: | --- |
| 1 | 30 | 3 | Temel meteor akışı |
| 2 | 45 | 3 | Artan meteor hızı |
| 3 | 60 | 4 | Duvarsız meteor bölümü |
| 4 | 75 | 5 | Aşağı inen duvarlar ve güçlendirmeler |

Bölüm 4 duvarlarının iniş hızı %40 azaltılmış, duvarlar arasındaki süre üç katına çıkarılmıştır.

## Kontroller

- `◀` ve `▶`: Gemiyi sağa-sola hareket ettirir. Basılı tutularak sürekli hareket sağlanır.
- `ATEŞ`: Lazer ateşler.
- Gemi ayrıca sürüklenerek yatayda kontrol edilebilir.

Oyun tüm ekranlarda yalnızca dikey (`portrait`) yönü destekler.

## Projeyi çalıştırma

1. [Solar2D](https://solar2d.com/) Simulator’ı kurun.
2. Solar2D Simulator’da bu klasörü açın.
3. `main.lua` dosyasını çalıştırın.

Yerel Lua doğrulaması için:

```bash
luac -p *.lua
```

## Proje yapısı

- `main.lua`: Uygulama başlangıcı ve genel ses ayarı.
- `menu.lua`: Ana menü ve oyun seçenekleri.
- `oyun.lua` – `oyun4.lua`: Bölüm oynanışları.
- `oyun_ayar.lua`: Bölüm hedefleri ve denge ayarları.
- `oyun_kayit.lua`: Yerel devam kaydı.
- `oyun_meta.lua`: Başarımlar ve günlük görevler.
- `sonuc.lua`, `yuksek_skor.lua`: Sonuç ve yüksek skor ekranları.
- `destek.lua`: Oyun içi destek/iletişim sayfası.

## Gizlilik ve iletişim

- Gizlilik politikası: <https://ttaskesen.github.io/benimStarApp/privacy-policy/>
- Geliştirici: **Taskesen**
- E-posta: **taskesen@msn.com**

Oyun kişisel veri toplamaz; kayıtlar cihazın yerel depolamasında tutulur.

## Sürüm

Mevcut geliştirme sürümü: **v0.0.8**

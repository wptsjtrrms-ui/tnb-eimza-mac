# TNB E-İmza – Apple Silicon Mac Düzeltmesi

M1 / M2 / M3 / M4 işlemcili Mac'lerde **TNB E-İmza Client** çalışmıyorsa bu betik sorunu tek komutla düzeltir.

## Önce bunları kurun

1. **TNB E-İmza Client**: e-hizmet.tnb.org.tr üzerinden `TNBEImzaClient.dmg`
2. **Intel (x86 64-bit) Java 17 veya üstü**: [Azul Zulu](https://www.azul.com/downloads/?os=macos&architecture=x86-64-bit&package=jdk) sayfasından *macOS / x86 64-bit / JDK* `.dmg`
3. **AKİS Kart İzleme Aracı**: kamusm.bilgem.tubitak.gov.tr

## Kurulum (tek komut)

Terminal'i açın, aşağıdaki satırı yapıştırıp Enter'a basın:

```bash
zsh <(curl -fsSL https://raw.githubusercontent.com/wptsjtrrms-ui/tnb-eimza-mac/main/tnb-eimza-m1-duzeltme.sh)
```

macOS uyarı gösterirse **Yine de yapıştır** deyin. Eksik bir şey varsa betik ne yapmanız gerektiğini yazar ve durur.

## Kurulumdan sonra

- Uygulamayı **masaüstündeki `TNB E-Imza Baslat.command`** ile açın (TNB simgesiyle değil).
- İmzayı **Chrome**'da atın (Safari değil).

## Ne yapar, neye dokunur?

Asıl TNB uygulamasını değiştirmez, şifre istemez. Her şeyi `~/.eImzaClient` klasörüne ve masaüstündeki kısayola yazar.

## Kaldırma

```bash
rm -rf ~/.eImzaClient ~/Desktop/"TNB E-Imza Baslat.command"
```

---

TNB'nin resmi bir aracı değildir. Kullanım sorumluluğu kullanıcıya aittir.

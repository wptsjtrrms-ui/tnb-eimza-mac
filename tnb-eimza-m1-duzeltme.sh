#!/bin/zsh
# TNB E-Imza Client - Apple Silicon (M1/M2/M3/M4) Mac duzeltmesi
#
# Kullanim:  zsh tnb-eimza-m1-duzeltme.sh            (kurar ve baslatir)
#            zsh tnb-eimza-m1-duzeltme.sh --kontrol  (sadece kontrol eder, hicbir sey degistirmez)
#
# Asil TNB uygulamasina dokunmaz; her sey ~/.eImzaClient altina ve masaustune yazilir.
setopt nonomatch
KONTROL=0; [[ "$1" == "--kontrol" ]] && KONTROL=1
DIR="$HOME/.eImzaClient"
LAUNCHER="$HOME/Desktop/TNB E-Imza Baslat.command"
hata() { print -P "%F{red}HATA:%f $1"; exit 1; }
tamam() { print -P "%F{green}✓%f $1"; }

# 1) TNB E-Imza Client kurulu mu?
JAR=$(ls /Applications/TNBEImzaClient/NbsWebEImzaClient-*.jar 2>/dev/null | sort -V | tail -1)
[[ -n "$JAR" ]] || hata "TNB E-Imza Client bulunamadi. Once e-hizmet.tnb.org.tr uzerinden TNBEImzaClient.dmg'yi indirip kurun."
tamam "TNB E-Imza Client: $JAR"

# 2) Rosetta (yoksa kurmayi dener)
if ! arch -x86_64 /usr/bin/true 2>/dev/null; then
  (( KONTROL )) && hata "Rosetta kurulu degil. Komutu --kontrol olmadan calistirirsaniz kurmayi dener."
  print "Rosetta kuruluyor..."
  softwareupdate --install-rosetta --agree-to-license >/dev/null 2>&1
  arch -x86_64 /usr/bin/true 2>/dev/null || hata "Rosetta kurulamadi. Su komutu calistirip tekrar deneyin:
  softwareupdate --install-rosetta --agree-to-license"
fi
tamam "Rosetta kurulu"

# 3) Intel (x86_64) Java 11+ bul (en yuksek surum secilir)
JAVA=""; JV=0
for h in /Library/Java/JavaVirtualMachines/*/Contents/Home "$HOME"/Library/Java/JavaVirtualMachines/*/Contents/Home; do
  j="$h/bin/java"; [[ -x "$j" ]] || continue
  file "$j" | grep -q x86_64 || continue
  v=$("$j" -version 2>&1 | head -1 | sed -E 's/.*version "([0-9]+).*/\1/')
  [[ "$v" == <-> ]] || continue
  (( v >= 11 && v > JV )) && { JAVA="$j"; JV=$v; }
done
[[ -n "$JAVA" ]] || hata "Intel (x86_64) Java 11 veya ustu bulunamadi.
  https://www.azul.com/downloads/?os=macos&architecture=x86-64-bit&package=jdk adresinden
  'macOS / x86 64-bit / JDK' .dmg dosyasini indirip kurun, sonra bu komutu tekrar calistirin."
tamam "Intel Java $JV: $JAVA"

# 4) Sistemde kurulu AKIS surucusu
AKIS=/usr/local/lib/libakisp11.dylib
if [[ -f "$AKIS" ]] && lipo -archs "$AKIS" 2>/dev/null | grep -q x86_64; then
  tamam "AKIS surucusu: $AKIS"
else
  AKIS=""
  print -P "%F{yellow}UYARI:%f Intel uyumlu AKIS surucusu (/usr/local/lib/libakisp11.dylib) yok."
  print "  Kartiniz gorunmezse kamusm.bilgem.tubitak.gov.tr adresinden 'AKIS Kart Izleme Araci'ni kurup tekrar deneyin."
fi

# 5) OpenSSL
SSL=""
for c in /Applications/ArkSigner.app/Contents/Frameworks/libcrypto.1.1.dylib \
         /usr/local/opt/openssl@1.1/lib/libcrypto.1.1.dylib \
         /usr/local/opt/openssl@3/lib/libcrypto.3.dylib \
         /Library/Frameworks/eToken.framework/Versions/A/libcrypto.3.dylib; do
  [[ -f "$c" ]] && lipo -archs "$c" 2>/dev/null | grep -q x86_64 && { SSL="$c"; break; }
done
if [[ -n "$SSL" ]]; then tamam "OpenSSL: $SSL"
elif [[ -z "$AKIS" ]]; then
  hata "Ne AKIS surucusu ne de Intel uyumlu OpenSSL bulundu; uygulama kart okurken cokecek.
  'AKIS Kart Izleme Araci'ni kurup bu komutu tekrar calistirin."
fi

if (( KONTROL )); then print "\n--kontrol: Her sey hazir gorunuyor. Kurmak icin --kontrol olmadan calistirin."; exit 0; fi

# 6) Kurulum
mkdir -p "$DIR/openssl" || hata "$DIR olusturulamadi"
if [[ -n "$SSL" ]]; then
  cp -f "$SSL" "$DIR/openssl/" && ln -sf "${SSL:t}" "$DIR/openssl/libcrypto.dylib"
  s="${SSL:h}/${${SSL:t}/libcrypto/libssl}"
  [[ -f "$s" ]] && cp -f "$s" "$DIR/openssl/" && ln -sf "${s:t}" "$DIR/openssl/libssl.dylib"
fi

RUNJAR="$JAR"
if [[ -n "$AKIS" ]]; then
  RUNJAR="$DIR/NbsWebEImzaClient-yamali.jar"
  T=$(mktemp -d) || hata "gecici klasor olusturulamadi"
  mkdir -p "$T/BOOT-INF/classes/suruculer/akis/mac"
  cp "$AKIS" "$T/BOOT-INF/classes/suruculer/akis/mac/akisp11.dylib"
  cp -f "$JAR" "$RUNJAR" || hata "jar kopyalanamadi"
  (cd "$T" && zip -q "$RUNJAR" BOOT-INF/classes/suruculer/akis/mac/akisp11.dylib) || hata "jar guncellenemedi"
  rm -rf "$T"
  tamam "Yeni AKIS surucusuyle uygulama kopyasi: $RUNJAR"
fi

NATIVE=""; (( JV >= 17 )) && NATIVE="--enable-native-access=ALL-UNNAMED"
cat > "$LAUNCHER" <<EOF
#!/bin/zsh
# TNB E-Imza Client'i Intel Java (Rosetta) ile baslatir.
pkill -f NbsWebEImzaClient; sleep 2
cd "${JAR:h}" || exit 1
trap '' HUP
export DYLD_LIBRARY_PATH="$DIR/openssl"
"$JAVA" -Dfile.encoding=UTF-8 \\
  --add-exports=jdk.crypto.cryptoki/sun.security.pkcs11.wrapper=ALL-UNNAMED \\
  --add-opens=jdk.crypto.cryptoki/sun.security.pkcs11.wrapper=ALL-UNNAMED \\
  --add-opens=jdk.crypto.cryptoki/sun.security.pkcs11=ALL-UNNAMED \\
  --add-opens=java.base/java.lang=ALL-UNNAMED \\
  --add-opens=java.base/sun.security.util=ALL-UNNAMED \\
  --add-opens=java.base/sun.security.x509=ALL-UNNAMED \\
  $NATIVE -jar "$RUNJAR" </dev/null >/dev/null 2>&1 &!
echo "TNB E-Imza baslatildi. Bu pencereyi kapatabilirsiniz."
EOF
chmod +x "$LAUNCHER"
tamam "Masaustune kisayol yazildi: $LAUNCHER"

zsh "$LAUNCHER"
print "\nUygulama baslatiliyor (yaklasik 30 sn)..."
for i in {1..20}; do
  sleep 3
  if curl -s -m 2 -o /dev/null http://localhost:17000/; then
    tamam "Uygulama calisiyor."
    print "\nSimdi Chrome'da (Safari degil) e-hizmet.tnb.org.tr sayfasini yenileyip imzalayin."
    print "Bundan sonra uygulamayi masaustundeki 'TNB E-Imza Baslat.command' ile acin (TNB simgesiyle degil)."
    exit 0
  fi
done
hata "Uygulama 60 sn icinde baslamadi. Kayitlar: $DIR/logs/app.log"

# ARK-Okul-zili
GNU/Linux sistemler için okul zili uygulaması


Derleyebilmek için mutlaka libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev paketleri de yüklü olmalı.

Derlemek için:

glib-compile-resources resources.xml --target=resources.c --generate-source

ile kaynakları derle.

valac --pkg gtk+-3.0 --pkg gstreamer-1.0 main.vala SesMotoru.vala MelodiSekmesi.vala ZamanYonetici.vala HemenCalSekmesi.vala MuzikYayiniSekmesi.vala AyarYoneticisi.vala resources.c -o okul_zili

ile programı oluştur.

Pardus XFCE için Oturum ve Başlangıç ayarlarında aşağıdaki komutu kullanarak uygulamayı ekleyin: 
sh -c "sleep 30 && cd ~/Masaüstü/ARK && ./okul_zili"

Eklemek istediğiniz zil sesini Sesler dizini altındaki Ziller dizinine ekleyebilirsiniz.
Sesler dizini altındaki Melodiler ve Melodiler_cuma dizinlerine teneffüslerde çalınacak müzikleri yükleyebilirsiniz.
ayarlar.ini dosyasına programda yapılan değişiklikler kaydedilmektedir. Programı yeniden başlattığınızda bu dosyadaki
bilgilere göre yapmış olduğunuz saat, melodi ve ses seviyesi gibi değişiklikler bu dosyadan çağırılmaktadır.

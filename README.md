<img width="749" height="949" alt="Ekran görüntüsü_2026-05-07_01-06-50" src="https://github.com/user-attachments/assets/cffc3d18-a05c-4339-8dac-a93d76a84082" />
<img width="749" height="949" alt="Ekran görüntüsü_2026-05-07_01-07-13" src="https://github.com/user-attachments/assets/825b2dd1-d11e-458b-8b84-be2d6f5f2af3" />
<img width="749" height="949" alt="Ekran görüntüsü_2026-05-07_01-07-41" src="https://github.com/user-attachments/assets/9b7e37de-0402-4dba-b704-e7ba9f769b21" />


# ARK-Okul-zili
GNU/Linux sistemler için okul zili uygulaması

Bağımlılıklar: libgtk-3-0, libgstreamer1.0-0, gstreamer1.0-plugins-base, gstreamer1.0-plugins-good, gstreamer1.0-plugins-bad

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
~/.config/ARK-okul-zili/ayarlar.conf dosyasına programda yapılan değişiklikler kaydedilmektedir. Programı yeniden başlattığınızda bu dosyadaki
bilgilere göre yapmış olduğunuz saat, melodi ve ses seviyesi gibi ayarlar çağırılmaktadır.

# ARK-Okul-zili
GNU/Linux sistemler için okul zili uygulaması

Derlemek için
valac --pkg gtk+-3.0 --pkg gstreamer-1.0 main.vala SesMotoru.vala MelodiSekmesi.vala ZamanYonetici.vala HemenCalSekmesi.vala MuzikYayiniSekmesi.vala -o okul_zili
komutunu kullanınız.

Sesler dizini altındaki Melodiler ve Melodiler_cuma dizinlerine teneffüslerde çalınacak müzikleri yükleyebilirsiniz.
ayarlar.ini dosyasına programda yapılan değişiklikler kaydedilmektedir. Programı yeniden başlattığınızda bu dosyadaki
bilgilere göre yapmış olduğunuz saat, melodi ve ses seviyesi gibi değişiklikler bu dosyadan çağırılmaktadır.

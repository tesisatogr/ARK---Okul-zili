using Gtk;
using GLib;

public class MuzikYayiniSekmesi : GLib.Object {
    private CheckButton checkbutton_muzik_yayini_yap;
    private Adjustment adjustment7;

    private CheckButton[] normal_teneffus = new CheckButton[16];
    private CheckButton[] cuma_teneffus = new CheckButton[16];

    private Button button_muzik_yayini_hemen_cal;
    private Button button_muzik_yayini_durdur;
    private Label label_calinan_sarki;

    private SesMotoru ses_motoru;

    private bool su_an_teneffus_mu = false;
    private bool su_an_cuma_mi = false;

    // --- YENİ: I/O OPTİMİZASYONU İÇİN AKILLI ÖNBELLEK DEĞİŞKENLERİ ---
    private GenericArray<string>? normal_sarki_listesi = null;
    private GenericArray<string>? cuma_sarki_listesi = null;
    private uint64 normal_klasor_son_degisiklik = 0;
    private uint64 cuma_klasor_son_degisiklik = 0;

    public MuzikYayiniSekmesi (Builder builder, SesMotoru motor) {
        this.ses_motoru = motor;

        // --- ANA KONTROLLER ---
        checkbutton_muzik_yayini_yap = builder.get_object ("checkbutton_muzik_yayini_yap") as CheckButton;
        adjustment7 = builder.get_object ("adjustment7") as Adjustment;

        // --- MANUEL BUTONLARI GLADE'DEN ÇEKME ---
        button_muzik_yayini_hemen_cal = builder.get_object ("button_muzik_yayini_hemen_cal") as Button;
        button_muzik_yayini_durdur = builder.get_object ("button_muzik_yayini_durdur") as Button;
        label_calinan_sarki = builder.get_object ("label_calinan_sarki") as Label;

        // --- GLADE'DEN TÜM CHECKBUTTONLARI ÇEKME ---
        for (int i = 0; i < 8; i++) {
            normal_teneffus[i] = builder.get_object ("checkbutton_sabah_muzikli_teneffus_%d".printf(i+1)) as CheckButton;
            normal_teneffus[i+8] = builder.get_object ("checkbutton_ogle_muzikli_teneffus_%d".printf(i+1)) as CheckButton;

            cuma_teneffus[i] = builder.get_object ("checkbutton_cuma_sabah_muzikli_teneffus_%d".printf(i+1)) as CheckButton;
            cuma_teneffus[i+8] = builder.get_object ("checkbutton_cuma_ogle_muzikli_teneffus_%d".printf(i+1)) as CheckButton;
        }

		ayarlari_yukle ();
        arayuz_durumunu_guncelle ();

        // --- SİNYALLERİ BAĞLAMA ---
        ses_motoru.sarki_bitti.connect (otomatik_sarki_gecisi);
        
        if (checkbutton_muzik_yayini_yap != null) {
            checkbutton_muzik_yayini_yap.toggled.connect (ayarlari_kaydet);
            checkbutton_muzik_yayini_yap.toggled.connect (arayuz_durumunu_guncelle);
        }

        if (adjustment7 != null) adjustment7.value_changed.connect (ayarlari_kaydet);
        
        for (int i = 0; i < 16; i++) {
            if (normal_teneffus[i] != null) normal_teneffus[i].toggled.connect (ayarlari_kaydet);
            if (cuma_teneffus[i] != null) cuma_teneffus[i].toggled.connect (ayarlari_kaydet);
        }

        // --- MANUEL BUTON TETİKLEYİCİLERİ ---
        if (button_muzik_yayini_hemen_cal != null) {
            button_muzik_yayini_hemen_cal.clicked.connect (manuel_sarki_cal);
        }
        if (button_muzik_yayini_durdur != null) {
            button_muzik_yayini_durdur.clicked.connect (muzik_sistemini_durdur);
        }

        
    }

    private void manuel_sarki_cal () {
        var simdi = new DateTime.now_local ();
        bool bugun_cuma = (simdi.get_day_of_week () == 5);
        rastgele_sarki_cal_klasorden (bugun_cuma);
    }

    private void muzik_sistemini_durdur () {
        su_an_teneffus_mu = false; 
        ses_motoru.durdur (); 
        if (label_calinan_sarki != null) label_calinan_sarki.set_text ("");
    }

    private void arayuz_durumunu_guncelle () {
        if (checkbutton_muzik_yayini_yap == null) return;
        bool aktif_mi = checkbutton_muzik_yayini_yap.active;

        for (int i = 0; i < 16; i++) {
            if (normal_teneffus[i] != null) normal_teneffus[i].set_sensitive (aktif_mi);
            if (cuma_teneffus[i] != null) cuma_teneffus[i].set_sensitive (aktif_mi);
        }
    }

    public void teneffus_basladi (int index, bool cuma_mi) {
        if (checkbutton_muzik_yayini_yap == null || !checkbutton_muzik_yayini_yap.active) return;
        CheckButton[] hedef_dizi = cuma_mi ? cuma_teneffus : normal_teneffus;
        
        if (hedef_dizi[index] != null && hedef_dizi[index].active) {
            su_an_teneffus_mu = true;
            su_an_cuma_mi = cuma_mi;
            rastgele_sarki_cal_klasorden (su_an_cuma_mi);       
        }
    }

    public void teneffus_bitti () {
        su_an_teneffus_mu = false;
        ses_motoru.durdur (); 
        if (label_calinan_sarki != null) label_calinan_sarki.set_text ("");
    }

    private void otomatik_sarki_gecisi () {
        if (su_an_teneffus_mu) {
            rastgele_sarki_cal_klasorden (su_an_cuma_mi);
        }
    }

	// --- GÜNCELLENMİŞ: HER BİLGİSAYARDA ÇALIŞAN AKILLI TARAYICI ---
    private void klasoru_denetle_ve_guncelle (bool cuma_klasoru) {
    string klasor_adi = cuma_klasoru ? "Melodiler_cuma" : "Melodiler";
    
    // ARTIK HİÇBİR ŞEYE GÜVENMİYORUZ, YOLU TEK SATIRDA ÇİVİLİYORUZ:
    string tam_yol = GLib.Environment.get_home_dir() + "/ARK/Sesler/" + klasor_adi;
    
    // Terminale tam olarak nereye baktığını yazdıralım ki emin olalım:
    print ("\n--- KLASÖR TARANIYOR --- \nBaktığım yer: %s\n", tam_yol);
        
        try {
            var klasor = File.new_for_path (tam_yol);
            if (!klasor.query_exists()) {
                print ("Hata: Müzik klasörü bulunamadı: %s\n", tam_yol);
                return;
            }

            var info = klasor.query_info ("time::modified", FileQueryInfoFlags.NONE);
            uint64 mtime = info.get_attribute_uint64 ("time::modified");

            uint64 son_degisiklik = cuma_klasoru ? cuma_klasor_son_degisiklik : normal_klasor_son_degisiklik;
            var liste = cuma_klasoru ? cuma_sarki_listesi : normal_sarki_listesi;

            if (liste == null || mtime != son_degisiklik) {
                var yeni_liste = new GenericArray<string> ();
                var enum_files = klasor.enumerate_children (FileAttribute.STANDARD_NAME, 0);
                FileInfo f_info;
                while ((f_info = enum_files.next_file ()) != null) {
                    // Sadece küçük harf büyük harf duyarlılığına karşı .mp3 ve .MP3 kontrolü
                    string dosya_adi = f_info.get_name ().down (); 
                    if (dosya_adi.has_suffix (".mp3")) {
                        yeni_liste.add (Path.build_filename (tam_yol, f_info.get_name ()));
                    }
                }
                
                if (cuma_klasoru) {
                    cuma_sarki_listesi = yeni_liste;
                    cuma_klasor_son_degisiklik = mtime;
                } else {
                    normal_sarki_listesi = yeni_liste;
                    normal_klasor_son_degisiklik = mtime;
                }
            }
        } catch (GLib.Error e) { 
            print ("Klasör okunamadı: %s | Hata: %s\n", tam_yol, e.message); 
            if (cuma_klasoru && cuma_sarki_listesi == null) cuma_sarki_listesi = new GenericArray<string> ();
            if (!cuma_klasoru && normal_sarki_listesi == null) normal_sarki_listesi = new GenericArray<string> ();
        }
    }

    private void rastgele_sarki_cal_klasorden (bool cuma_klasoru) {
    klasoru_denetle_ve_guncelle (cuma_klasoru);
    
    var liste = cuma_klasoru ? cuma_sarki_listesi : normal_sarki_listesi;

    // TERMINAL KONTROLU (Sorunu anlamak için buraya bakacağız)
    if (liste != null) {
        print ("Tarama bitti. Bulunan şarkı sayısı: %d\n", liste.length);
    }

    if (liste != null && liste.length > 0) {
        int rastgele_index = Random.int_range (0, liste.length);
        string secilen_sarki = liste[rastgele_index];
        
        // Ses motoruna gönder
        ses_motoru.cal (secilen_sarki, adjustment7);

        if (label_calinan_sarki != null) {
            string sarki_adi = Path.get_basename (secilen_sarki).replace (".mp3", "").replace(".MP3", "");
            label_calinan_sarki.set_text ("Şu an çalan şarkı:\n" + sarki_adi);
        }
    } else {
        print ("HATA: Oynatılacak şarkı bulunamadı! Klasör boş mu?\n");
    }
}

    // --- YENİ: AYAR YÖNETİCİSİ ENTEGRASYONU (Yarış Koşulu Çözüldü) ---
    public void ayarlari_kaydet () {
        var ayar = AyarYoneticisi.instance ();

        if (checkbutton_muzik_yayini_yap != null) ayar.yaz_mantiksal ("Muzik", "Aktif", checkbutton_muzik_yayini_yap.active);
        if (adjustment7 != null) ayar.yaz_ondalik ("Muzik", "Ses", adjustment7.value);

        for (int i = 0; i < 16; i++) {
            if (normal_teneffus[i] != null) ayar.yaz_mantiksal ("Muzik", "Normal_%d".printf(i), normal_teneffus[i].active);
            if (cuma_teneffus[i] != null) ayar.yaz_mantiksal ("Muzik", "Cuma_%d".printf(i), cuma_teneffus[i].active);
        }
        ayar.kaydet (); // Tüm bilgileri verdikten sonra tek bir yerden kaydet!
    }

    private void ayarlari_yukle () {
        var ayar = AyarYoneticisi.instance ();
        
        if (checkbutton_muzik_yayini_yap != null) checkbutton_muzik_yayini_yap.active = ayar.oku_mantiksal ("Muzik", "Aktif", false);
        if (adjustment7 != null) adjustment7.value = ayar.oku_ondalik ("Muzik", "Ses", 50.0);

        for (int i = 0; i < 16; i++) {
            if (normal_teneffus[i] != null) normal_teneffus[i].active = ayar.oku_mantiksal ("Muzik", "Normal_%d".printf(i), false);
            if (cuma_teneffus[i] != null) cuma_teneffus[i].active = ayar.oku_mantiksal ("Muzik", "Cuma_%d".printf(i), false);
        }
    }
}

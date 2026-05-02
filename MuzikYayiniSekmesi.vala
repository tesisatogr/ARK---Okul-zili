using Gtk;
using GLib;

public class MuzikYayiniSekmesi : GLib.Object {
    private CheckButton checkbutton_muzik_yayini_yap;
    private Adjustment adjustment7;

    private CheckButton[] normal_teneffus = new CheckButton[16];
    private CheckButton[] cuma_teneffus = new CheckButton[16];

    // --- YENİ EKLENEN MANUEL KONTROL BUTONLARI ---
    private Button button_muzik_yayini_hemen_cal;
    private Button button_muzik_yayini_durdur;
    private Label label_calinan_sarki;

    private SesMotoru ses_motoru;

    private bool su_an_teneffus_mu = false;
    private bool su_an_cuma_mi = false;

    public MuzikYayiniSekmesi (Builder builder, SesMotoru motor) {
        this.ses_motoru = motor;

        // --- ANA KONTROLLER ---
        checkbutton_muzik_yayini_yap = builder.get_object ("checkbutton_muzik_yayini_yap") as CheckButton;
        adjustment7 = builder.get_object ("adjustment7") as Adjustment;

        // --- YENİ: MANUEL BUTONLARI GLADE'DEN ÇEKME ---
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

        // --- YENİ: MANUEL BUTON TETİKLEYİCİLERİ ---
        if (button_muzik_yayini_hemen_cal != null) {
            button_muzik_yayini_hemen_cal.clicked.connect (manuel_sarki_cal);
        }
        if (button_muzik_yayini_durdur != null) {
            button_muzik_yayini_durdur.clicked.connect (muzik_sistemini_durdur);
        }

        ayarlari_yukle ();
        arayuz_durumunu_guncelle ();
    }

    // --- YENİ: MANUEL ÇALMA VE DURDURMA FONKSİYONLARI ---
    private void manuel_sarki_cal () {
        // Teneffüste olmasak bile, bilgisayarın o anki saatine bakıp Cuma olup olmadığını anlıyoruz.
        var simdi = new DateTime.now_local ();
        bool bugun_cuma = (simdi.get_day_of_week () == 5);
        
        // Klasörden doğrudan çal
        rastgele_sarki_cal_klasorden (bugun_cuma);
    }

    private void muzik_sistemini_durdur () {
        // 1. Şarkı durduğunda "sarki_bitti" sinyalinin yeni şarkı açmasını engelliyoruz.
        su_an_teneffus_mu = false; 
        
        // 2. Sesi tamamen kesiyoruz. (SesMotoru içindeki metodun "durdur" olduğunu varsayıyoruz)
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
        }
    }

    public void teneffus_bitti () {
        su_an_teneffus_mu = false;
        ses_motoru.durdur (); // Zil çaldığı an müziği kes

        if (label_calinan_sarki != null) label_calinan_sarki.set_text ("");
    }

    private void otomatik_sarki_gecisi () {
        if (su_an_teneffus_mu) {
            rastgele_sarki_cal_klasorden (su_an_cuma_mi);
        }
    }

    // --- GÜNCELLENEN RASTGELE SEÇİCİ (Parametre Alıyor) ---
    private void rastgele_sarki_cal_klasorden (bool cuma_klasoru) {
        string klasor_adi = cuma_klasoru ? "Melodiler_cuma" : "Melodiler";
        string tam_yol = Path.build_filename (Environment.get_current_dir (), "Sesler", klasor_adi);
        
        var sarki_listesi = new GenericArray<string> ();
        
        try {
            var klasor = File.new_for_path (tam_yol);
            var enum_files = klasor.enumerate_children (FileAttribute.STANDARD_NAME, 0);
            FileInfo info;
            while ((info = enum_files.next_file ()) != null) {
                if (info.get_name ().has_suffix (".mp3")) {
                    sarki_listesi.add (Path.build_filename (tam_yol, info.get_name ()));
                }
            }
        } catch { print ("Klasör okunamadı: %s\n", tam_yol); }

        if (sarki_listesi.length > 0) {
            int rastgele_index = Random.int_range (0, sarki_listesi.length);
            string secilen_sarki = sarki_listesi[rastgele_index];
            ses_motoru.cal (secilen_sarki, adjustment7);

        if (label_calinan_sarki != null) {
                // Sadece dosya adını al ve ".mp3" kısmını silerek tertemiz göster
                string sarki_adi = Path.get_basename (secilen_sarki).replace (".mp3", "");
                label_calinan_sarki.set_text ("Şu an çalan şarkı:\n" + sarki_adi);
        }
    }
}
    // Ayarları Kaydetme ve Yükleme fonksiyonları (Değişiklik Yok)
    public void ayarlari_kaydet () {
        var kf = new KeyFile ();
        string yol = Path.build_filename (Environment.get_current_dir (), "ayarlar.ini");
        try { kf.load_from_file (yol, KeyFileFlags.NONE); } catch { }

        if (checkbutton_muzik_yayini_yap != null) kf.set_boolean ("Muzik", "Aktif", checkbutton_muzik_yayini_yap.active);
        if (adjustment7 != null) kf.set_double ("Muzik", "Ses", adjustment7.value);

        for (int i = 0; i < 16; i++) {
            if (normal_teneffus[i] != null) kf.set_boolean ("Muzik", "Normal_%d".printf(i), normal_teneffus[i].active);
            if (cuma_teneffus[i] != null) kf.set_boolean ("Muzik", "Cuma_%d".printf(i), cuma_teneffus[i].active);
        }
        try { FileUtils.set_contents (yol, kf.to_data ()); } catch { }
    }

    private void ayarlari_yukle () {
        var kf = new KeyFile ();
        string yol = Path.build_filename (Environment.get_current_dir (), "ayarlar.ini");
        try {
            kf.load_from_file (yol, KeyFileFlags.NONE);
            if (checkbutton_muzik_yayini_yap != null) checkbutton_muzik_yayini_yap.active = kf.get_boolean ("Muzik", "Aktif");
            if (adjustment7 != null) adjustment7.value = kf.get_double ("Muzik", "Ses");

            for (int i = 0; i < 16; i++) {
                if (normal_teneffus[i] != null) normal_teneffus[i].active = kf.get_boolean ("Muzik", "Normal_%d".printf(i));
                if (cuma_teneffus[i] != null) cuma_teneffus[i].active = kf.get_boolean ("Muzik", "Cuma_%d".printf(i));
            }
        } catch { }
    }
}

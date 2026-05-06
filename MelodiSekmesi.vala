using Gtk;

public class MelodiSekmesi : GLib.Object {
    // --- Öğrenci ---
    private ComboBoxText combo_ogrenci_zili_sec;
    private CheckButton checkbutton_ogrenci_anonslu;
    private CheckButton checkbutton_anons_yapma;
    private Adjustment adjustment4; 
    
    // --- Öğretmen ---
    private ComboBoxText combo_ogretmen_zili_sec;
    private CheckButton checkbutton_ogretmen_anonslu;
    private Adjustment adjustment5; 
    
    // --- Çıkış ---
    private ComboBoxText combo_cikis_zili_sec;
    private Adjustment adjustment6; 

    private SesMotoru ses_motoru;
    
    private bool anons_caliyor_mu = false;
    private string aktif_anons_dosyasi = "";
    private Adjustment aktif_adjustment = null;

    public MelodiSekmesi (Builder builder, SesMotoru motor) {
        this.ses_motoru = motor;

        // --- Nesneleri Glade'den Çekiyoruz ---
        combo_ogrenci_zili_sec = builder.get_object ("combo_ogrenci_zili_sec") as ComboBoxText;
        checkbutton_ogrenci_anonslu = builder.get_object ("checkbutton_ogrenci_anonslu") as CheckButton;
        adjustment4 = builder.get_object ("adjustment4") as Adjustment;
        checkbutton_anons_yapma = builder.get_object ("checkbutton_anons_yapma") as CheckButton;
        
        combo_ogretmen_zili_sec = builder.get_object ("combo_ogretmen_zili_sec") as ComboBoxText;
        checkbutton_ogretmen_anonslu = builder.get_object ("checkbutton_ogretmen_anonslu") as CheckButton;
        adjustment5 = builder.get_object ("adjustment5") as Adjustment;
        
        combo_cikis_zili_sec = builder.get_object ("combo_cikis_zili_sec") as ComboBoxText;
        adjustment6 = builder.get_object ("adjustment6") as Adjustment;

        // --- Buton Sinyalleri ---
        var btn_ogrenci = builder.get_object ("button_ogrenci_zili_dinle") as Button;
        btn_ogrenci.clicked.connect (() => { ogrenci_zili_baslat (false); });

        var btn_ogretmen = builder.get_object ("button_ogretmen_zili_dinle") as Button;
        btn_ogretmen.clicked.connect (ogretmen_zili_baslat);

        var btn_cikis = builder.get_object ("button_cikis_zili_dinle") as Button;
        btn_cikis.clicked.connect (cikis_zili_baslat);

        var button_zili_durdur = builder.get_object ("button_zili_durdur") as Button;
        if (button_zili_durdur != null) {
            button_zili_durdur.clicked.connect (zili_sustur);
        }

        // Zilleri listeye doldur
        zilleri_yukle ();

        // --- HAFIZA: Eski ayarları yükle ---
        ayarlari_yukle ();

        // --- Sinyal Bağlantıları (Her değişiklikte otomatik kaydet) ---
        combo_ogrenci_zili_sec.changed.connect (ayarlari_kaydet);
        combo_ogretmen_zili_sec.changed.connect (ayarlari_kaydet);
        combo_cikis_zili_sec.changed.connect (ayarlari_kaydet);
        
        checkbutton_ogrenci_anonslu.toggled.connect (ayarlari_kaydet);
        checkbutton_ogretmen_anonslu.toggled.connect (ayarlari_kaydet);
        
        if (checkbutton_anons_yapma != null) checkbutton_anons_yapma.toggled.connect (ayarlari_kaydet);
        
        // Ses seviyeleri değişince de kaydetmek istersen:
        adjustment4.value_changed.connect (ayarlari_kaydet);
        adjustment5.value_changed.connect (ayarlari_kaydet);
        adjustment6.value_changed.connect (ayarlari_kaydet);

        ses_motoru.sarki_bitti.connect (zil_bitti_kontrolu);
    }

    // --- YENİ VE GÜVENLİ: AYARLARI KAYDETME FONKSİYONU ---
    public void ayarlari_kaydet () {
        var ayar = AyarYoneticisi.instance ();

        ayar.yaz_yazi ("Melodiler", "OgrenciZili", combo_ogrenci_zili_sec.get_active_id () ?? "");
        ayar.yaz_yazi ("Melodiler", "OgretmenZili", combo_ogretmen_zili_sec.get_active_id () ?? "");
        ayar.yaz_yazi ("Melodiler", "CikisZili", combo_cikis_zili_sec.get_active_id () ?? "");
        
        ayar.yaz_mantiksal ("Melodiler", "OgrenciAnons", checkbutton_ogrenci_anonslu.active);
        ayar.yaz_mantiksal ("Melodiler", "OgretmenAnons", checkbutton_ogretmen_anonslu.active);
        
        if (checkbutton_anons_yapma != null) ayar.yaz_mantiksal ("Melodiler", "IlkZilAnonsIptal", checkbutton_anons_yapma.active);
        
        ayar.yaz_ondalik ("Melodiler", "OgrenciSes", adjustment4.get_value ());
        ayar.yaz_ondalik ("Melodiler", "OgretmenSes", adjustment5.get_value ());
        ayar.yaz_ondalik ("Melodiler", "CikisSes", adjustment6.get_value ());

        ayar.kaydet (); // Tüm bilgileri yöneticiye verdik, o güvenlice kaydedecek!
    }

    // --- YENİ VE GÜVENLİ: AYARLARI YÜKLEME FONKSİYONU ---
    public void ayarlari_yukle () {
        var ayar = AyarYoneticisi.instance ();

        combo_ogrenci_zili_sec.set_active_id (ayar.oku_yazi ("Melodiler", "OgrenciZili"));
        combo_ogretmen_zili_sec.set_active_id (ayar.oku_yazi ("Melodiler", "OgretmenZili"));
        combo_cikis_zili_sec.set_active_id (ayar.oku_yazi ("Melodiler", "CikisZili"));
        
        checkbutton_ogrenci_anonslu.active = ayar.oku_mantiksal ("Melodiler", "OgrenciAnons", false);
        checkbutton_ogretmen_anonslu.active = ayar.oku_mantiksal ("Melodiler", "OgretmenAnons", false);
        
        if (checkbutton_anons_yapma != null) checkbutton_anons_yapma.active = ayar.oku_mantiksal ("Melodiler", "IlkZilAnonsIptal", false);
        
        adjustment4.set_value (ayar.oku_ondalik ("Melodiler", "OgrenciSes", 50.0));
        adjustment5.set_value (ayar.oku_ondalik ("Melodiler", "OgretmenSes", 50.0));
        adjustment6.set_value (ayar.oku_ondalik ("Melodiler", "CikisSes", 50.0));
    }

    // Zil çalma fonksiyonları 
    public void ogrenci_zili_baslat (bool ilk_zil = false) {
        string secilen = combo_ogrenci_zili_sec.get_active_id ();
        if (secilen == null) return;

        anons_caliyor_mu = false;
        aktif_adjustment = adjustment4; // Öğrenci ayarını kullan
        
        // --- ANONS KARAR MERKEZİ ---
        bool anons_yapilsin_mi = checkbutton_ogrenci_anonslu.get_active ();
        
        // Eğer ilk zilse VE "ilk zilde anons yapma" kutusu işaretliyse anonsu İPTAL ET
        if (ilk_zil && checkbutton_anons_yapma != null && checkbutton_anons_yapma.get_active ()) {
            anons_yapilsin_mi = false;
        }

        // Karara göre GÖMÜLÜ anons dosyasını ayarla
        aktif_anons_dosyasi = anons_yapilsin_mi ? "resource:///org/ark/okulzili/Sesler/ogrencianons.mp3" : "";
        
        // Zil dışarıdan klasörden okunmaya devam ediyor
        string yol = GLib.Environment.get_current_dir () + "/Sesler/Ziller/" + secilen;
        ses_motoru.cal (yol, aktif_adjustment);
    }

    public void ogretmen_zili_baslat () {
        string secilen = combo_ogretmen_zili_sec.get_active_id ();
        if (secilen == null) return;

        anons_caliyor_mu = false;
        aktif_adjustment = adjustment5; // Öğretmen ayarını kullan
        
        // GÖMÜLÜ anons dosyasını ayarla
        aktif_anons_dosyasi = checkbutton_ogretmen_anonslu.get_active () ? "resource:///org/ark/okulzili/Sesler/ogretmenanons.mp3" : "";
        
        string yol = GLib.Environment.get_current_dir () + "/Sesler/Ziller/" + secilen;
        ses_motoru.cal (yol, aktif_adjustment);
    }

    public void cikis_zili_baslat () {
        string secilen = combo_cikis_zili_sec.get_active_id ();
        if (secilen == null) return;

        anons_caliyor_mu = false;
        aktif_adjustment = adjustment6; // Çıkış ayarını kullan
        aktif_anons_dosyasi = ""; // Çıkış zilinde anons yok
        
        string yol = GLib.Environment.get_current_dir () + "/Sesler/Ziller/" + secilen;
        ses_motoru.cal (yol, aktif_adjustment);
    }

    public void zili_sustur () {
        ses_motoru.durdur ();
        anons_caliyor_mu = false;
        aktif_anons_dosyasi = "";
    }

    private void zil_bitti_kontrolu () {
        if (!anons_caliyor_mu && aktif_anons_dosyasi != "") {
            anons_caliyor_mu = true;
            
            // --- DÜZELTİLEN KISIM: Artık sadece resource adresini doğrudan kullanıyoruz ---
            string yol = aktif_anons_dosyasi; 
            aktif_anons_dosyasi = ""; 
            
            ses_motoru.cal (yol, aktif_adjustment); // Anonsu, zilin kendi ayarıyla çal
        } else {
            anons_caliyor_mu = false;
        }
    }

    private void zilleri_yukle () {
        string yol = GLib.Path.build_filename (GLib.Environment.get_current_dir (), "Sesler", "Ziller");
        var klasor = GLib.File.new_for_path (yol);

        try {
            var enum_files = klasor.enumerate_children (GLib.FileAttribute.STANDARD_NAME, 0);
            GLib.FileInfo info;
            while ((info = enum_files.next_file ()) != null) {
                if (info.get_name ().has_suffix (".mp3")) {
                    string isim = info.get_name ();
                    // append (ID, TEXT) -> ID olarak dosya adını veriyoruz
                    combo_ogrenci_zili_sec.append (isim, isim);
                    combo_ogretmen_zili_sec.append (isim, isim);
                    combo_cikis_zili_sec.append (isim, isim);
                }
            }
            // Eğer seçili ID ayarlar dosyasından gelmediyse ilk öğeyi seç
            if (combo_ogrenci_zili_sec.get_active_id () == null) combo_ogrenci_zili_sec.set_active (0);
            if (combo_ogretmen_zili_sec.get_active_id () == null) combo_ogretmen_zili_sec.set_active (0);
            if (combo_cikis_zili_sec.get_active_id () == null) combo_cikis_zili_sec.set_active (0);
            
        } catch (GLib.Error e) {
            GLib.printerr ("Hata: %s\n", e.message);
        }
    }
}

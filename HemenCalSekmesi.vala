using Gtk;

public class HemenCalSekmesi : GLib.Object {
    private Button button_ogrenci_zili_cal;
    private Button button_ogretmen_zili_cal;
    private Button button_cikis_zili_cal;
    private Button button_istiklal_cal;
    private Button button_saygi_cal;
    private Button button_siren_cal;
    private Button button_durdur;

    private Adjustment adjustment1; 
    private Adjustment adjustment2; 
    private Adjustment adjustment3; 

    //Zaman Labelları
    private Label label_saat;
    private Label label_gun;
    private Label label_kalan_sure_normal;
    private Label label_kalan_sure_cuma;
    
    // Kapatma Kontrolleri
    private CheckButton checkbutton_poweroff;
    private SpinButton spinbutton_poweroff_saat;
    private SpinButton spinbutton_poweroff_dakika;

    private MelodiSekmesi melodi_hedefi;
    private ZamanYonetici zaman_yoneticisi;
    private SesMotoru ses_motoru;
    
    private int son_kapatma_dakikasi = -1;

    public HemenCalSekmesi (Builder builder, MelodiSekmesi hedef_sinif, SesMotoru motor, ZamanYonetici z_yonetici) {
        this.melodi_hedefi = hedef_sinif;
        this.zaman_yoneticisi = z_yonetici; 
        this.ses_motoru = motor;

        // --- Mevcut Buton Bağlantıları ---
        button_ogrenci_zili_cal = builder.get_object ("button_ogrenci_zili_cal") as Button;
        button_ogretmen_zili_cal = builder.get_object ("button_ogretmen_zili_cal") as Button;
        button_cikis_zili_cal = builder.get_object ("button_cikis_zili_cal") as Button;
        button_istiklal_cal = builder.get_object ("button_istiklal_cal") as Button;
        button_saygi_cal = builder.get_object ("button_saygi_cal") as Button;
        button_siren_cal = builder.get_object ("button_siren_cal") as Button;
        button_durdur = builder.get_object ("button_durdur") as Button;

        // --- EKSİK OLAN KISIM: Ses Ayarlarını Glade'den Çekiyoruz ---
        adjustment1 = builder.get_object ("adjustment1") as Adjustment;
        adjustment2 = builder.get_object ("adjustment2") as Adjustment;
        adjustment3 = builder.get_object ("adjustment3") as Adjustment;

        // --- Etiketleri (Label) Glade'den Çekiyoruz ---
        label_saat = builder.get_object ("label_saat") as Label;
        label_gun = builder.get_object ("label_gun") as Label;

        // --- Kalan Süre Etiketlerini Glade'den Çekiyoruz ---
        label_kalan_sure_normal = builder.get_object ("label_kalan_sure_normal") as Label;
        label_kalan_sure_cuma = builder.get_object ("label_kalan_sure_cuma") as Label;

        // --- Kapatma Nesnelerini Çekiyoruz ---
        checkbutton_poweroff = builder.get_object ("checkbutton_poweroff") as CheckButton;
        spinbutton_poweroff_saat = builder.get_object ("spinbutton_poweroff_saat") as SpinButton;
        spinbutton_poweroff_dakika = builder.get_object ("spinbutton_poweroff_dakika") as SpinButton;

        // --- Olay Bağlantıları ---
        button_ogrenci_zili_cal.clicked.connect (() => melodi_hedefi.ogrenci_zili_baslat ());
        button_ogretmen_zili_cal.clicked.connect (() => melodi_hedefi.ogretmen_zili_baslat ());
        button_cikis_zili_cal.clicked.connect (() => melodi_hedefi.cikis_zili_baslat ());

        // --- GÖMÜLÜ SESLER İÇİN YOL GÜNCELLEMELERİ ---
        button_istiklal_cal.clicked.connect (() => {
            ses_motoru.cal ("resource:///org/ark/okulzili/Sesler/Resmi/istiklal.mp3", adjustment1);
        });

        button_saygi_cal.clicked.connect (() => {
            // 1. ADIM: Motorun hafızasına sıradaki marşı ve onun ses ayarını yüklüyoruz
            ses_motoru.siradaki_ses = "resource:///org/ark/okulzili/Sesler/Resmi/istiklal.mp3";         
            ses_motoru.siradaki_ayar = adjustment2; 
            
            // 2. ADIM: Saygı duruşunu da aynı ses seviyesiyle (adjustment2) çalarak zinciri başlatıyoruz
            ses_motoru.cal ("resource:///org/ark/okulzili/Sesler/Resmi/saygi.mp3", adjustment2);
        });

        button_siren_cal.clicked.connect (() => {
            ses_motoru.cal ("resource:///org/ark/okulzili/Sesler/Resmi/siren.mp3", adjustment3);
        });

        button_durdur.clicked.connect (() => melodi_hedefi.zili_sustur ());

        // --- EKSİK OLAN KISIM: Ayarları Yükle ve Değişimleri Dinle ---
        ayarlari_yukle ();

        if (checkbutton_poweroff != null) checkbutton_poweroff.toggled.connect (ayarlari_kaydet);
        if (spinbutton_poweroff_saat != null) spinbutton_poweroff_saat.value_changed.connect (ayarlari_kaydet);
        if (spinbutton_poweroff_dakika != null) spinbutton_poweroff_dakika.value_changed.connect (ayarlari_kaydet);
        
        if (adjustment1 != null) adjustment1.value_changed.connect (ayarlari_kaydet);
        if (adjustment2 != null) adjustment2.value_changed.connect (ayarlari_kaydet);
        if (adjustment3 != null) adjustment3.value_changed.connect (ayarlari_kaydet);

        // HER SANİYE SAATİ KONTROL ET
        GLib.Timeout.add_seconds (1, saniyelik_dongu);
    }

    private bool saniyelik_dongu () {
        var simdi = new DateTime.now_local ();
        int gun_no = simdi.get_day_of_week (); 
        
        if (gun_no == 5) {
            zaman_yoneticisi.cuma_saatlerini_denetle (simdi);
            zaman_yoneticisi.kalan_sureyi_guncelle (simdi, true, label_kalan_sure_cuma); 
        } else {
            zaman_yoneticisi.normal_saatleri_denetle (simdi);
            zaman_yoneticisi.kalan_sureyi_guncelle (simdi, false, label_kalan_sure_normal);
        }

        label_saat.set_text (simdi.format ("%H:%M:%S"));
        label_gun.set_text (simdi.format ("%d %B %Y %A"));

        // 2. Bilgisayarı Kapatma Kontrolü
        if (checkbutton_poweroff != null && checkbutton_poweroff.get_active ()) {
            int hedef_saat = (int) spinbutton_poweroff_saat.get_value ();
            int hedef_dakika = (int) spinbutton_poweroff_dakika.get_value ();

            if (simdi.get_hour () == hedef_saat && 
                simdi.get_minute () == hedef_dakika && 
                simdi.get_second () == 0) {
            
                if (son_kapatma_dakikasi != hedef_dakika) {
                    son_kapatma_dakikasi = hedef_dakika;
                    bilgisayari_kapat ();
                }
            }
        }

        return true;
    }

    private void bilgisayari_kapat () {
        print ("Sistem yetki istemediği için direkt kapatılıyor...\n");
        try {
            Process.spawn_command_line_async ("/sbin/poweroff");
        } catch (GLib.Error e) {
            printerr ("Kapatma hatası: %s\n", e.message);
        }
    }

    // --- YENİ EKLENEN MERKEZİ AYAR YÖNETİMİ FONKSİYONLARI ---
    private void ayarlari_kaydet () {
        var ayar = AyarYoneticisi.instance ();
        
        if (checkbutton_poweroff != null) ayar.yaz_mantiksal ("Sistem", "PowerOff_Aktif", checkbutton_poweroff.active);
        if (spinbutton_poweroff_saat != null) ayar.yaz_ondalik ("Sistem", "PowerOff_Saat", spinbutton_poweroff_saat.value);
        if (spinbutton_poweroff_dakika != null) ayar.yaz_ondalik ("Sistem", "PowerOff_Dakika", spinbutton_poweroff_dakika.value);
        
        if (adjustment1 != null) ayar.yaz_ondalik ("Sesler", "Istiklal_Ses", adjustment1.value);
        if (adjustment2 != null) ayar.yaz_ondalik ("Sesler", "Saygi_Ses", adjustment2.value);
        if (adjustment3 != null) ayar.yaz_ondalik ("Sesler", "Siren_Ses", adjustment3.value);
        
        ayar.kaydet ();
    }

    private void ayarlari_yukle () {
        var ayar = AyarYoneticisi.instance ();
        
        if (checkbutton_poweroff != null) checkbutton_poweroff.active = ayar.oku_mantiksal ("Sistem", "PowerOff_Aktif", false);
        if (spinbutton_poweroff_saat != null) spinbutton_poweroff_saat.value = ayar.oku_ondalik ("Sistem", "PowerOff_Saat", 17.0);
        if (spinbutton_poweroff_dakika != null) spinbutton_poweroff_dakika.value = ayar.oku_ondalik ("Sistem", "PowerOff_Dakika", 0.0);
        
        if (adjustment1 != null) adjustment1.value = ayar.oku_ondalik ("Sesler", "Istiklal_Ses", 50.0);
        if (adjustment2 != null) adjustment2.value = ayar.oku_ondalik ("Sesler", "Saygi_Ses", 50.0);
        if (adjustment3 != null) adjustment3.value = ayar.oku_ondalik ("Sesler", "Siren_Ses", 50.0);
    }
}

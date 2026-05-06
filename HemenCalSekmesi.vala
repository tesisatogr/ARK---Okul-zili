using Gtk;

public class HemenCalSekmesi : GLib.Object {
    // ... (Mevcut Butonlar ve Adjustmentlar) ...
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
    
    // Yeni Kapatma Kontrolleri
    private CheckButton checkbutton_poweroff;
    private SpinButton spinbutton_poweroff_saat;
    private SpinButton spinbutton_poweroff_dakika;

    private MelodiSekmesi melodi_hedefi;
    private ZamanYonetici zaman_yoneticisi;
    private SesMotoru ses_motoru;
    
    private int son_kapatma_dakikasi = -1;

    public HemenCalSekmesi (Builder builder, MelodiSekmesi hedef_sinif, SesMotoru motor, ZamanYonetici z_yonetici) {
        this.melodi_hedefi = hedef_sinif;
        this.zaman_yoneticisi = z_yonetici; // Artık yeni yaratmıyor, main'den geleni alıyor
        this.ses_motoru = motor;

        // --- Mevcut Buton Bağlantıları ---
        button_ogrenci_zili_cal = builder.get_object ("button_ogrenci_zili_cal") as Button;
        button_ogretmen_zili_cal = builder.get_object ("button_ogretmen_zili_cal") as Button;
        button_cikis_zili_cal = builder.get_object ("button_cikis_zili_cal") as Button;
        button_istiklal_cal = builder.get_object ("button_istiklal_cal") as Button;
        button_saygi_cal = builder.get_object ("button_saygi_cal") as Button;
        button_siren_cal = builder.get_object ("button_siren_cal") as Button;
        button_durdur = builder.get_object ("button_durdur") as Button;

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
            ses_motoru.cal ("resource:///org/ark/okulzili/Sesler/Resmi/saygi.mp3", adjustment2);
        });

        button_siren_cal.clicked.connect (() => {
            ses_motoru.cal ("resource:///org/ark/okulzili/Sesler/Resmi/siren.mp3", adjustment3);
        });

        button_durdur.clicked.connect (() => melodi_hedefi.zili_sustur ());

        // HER SANİYE SAATİ KONTROL ET
        GLib.Timeout.add_seconds (1, saniyelik_dongu);
    }

    private bool saniyelik_dongu () {
        var simdi = new DateTime.now_local ();
        int gun_no = simdi.get_day_of_week (); // 1: Pazartesi ... 5: Cuma
        
        if (gun_no == 5) {
            // CUMA GÜNÜ: Cuma kutularını tara!
            zaman_yoneticisi.cuma_saatlerini_denetle (simdi);
            zaman_yoneticisi.kalan_sureyi_guncelle (simdi, true, label_kalan_sure_cuma); 
        } else {
            // DİĞER GÜNLER: Normal saatleri kontrol et
            zaman_yoneticisi.normal_saatleri_denetle (simdi);
            zaman_yoneticisi.kalan_sureyi_guncelle (simdi, false, label_kalan_sure_normal);
        }

        label_saat.set_text (simdi.format ("%H:%M:%S"));
        label_gun.set_text (simdi.format ("%d %B %Y %A"));

        // 2. Bilgisayarı Kapatma Kontrolü
        if (checkbutton_poweroff.get_active ()) {
            int hedef_saat = (int) spinbutton_poweroff_saat.get_value ();
            int hedef_dakika = (int) spinbutton_poweroff_dakika.get_value ();

            if (simdi.get_hour () == hedef_saat && 
            simdi.get_minute () == hedef_dakika && 
            simdi.get_second () == 0) {
            
            // DÜZELTME: Saniye 0 olsa bile aynı dakika içinde sadece 1 kez kapatma komutu yollar
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
}

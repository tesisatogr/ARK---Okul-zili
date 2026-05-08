using Gtk;
using GLib;

public class ZamanYonetici : GLib.Object {
    
    private MelodiSekmesi melodi_hedefi;
    private MuzikYayiniSekmesi muzik_hedefi;
    private int son_calan_dakika = -1;

    // --- KUTULAR VE AYARLAR ---
    private Entry[] tum_ogrenci = new Entry[16];
    private Entry[] tum_ogretmen = new Entry[16];
    private Entry[] tum_cikis = new Entry[16];
    private Entry[] cuma_ogrenci = new Entry[16];
    private Entry[] cuma_ogretmen = new Entry[16];
    private Entry[] cuma_cikis = new Entry[16];



    public ZamanYonetici (Builder builder, MelodiSekmesi melodi, MuzikYayiniSekmesi muzik) {
        this.melodi_hedefi = melodi;
        this.muzik_hedefi = muzik;

        // --- 1. NESNELERİ GLADE'DEN ÇEKME ---
        for (int i = 0; i < 8; i++) {
            tum_ogrenci[i] = builder.get_object ("sabah_ogrenci_%d".printf (i + 1)) as Entry;
            tum_ogretmen[i] = builder.get_object ("sabah_ogretmen_%d".printf (i + 1)) as Entry;
            tum_cikis[i] = builder.get_object ("sabah_cikis_%d".printf (i + 1)) as Entry;
            tum_ogrenci[i + 8] = builder.get_object ("ogle_ogrenci_%d".printf (i + 1)) as Entry;
            tum_ogretmen[i + 8] = builder.get_object ("ogle_ogretmen_%d".printf (i + 1)) as Entry;
            tum_cikis[i + 8] = builder.get_object ("ogle_cikis_%d".printf (i + 1)) as Entry;

            cuma_ogrenci[i] = builder.get_object ("cuma_sabah_ogrenci_%d".printf (i + 1)) as Entry;
            cuma_ogretmen[i] = builder.get_object ("cuma_sabah_ogretmen_%d".printf (i + 1)) as Entry;
            cuma_cikis[i] = builder.get_object ("cuma_sabah_cikis_%d".printf (i + 1)) as Entry;
            cuma_ogrenci[i + 8] = builder.get_object ("cuma_ogle_ogrenci_%d".printf (i + 1)) as Entry;
            cuma_ogretmen[i + 8] = builder.get_object ("cuma_ogle_ogretmen_%d".printf (i + 1)) as Entry;
            cuma_cikis[i + 8] = builder.get_object ("cuma_ogle_cikis_%d".printf (i + 1)) as Entry;
        }
		
		ayarlari_yukle ();
		

        // --- 2. SİNYALLERİ BAĞLAMA (OTOMATİK KAYIT) ---
        for (int i = 0; i < 16; i++) {
            bagla_akilli_denetim (tum_ogrenci[i]); bagla_akilli_denetim (tum_ogretmen[i]); bagla_akilli_denetim (tum_cikis[i]);
            bagla_akilli_denetim (cuma_ogrenci[i]); bagla_akilli_denetim (cuma_ogretmen[i]); bagla_akilli_denetim (cuma_cikis[i]);
        }


        // Temizle Butonları
        var btn_normal = builder.get_object ("button_saat_temizle") as Button;
        if (btn_normal != null) btn_normal.clicked.connect (normal_saatleri_temizle);
        var btn_cuma = builder.get_object ("button_cuma_saat_temizle") as Button;
        if (btn_cuma != null) btn_cuma.clicked.connect (cuma_saatlerini_temizle);

        
    }

    private void bagla_akilli_denetim (Entry? kutu) {
        if (kutu != null) {
            kutu.focus_out_event.connect ((w, e) => { return saat_dogrula_ve_formatla (w as Entry); });
        }
    }

    private bool saat_dogrula_ve_formatla (Entry kutu) {
        string metin = kutu.get_text ().strip ();
        var context = kutu.get_style_context ();
        if (metin == "") { context.remove_class ("error"); ayarlari_kaydet (); return false; }

        string islenen = metin.replace (".", ":").replace (",", ":");
        if (!islenen.contains (":")) {
            if (islenen.length <= 2) islenen = islenen + ":00";
            else if (islenen.length == 3) islenen = islenen.substring(0, 1) + ":" + islenen.substring(1, 2);
            else if (islenen.length == 4) islenen = islenen.substring(0, 2) + ":" + islenen.substring(2, 2);
        }

        bool gecerli = false;
        string[] parcalar = islenen.split (":");
        if (parcalar.length == 2) {
                int sa = int.parse (parcalar[0]);
                int dk = int.parse (parcalar[1]);
                if (sa >= 0 && sa <= 23 && dk >= 0 && dk <= 59) { kutu.set_text ("%02d:%02d".printf (sa, dk)); gecerli = true; }
        }

        if (gecerli) context.remove_class ("error");
        else context.add_class ("error");

        ayarlari_kaydet ();
        return false;
    }

	public void ayarlari_kaydet () {
        var ayar = AyarYoneticisi.instance (); // Merkezi yöneticiyi çağırıyoruz

        // 1. Saatleri Kaydet
        for (int i = 0; i < 8; i++) {
            ayar.yaz_yazi ("NormalSaatler", "Sabah_Ogrenci_%d".printf(i+1), tum_ogrenci[i].get_text ());
            ayar.yaz_yazi ("NormalSaatler", "Sabah_Ogretmen_%d".printf(i+1), tum_ogretmen[i].get_text ());
            ayar.yaz_yazi ("NormalSaatler", "Sabah_Cikis_%d".printf(i+1), tum_cikis[i].get_text ());
            ayar.yaz_yazi ("NormalSaatler", "Ogle_Ogrenci_%d".printf(i+1), tum_ogrenci[i+8].get_text ());
            ayar.yaz_yazi ("NormalSaatler", "Ogle_Ogretmen_%d".printf(i+1), tum_ogretmen[i+8].get_text ());
            ayar.yaz_yazi ("NormalSaatler", "Ogle_Cikis_%d".printf(i+1), tum_cikis[i+8].get_text ());

            ayar.yaz_yazi ("CumaSaatleri", "Sabah_Ogrenci_%d".printf(i+1), cuma_ogrenci[i].get_text ());
            ayar.yaz_yazi ("CumaSaatleri", "Sabah_Ogretmen_%d".printf(i+1), cuma_ogretmen[i].get_text ());
            ayar.yaz_yazi ("CumaSaatleri", "Sabah_Cikis_%d".printf(i+1), cuma_cikis[i].get_text ());
            ayar.yaz_yazi ("CumaSaatleri", "Ogle_Ogrenci_%d".printf(i+1), cuma_ogrenci[i+8].get_text ());
            ayar.yaz_yazi ("CumaSaatleri", "Ogle_Ogretmen_%d".printf(i+1), cuma_ogretmen[i+8].get_text ());
            ayar.yaz_yazi ("CumaSaatleri", "Ogle_Cikis_%d".printf(i+1), cuma_cikis[i+8].get_text ());
        }


        ayar.kaydet (); // Bütün siparişleri verdik, şimdi tek seferde diske yaz diyoruz!
    }

    private void ayarlari_yukle () {
        var ayar = AyarYoneticisi.instance ();
        
        // try-catch bloklarına artık gerek yok, AyarYoneticisi bunu arkada hallediyor!
        for (int i = 0; i < 8; i++) {
            if (tum_ogrenci[i] != null) tum_ogrenci[i].set_text (ayar.oku_yazi ("NormalSaatler", "Sabah_Ogrenci_%d".printf(i+1), ""));
            if (tum_ogretmen[i] != null) tum_ogretmen[i].set_text (ayar.oku_yazi ("NormalSaatler", "Sabah_Ogretmen_%d".printf(i+1), ""));
            if (tum_cikis[i] != null) tum_cikis[i].set_text (ayar.oku_yazi ("NormalSaatler", "Sabah_Cikis_%d".printf(i+1), ""));
            if (tum_ogrenci[i+8] != null) tum_ogrenci[i+8].set_text (ayar.oku_yazi ("NormalSaatler", "Ogle_Ogrenci_%d".printf(i+1), ""));
            if (tum_ogretmen[i+8] != null) tum_ogretmen[i+8].set_text (ayar.oku_yazi ("NormalSaatler", "Ogle_Ogretmen_%d".printf(i+1), ""));
            if (tum_cikis[i+8] != null) tum_cikis[i+8].set_text (ayar.oku_yazi ("NormalSaatler", "Ogle_Cikis_%d".printf(i+1), ""));

            if (cuma_ogrenci[i] != null) cuma_ogrenci[i].set_text (ayar.oku_yazi ("CumaSaatleri", "Sabah_Ogrenci_%d".printf(i+1), ""));
            if (cuma_ogretmen[i] != null) cuma_ogretmen[i].set_text (ayar.oku_yazi ("CumaSaatleri", "Sabah_Ogretmen_%d".printf(i+1), ""));
            if (cuma_cikis[i] != null) cuma_cikis[i].set_text (ayar.oku_yazi ("CumaSaatleri", "Sabah_Cikis_%d".printf(i+1), ""));
            if (cuma_ogrenci[i+8] != null) cuma_ogrenci[i+8].set_text (ayar.oku_yazi ("CumaSaatleri", "Ogle_Ogrenci_%d".printf(i+1), ""));
            if (cuma_ogretmen[i+8] != null) cuma_ogretmen[i+8].set_text (ayar.oku_yazi ("CumaSaatleri", "Ogle_Ogretmen_%d".printf(i+1), ""));
            if (cuma_cikis[i+8] != null) cuma_cikis[i+8].set_text (ayar.oku_yazi ("CumaSaatleri", "Ogle_Cikis_%d".printf(i+1), ""));
        }


    }

    // --- DİĞER FONKSİYONLAR (Denetle, Tarayıcı vs. aynı kalıyor) ---
    public void normal_saatleri_denetle (DateTime simdi) { saat_tarayici (simdi, tum_ogrenci, tum_ogretmen, tum_cikis, false); }
    public void cuma_saatlerini_denetle (DateTime simdi) { saat_tarayici (simdi, cuma_ogrenci, cuma_ogretmen, cuma_cikis, true); }
    private void saat_tarayici (DateTime simdi, Entry[] ogrenci, Entry[] ogretmen, Entry[] cikis, bool cuma_mi) {
        int anlik_dakika = simdi.get_minute ();
        
        // 1. KORUMA KALKANI
        if (son_calan_dakika == anlik_dakika) return;

        for (int i = 0; i < 16; i++) {
            if (ogrenci[i] != null && saat_eslesiyor_mu (ogrenci[i].get_text (), simdi)) { 
                muzik_hedefi.teneffus_bitti (); 
                melodi_hedefi.ogrenci_zili_baslat (i==0); 
                son_calan_dakika = anlik_dakika; 
                return; 
            }
            if (ogretmen[i] != null && saat_eslesiyor_mu (ogretmen[i].get_text (), simdi)) { 
                muzik_hedefi.teneffus_bitti (); 
                melodi_hedefi.ogretmen_zili_baslat (); 
                son_calan_dakika = anlik_dakika; 
                return; 
            }
            if (cikis[i] != null && saat_eslesiyor_mu (cikis[i].get_text (), simdi)) { 
                muzik_hedefi.teneffus_basladi (i, cuma_mi); 
                melodi_hedefi.cikis_zili_baslat (); 
                son_calan_dakika = anlik_dakika; 
                return; 
            }
        }
      
    }
    private bool saat_eslesiyor_mu (string deger, DateTime simdi) {
        if (deger == null || deger.strip () == "" || !deger.contains(":")) return false;
        string[] parcalar = deger.split (":");
        return (int.parse(parcalar[0]) == simdi.get_hour () && int.parse(parcalar[1]) == simdi.get_minute ());
    }
    public void kalan_sureyi_guncelle (DateTime simdi, bool cuma_mi, Label hedef_label) {
        if (hedef_label == null) return;
        int su_an = (simdi.get_hour () * 60) + simdi.get_minute ();
        int en_yakin = 1440; bool bulundu = false;
        Entry[] l1 = cuma_mi ? cuma_ogrenci : tum_ogrenci;
        Entry[] l2 = cuma_mi ? cuma_ogretmen : tum_ogretmen;
        Entry[] l3 = cuma_mi ? cuma_cikis : tum_cikis;
        for (int i = 0; i < 16; i++) { fark_bak (l1[i], su_an, ref en_yakin, ref bulundu); fark_bak (l2[i], su_an, ref en_yakin, ref bulundu); fark_bak (l3[i], su_an, ref en_yakin, ref bulundu); }
        if (bulundu) hedef_label.set_text ("Sıradaki zile %d dakika kaldı".printf (en_yakin - su_an));
        else hedef_label.set_text ("Bugünlük ziller tamamlandı.");
    }
    private void fark_bak (Entry e, int su_an, ref int en_yakin, ref bool bulundu) {
        if (e == null || e.get_text ().strip () == "" || !e.get_text().contains(":")) return;
        string[] p = e.get_text ().split (":");
        int t = (int.parse(p[0]) * 60) + int.parse(p[1]);
        if (t > su_an && t < en_yakin) { en_yakin = t; bulundu = true; }
    }
    private void normal_saatleri_temizle () { for (int i=0; i<16; i++) { tum_ogrenci[i]?.set_text(""); tum_ogretmen[i]?.set_text(""); tum_cikis[i]?.set_text(""); } ayarlari_kaydet (); }
    private void cuma_saatlerini_temizle () { for (int i=0; i<16; i++) { cuma_ogrenci[i]?.set_text(""); cuma_ogretmen[i]?.set_text(""); cuma_cikis[i]?.set_text(""); } ayarlari_kaydet (); }
}

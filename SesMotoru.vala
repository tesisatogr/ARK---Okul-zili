using Gst;
using Gtk;

public class SesMotoru : GLib.Object {
    private Element playbin;
    public signal void sarki_bitti ();
    private Adjustment? aktif_ayar = null; 
    private ulong sinyal_id = 0;           

    // --- YENİ: KUYRUK SİSTEMİ HAFIZASI ---
    public string? siradaki_ses = null;
    public Adjustment? siradaki_ayar = null;

    public SesMotoru () {
        playbin = ElementFactory.make ("playbin", "merkezi_motor");
        playbin.get_bus ().add_watch (GLib.Priority.DEFAULT, mesaj_yakala);
    }

    public void cal (string dosya_yolu, Adjustment adj) {
        playbin.set_state (State.NULL);
        
        // Önceki sinyal bağlantısı varsa temizle (Çakışmayı önler)
        if (aktif_ayar != null && sinyal_id > 0) {
            aktif_ayar.disconnect (sinyal_id);
        }

        this.aktif_ayar = adj;
        
        // --- GÜR SES FORMÜLÜ UYGULANIYOR ---
        double gurluk_orani = (adj.get_value () / 100.0) * 2.0;
        playbin.set ("volume", gurluk_orani);

        sinyal_id = adj.value_changed.connect (() => {
            double dinamik_gur_ses = (adj.get_value () / 100.0) * 2.0;
            playbin.set ("volume", dinamik_gur_ses);
        });

        // --- AKILLI YOL (URI) YÖNLENDİRİCİSİ ---
        string kusursuz_uri = "";
        if (dosya_yolu.has_prefix ("resource://") || dosya_yolu.has_prefix ("file://")) {
            kusursuz_uri = dosya_yolu;
        } else {
            try {
                kusursuz_uri = GLib.Filename.to_uri (dosya_yolu, null);
            } catch (GLib.Error e) {
                printerr ("Dosya yolu hatası: %s\n", e.message);
                return; 
            }
        }

        playbin.set ("uri", kusursuz_uri);
        playbin.set_state (State.PLAYING);
    }

    public void durdur () {
        // MANUEL DURDURMADA ZİNCİRİ KOPAR!
        siradaki_ses = null;
        siradaki_ayar = null;
        playbin.set_state (State.NULL);
    }

    private bool mesaj_yakala (Gst.Bus bus, Gst.Message mesaj) {
        if (mesaj.type == Gst.MessageType.EOS) {
            // Şarkı bitti! Motoru durdurmadan önce sıradaki şarkıyı ve ayarını cebimize alalım
            string? yedek_ses = siradaki_ses;
            Adjustment? yedek_ayar = siradaki_ayar;
            
            durdur (); // DİKKAT: Bu fonksiyon siradaki_ses değişkenlerini sıfırlayacak
            sarki_bitti (); // Arayüzdeki butonları normale döndüren sinyal
            
            // Eğer cebimizde bekleyen bir şarkı ve ayar varsa, vakit kaybetmeden ateşle!
            if (yedek_ses != null && yedek_ayar != null) {
                cal (yedek_ses, yedek_ayar);
            }
        }
        return true;
    }
}

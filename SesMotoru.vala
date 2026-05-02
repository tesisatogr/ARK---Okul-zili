using Gst;
using Gtk;

public class SesMotoru : GLib.Object {
    private Element playbin;
    public signal void sarki_bitti ();
    private Adjustment? aktif_ayar = null; // Şu anki ses ayar düğmesini tutar
    private ulong sinyal_id = 0;          // Sinyal bağlantısını temizlemek için

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
        // (Deger / 100) ile 0-1 arası oran bulunur, * 3.0 ile ses yükseltilir
        double gurluk_orani = (adj.get_value () / 100.0) * 3.0;
        playbin.set ("volume", gurluk_orani);

        sinyal_id = adj.value_changed.connect (() => {
            double dinamik_gur_ses = (adj.get_value () / 100.0) * 3.0;
            playbin.set ("volume", dinamik_gur_ses);
        });

        try {
            string kusursuz_uri = GLib.Filename.to_uri (dosya_yolu, null);
            playbin.set ("uri", kusursuz_uri);
        } catch (GLib.Error e) {
            printerr ("Dosya yolu hatası: %s\n", e.message);
        }

        playbin.set_state (State.PLAYING);
    }

    public void durdur () {
        playbin.set_state (State.NULL);
    }

    private bool mesaj_yakala (Gst.Bus bus, Gst.Message mesaj) {
        if (mesaj.type == Gst.MessageType.EOS) {
            durdur ();
            sarki_bitti ();
        }
        return true;
    }
}

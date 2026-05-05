using Gtk;
using Gst;

void main (string[] args) {
    Gtk.init (ref args);
    Gst.init (ref args);

    var builder = new Builder ();
    try {
        // İŞTE SİHİRLİ DEĞİŞİKLİK BURADA: Artık file değil, resource!
        builder.add_from_resource ("/org/ark/okulzili/main_ui.glade");
    } catch (GLib.Error e) {
        GLib.printerr ("Kritik Hata: Gömülü arayüz yüklenemedi! Detay: %s\n", e.message);
        return; // Dosya yoksa programı güvenlice kapat
    }

    var win = builder.get_object ("main_window") as Window;
    win.destroy.connect (Gtk.main_quit);

    // 1. Önce tek bir bağımsız motor yarat!
    var merkez_motor = new SesMotoru ();

    // 2. Motoru ilgili sekmelere ver (YENİ EKLENEN muzik_sekmesi)
    var muzik_sekmesi = new MuzikYayiniSekmesi (builder, merkez_motor);
    var melodi_sekmesi = new MelodiSekmesi (builder, merkez_motor);
    var hemen_cal_sekmesi = new HemenCalSekmesi (builder, melodi_sekmesi, merkez_motor, muzik_sekmesi);

    win.show_all ();
    Gtk.main ();
}

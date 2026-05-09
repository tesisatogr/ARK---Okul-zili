using Gtk;
using Gst;

public class ArkOkulZili : Gtk.Application {
    private Gtk.Window win;
    private Gtk.StatusIcon tray_icon;

    public ArkOkulZili () {
        GLib.Object (application_id: "org.ark.okulzili", flags: ApplicationFlags.FLAGS_NONE);
    }

    protected override void activate () {
        var builder = new Gtk.Builder ();
        try {
            builder.add_from_resource ("/org/ark/okulzili/main_ui.glade");
        } catch (GLib.Error e) {
            GLib.printerr ("Kritik Hata: Gömülü arayüz yüklenemedi! Detay: %s\n", e.message);
            return;
        }

        win = builder.get_object ("main_window") as Gtk.Window;
        
        // --- YENİ İKON YOLU SİSTEMİ ---
        string ev_dizini = GLib.Environment.get_home_dir ();
        // İkonu artık ~/.local/share/icons/ark.svg konumunda arıyoruz
        string ikon_yolu = GLib.Path.build_filename (ev_dizini, ".local", "share", "icons", "ark.svg");
        
        tray_icon = new Gtk.StatusIcon.from_file (ikon_yolu);
        tray_icon.set_tooltip_text ("ARK Okul Zili Çalışıyor");
        tray_icon.set_visible (true);

        tray_icon.activate.connect (() => {
            if (win.get_visible ()) {
                win.hide ();
            } else {
                win.present ();
            }
        });

        tray_icon.popup_menu.connect ((button, activate_time) => {
            var menu = new Gtk.Menu ();
            
            var item_goster = new Gtk.MenuItem.with_label ("Pencereyi Aç");
            item_goster.activate.connect (() => { win.present (); });
            menu.append (item_goster);

            menu.append (new Gtk.SeparatorMenuItem ());

            var item_cikis = new Gtk.MenuItem.with_label ("Programı Kapat");
            item_cikis.activate.connect (() => { this.quit (); });
            menu.append (item_cikis);

            menu.show_all ();
            menu.popup (null, null, null, button, activate_time);
        });

        win.delete_event.connect ((event) => {
            win.hide_on_delete ();
            return true;
        });

        var merkez_motor = new SesMotoru ();
        var muzik_sekmesi = new MuzikYayiniSekmesi (builder, merkez_motor);
        var melodi_sekmesi = new MelodiSekmesi (builder, merkez_motor);
        var zaman_yoneticisi = new ZamanYonetici (builder, melodi_sekmesi, muzik_sekmesi);
        new HemenCalSekmesi (builder, melodi_sekmesi, merkez_motor, zaman_yoneticisi);

        win.show_all ();
        this.add_window (win);
    }
}

int main (string[] args) {
    Gst.init (ref args);
    var app = new ArkOkulZili ();
    return app.run (args);
}

using GLib;

public class AyarYoneticisi : Object {
    private static AyarYoneticisi _instance;
    private KeyFile kf;
    private string dosya_yolu;

    private AyarYoneticisi () {
        kf = new KeyFile ();
        // Linux yapılandırma standardı: /home/kullanici/.config/okulzili/
        string config_dir = Path.build_filename (Environment.get_user_config_dir (), "ARK-okul-zili");
        DirUtils.create_with_parents (config_dir, 0755);
        dosya_yolu = Path.build_filename (config_dir, "ayarlar.conf");
        
        try { kf.load_from_file (dosya_yolu, KeyFileFlags.NONE); } catch { }
    }

    // Bu sınıf "Singleton" mantığıyla çalışır, program boyunca sadece 1 tane var olur.
    public static AyarYoneticisi instance () {
        if (_instance == null) _instance = new AyarYoneticisi ();
        return _instance;
    }

    public void kaydet () {
        try { FileUtils.set_contents (dosya_yolu, kf.to_data ()); } catch { }
    }

    public string oku_yazi (string grup, string anahtar, string varsayilan = "") {
        try { return kf.get_string (grup, anahtar); } catch { return varsayilan; }
    }
    public void yaz_yazi (string grup, string anahtar, string deger) {
        kf.set_string (grup, anahtar, deger);
    }

    public bool oku_mantiksal (string grup, string anahtar, bool varsayilan = false) {
        try { return kf.get_boolean (grup, anahtar); } catch { return varsayilan; }
    }
    public void yaz_mantiksal (string grup, string anahtar, bool deger) {
        kf.set_boolean (grup, anahtar, deger);
    }

    public double oku_ondalik (string grup, string anahtar, double varsayilan = 0.0) {
        try { return kf.get_double (grup, anahtar); } catch { return varsayilan; }
    }
    public void yaz_ondalik (string grup, string anahtar, double deger) {
        kf.set_double (grup, anahtar, deger);
    }
}

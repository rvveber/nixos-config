import Astal from "gi://Astal?version=4.0"
import AstalIO from "gi://AstalIO"
import GLib from "gi://GLib"
import Gtk from "gi://Gtk?version=4.0"
import GObject from "gi://GObject?version=2.0"
import Gdk from "gi://Gdk?version=4.0"
import Gio from "gi://Gio"
import { string, boolean } from "./props"

// Korrekturmaßnahme für WindowAnchor: importiere die korrekten Anker-Konstanten
const { TOP } = Astal.WindowAnchor

export default class AppLauncher extends Astal.Window {
    static {
        GObject.registerClass(
            {
                GTypeName: "AppLauncher",
                Template: "resource:///ui/AppLauncher.ui",
                InternalChildren: ["appsFlowBox", "searchEntry", "categoriesBox"],
                Properties: {
                    ...string("search-text", ""),
                    ...boolean("is-searching", false),
                    ...string("selected-category", "All"),
                },
            },
            this,
        )
    }

    declare search_text: string
    declare is_searching: boolean
    declare selected_category: string
    declare _appsFlowBox: Gtk.FlowBox
    declare _searchEntry: Gtk.SearchEntry
    declare _categoriesBox: Gtk.Box

    private appInfos: Gio.AppInfo[] = []
    private categories: Set<string> = new Set(["All"])
    private categoryButtons: Map<string, Gtk.ToggleButton> = new Map()

    constructor() {
        super({
            visible: true,
            exclusivity: Astal.Exclusivity.NORMAL,
            anchor: TOP, // Geändert von CENTER zu TOP, da CENTER nicht verfügbar ist
            cssClasses: ["AppLauncher"],
        })

        // Apps laden
        this.loadApps()
        
        // Suche einrichten
        this._searchEntry.connect("search-changed", () => {
            this.search_text = this._searchEntry.text;
            this.is_searching = this.search_text.length > 0;
            this.filterApps();
        });

        // Kategorie-Buttons einrichten
        this.setupCategoryButtons();
        
        // App-Aktivierung behandeln
        this._appsFlowBox.connect("child-activated", (_, child) => {
            if (!child) return;
            
            const box = child.get_child() as Gtk.Box;
            if (!box) return;
            
            const appInfo = this.getAppInfoFromBox(box);
            if (appInfo) {
                try {
                    // Hier ist die Korrektur: Eine leere Liste statt null für 'files' übergeben
                    appInfo.launch([], null);
                    this.close();
                } catch (e) {
                    console.error(`Fehler beim Starten der App: ${e}`);
                }
            }
        });
        
        // Tastatursteuerung hinzufügen
        const keyController = new Gtk.EventControllerKey();
        keyController.connect("key-pressed", (_, keyval) => {
            if (keyval === Gdk.KEY_Escape) {
                this.close();
                return true;
            }
            return false;
        });
        this.add_controller(keyController);
        
        // Fokus auf die Suchleiste setzen
        this._searchEntry.grab_focus();
    }

    // Helper-Methode, um auf sichere Weise das AppInfo aus einer Box zu erhalten
    private getAppInfoFromBox(box: Gtk.Box): Gio.AppInfo | null {
        // In GJS-GTK können wir keine Daten mit set_data anhängen, 
        // daher müssen wir einen anderen Ansatz verwenden
        // Wir verwenden das erste Kind des Containers, um die App-ID zu speichern
        const firstChild = box.get_first_child();
        if (firstChild && firstChild instanceof Gtk.Label) {
            const appName = firstChild.get_text();
            return this.appInfos.find(info => info.get_name() === appName) || null;
        }
        return null;
    }

    private loadApps() {
        // Alle Desktop-Anwendungen laden
        this.appInfos = Gio.AppInfo.get_all()
            .filter(appInfo => appInfo.should_show())
            .sort((a, b) => {
                return a.get_name().localeCompare(b.get_name());
            });
        
        // Kategorien extrahieren
        this.appInfos.forEach(appInfo => {
            const categories = this.getAppCategories(appInfo);
            categories.forEach(category => {
                if (category && category.trim() !== "") {
                    this.categories.add(category);
                }
            });
        });
        
        // Apps-Grid erstellen
        this.populateAppGrid();
    }

    private getAppCategories(appInfo: Gio.AppInfo): string[] {
        try {
            const desktopFile = appInfo.get_id();
            if (!desktopFile) return [];
            
            const keyFile = new GLib.KeyFile();
            const path = GLib.build_filenamev([
                "/usr/share/applications", 
                desktopFile
            ]);
            
            if (keyFile.load_from_file(path, GLib.KeyFileFlags.NONE)) {
                const categoryString = keyFile.get_string("Desktop Entry", "Categories");
                if (categoryString) {
                    return categoryString.split(";")
                        .filter(cat => cat.trim() !== "")
                        .map(cat => this.formatCategoryName(cat));
                }
            }
        } catch (e) {
            // Stillschweigendes Fehlschlagen, wenn wir keine Kategorien erhalten können
        }
        return [];
    }

    private formatCategoryName(category: string): string {
        // CamelCase, with- oder with_ in lesbares Format umwandeln
        return category
            .replace(/([A-Z])/g, ' $1')
            .replace(/[-_]/g, ' ')
            .trim();
    }

    private setupCategoryButtons() {
        // Kategorie-Buttons hinzufügen
        Array.from(this.categories).sort().forEach(category => {
            const button = new Gtk.ToggleButton({
                label: category,
                active: category === "All",
            });
            
            button.connect("toggled", () => {
                if (button.active) {
                    // Andere Buttons deaktivieren
                    this.categoryButtons.forEach((btn, cat) => {
                        if (cat !== category && btn.active) {
                            btn.active = false;
                        }
                    });
                    this.selected_category = category;
                    this.filterApps();
                } else if (Array.from(this.categoryButtons.values()).every(btn => !btn.active)) {
                    // Mindestens ein Button muss aktiv sein
                    button.active = true;
                }
            });
            
            this.categoryButtons.set(category, button);
            this._categoriesBox.append(button);
        });
    }

    private populateAppGrid() {
        // Vorhandene Kinder löschen
        let child = this._appsFlowBox.get_first_child();
        while (child) {
            this._appsFlowBox.remove(child);
            child = this._appsFlowBox.get_first_child();
        }
        
        // App-Launcher hinzufügen
        this.appInfos.forEach(appInfo => {
            const box = new Gtk.Box({
                orientation: Gtk.Orientation.VERTICAL,
                spacing: 6,
                halign: Gtk.Align.CENTER,
            });
            
            // App-Icon
            const icon = appInfo.get_icon();
            const image = new Gtk.Image({
                gicon: icon ?? undefined,
                pixel_size: 48,
            });
            
            // App-Name - wir verwenden dies, um die App später wiederzufinden
            // Das erste Kind des Containers ist ein verstecktes Label mit dem Namen
            const hiddenLabel = new Gtk.Label({
                label: appInfo.get_name(),
                visible: false,
            });
            
            // Sichtbares Label für den Benutzer
            const visibleLabel = new Gtk.Label({
                label: appInfo.get_name(),
                ellipsize: 3, // PANGO_ELLIPSIZE_END
                lines: 2,
                max_width_chars: 12,
                justify: Gtk.Justification.CENTER,
            });
            
            box.append(hiddenLabel);
            box.append(image);
            box.append(visibleLabel);
            
            const flowBoxChild = new Gtk.FlowBoxChild();
            flowBoxChild.set_child(box);
            this._appsFlowBox.append(flowBoxChild);
        });
    }

    private filterApps() {
        const searchText = this.search_text.toLowerCase();
        const selectedCategory = this.selected_category;
        
        let childIndex = 0;
        let child = this._appsFlowBox.get_child_at_index(childIndex);
        
        while (child) {
            const box = child.get_child() as Gtk.Box;
            if (box) {
                const appInfo = this.getAppInfoFromBox(box);
                let visible = true;
                
                if (appInfo) {
                    // Nach Suchtext filtern
                    if (this.is_searching) {
                        const name = appInfo.get_name().toLowerCase();
                        const desc = appInfo.get_description()?.toLowerCase() || "";
                        visible = name.includes(searchText) || desc.includes(searchText);
                    }
                    
                    // Nach Kategorie filtern, wenn nicht "All"
                    if (visible && selectedCategory !== "All") {
                        const categories = this.getAppCategories(appInfo);
                        visible = categories.includes(selectedCategory);
                    }
                } else {
                    visible = false;
                }
                
                child.set_visible(visible);
            }
            
            childIndex++;
            child = this._appsFlowBox.get_child_at_index(childIndex);
        }
    }
}

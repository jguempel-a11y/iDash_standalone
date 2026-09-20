# iDash — RFID Asset Intelligence Platform

![System](https://img.shields.io/badge/System-RFID%20Asset%20Intelligence-0066cc)
![Platform](https://img.shields.io/badge/Platform-ASP.NET%20Web%20Forms%20%7C%20C%23-512BD4)
![Database](https://img.shields.io/badge/Database-SQL%20Server%20Express-CC2927)
![Sites](https://img.shields.io/badge/VISN%205-6%20VA%20Medical%20Centers-10b981)
![Assets](https://img.shields.io/badge/Tracking-666%2C877%2B%20Assets-f59e0b)
![Accessibility](https://img.shields.io/badge/Section%20508-WCAG%202.0%20AA-10b981)

**iDash** is a standalone RFID asset intelligence platform for the VA VISN 5 tagging project. It provides consolidated reporting, real-time inventory management, cross-site data synchronization, direct BarTender SDK label printing, and field operations tools across six VA medical centers. Built as a high-performance ASP.NET Web Forms application with direct SQL Server connectivity by **ID Integration Inc.**

## 🏥 Active VA Sites (VISN 5)

| Station | Site | Status |
|---------|------|--------|
| 512 | Baltimore VA Medical Center | ✅ Active — Field sync automated |
| 517 | Beckley VA Medical Center | ✅ Active |
| 540 | Clarksburg VA Medical Center | ✅ Active |
| 581 | Huntington VA Medical Center | ✅ Active |
| 613 | Martinsburg VA Medical Center | ✅ Active — Primary field operations |
| 688 | Washington DC VA Medical Center | ✅ Active |

---

## 🎯 Core Capabilities

### Executive Reporting
- **Asset Statistics Dashboard** (`va_asset_stats.aspx`) — KPI cards for tagged/untagged/in-use assets with dollar values, site-level filtering, and CSV export
- **Tagging Dashboard** (`va_tag_stats.aspx`) — Executive overview, employee activity tracking, tag type analysis with click-to-preview, and site detail drill-down with column toggle pills
- **CMR/EIL Statistics** (`va_cmr_stats.aspx`) — Equipment inventory list compliance reporting
- **Asset Master** (`va_asset_master.aspx`) — Searchable, filterable master view of all assets with drag-and-drop column pills

### Field Operations
- **Tag Team Scan** (`va_tagteam_scan.aspx`) — Rapid physical inventory scanning with RFID tag printing, location tracking, and bulk operations
- **Site Inventory** (`va_inventory.aspx`) — Location-based inventory scanning with offline support via Service Worker
- **RFID Asset Locator** (`va_rfid_locator.aspx`) — Dedicated missing-asset hunting tool with geiger counter-style proximity meter, audio feedback, and DataWedge/WebSerial USB support
- **Fixed Reader Configuration** (`va_reader_config.aspx`) — Manage fixed RFID reader registrations, antenna/power mappings, and live online/offline status
- **Site Location Maps** (`va_site_maps.aspx`) — Visual dashboard for tracking tagging sweep progress through facility floor plans
- **ENNX Scanning** (`va_ennx.aspx`) — EA/Nil/No-eXcuse inventory sessions with VistA AEMS/MERS push capability

### Printing
- **Direct BarTender SDK Printing** — Labels are printed directly via the BarTender SDK (`BarTenderApiHelper.PrintDirect()`), bypassing any external print server or MQTT broker
- **Print Administration** (`va_print_admin.aspx`) — Template management, printer routing, test print, and setup wizard
- **Excel Equipment Import & Print** (`va_excel_print.aspx`) — Bulk import from Excel with automatic label printing
- **Label templates** stored in `C:\idash_prints\` (`.btw` BarTender files)

### Data Pipeline
- **Field Server Sync** (`va_field_sync.aspx`) — Automated nightly `.bak` restore and cross-database merge from remote VISN field servers
- **Data Import** (`va_data_import.aspx`) — Excel and CSV bulk import tools for asset records
- **Excel Merge** (`va_excel.aspx`) — Multi-file Excel merging for tagging team data consolidation
- **Site Data Export** (`va_sitedata_export.aspx`) — Filtered CSV/Excel exports by site

### Administration
- **User Management** (`va_user_management.aspx`) — Role-based access control with tile-level permissions and site assignment
- **Scanner & System User Management** (`va_aw_user_management.aspx`) — RFID scanner user and database credential administration
- **Database Workbench** (`va_dbupdate_workbench.aspx`) — SQL query interface with saved profiles for administrative operations
- **Log Viewer** (`va_log_viewer.aspx`) — Real-time application log monitoring
- **Automated Reports** (`va_automated_reports.aspx`) — Scheduled report generation and email delivery
- **System Diagnostics** (`va_system_diagnostics.aspx`) — Health checks for IIS, SQL Server, BarTender, and print pipeline

---

## 🏗️ Architecture

### Technology Stack

| Layer | Technology |
|-------|-----------|
| **Backend** | C# ASP.NET Web Forms (`.aspx` + `.aspx.cs` code-behind) |
| **Frontend** | HTML5, CSS3, vanilla JavaScript (no frameworks) |
| **Database** | SQL Server Express (`LingCod\SQLEXPRESS`) — direct `SqlConnection` queries |
| **Web Server** | Windows Server IIS — Port 8181 |
| **Printing** | BarTender SDK — direct in-process printing via `BarTenderApiHelper` |
| **Services** | Native in-process MQTT listener (AntennaLocationService), CrossSiteTagObserver |
| **Offline** | Service Worker (`sw.js`) with network-first strategy |
| **Theming** | CSS custom properties with `localStorage`-based light/dark toggle |

### Standalone Architecture

iDash operates completely independently as a standalone web application:
1. **Direct SQL** — All reporting and management tools query the database directly via `SqlConnection` using the `iDash` connection string.
2. **Direct BarTender SDK Printing** — Labels are printed in-process via the BarTender .NET SDK. No external print server, MQTT broker, or third-party service is required.
3. **Self-Contained** — All dependencies (documentation, print templates, configuration, tools) are contained within the `C:\inetpub\wwwroot\iDash\` directory.

### Directory Structure

```
C:\inetpub\wwwroot\iDash\
├── App_Code\              # Shared C# classes
│   ├── UserManager.cs     # Role/site-based access control & site filtering
│   ├── VAssetData.cs      # Database helper and asset data access
│   ├── BarTenderApiHelper.cs  # Direct BarTender SDK printing
│   ├── PrintApiHelper.cs  # Print job orchestration (PrintAssetsDirect, PrintJobsDirect)
│   ├── EmailHelper.cs     # SMTP email utilities
│   ├── AlertingService.cs # Asset alerting logic
│   └── LiveScanService.cs # Real-time RFID scan processing
├── documentation\         # 70+ HTML documentation pages (self-hosted docs hub)
│   ├── index.aspx         # Documentation hub with role-based tile access
│   ├── docs_theme.css     # Documentation theme stylesheet
│   └── *.html             # Individual feature documentation
├── Assets\                # Branding images, icons
├── Controls\              # Shared ASCX controls (iDashFooter.ascx)
├── site_maps\             # SVG facility floor plans
├── printing\              # Print scripts and label preview service
├── downloads\             # Downloadable files and reports
├── config\                # Configuration files
├── api\                   # Internal API endpoints
├── sql\                   # Database schema and setup scripts
├── tools\                 # Licensing, migration, and build tools
├── services\              # Background services (CrossSiteTagObserver)
├── workbench_profiles\    # Saved SQL workbench query profiles
├── 59 .aspx pages         # Application pages
├── theme.css              # Global light/dark theme system
├── sw.js                  # Service Worker for offline support
└── web.config             # IIS configuration and connection strings
```

### Shared Infrastructure

| Component | File | Purpose |
|-----------|------|---------|
| User Access Control | `App_Code/UserManager.cs` | Centralizes role checks, site filtering, and tile-level permissions. `BuildSiteFilter()` generates SQL WHERE clauses to restrict data by user's assigned sites. |
| Database Access | `App_Code/VAssetData.cs` | Shared SQL connection management and data reader utilities |
| Print Engine | `App_Code/BarTenderApiHelper.cs` | Direct BarTender SDK printing — `PrintDirect()` opens templates, sets SubStrings, and prints without any external service |
| Theme System | `theme.css` | CSS custom properties for light/dark mode; toggled via `localStorage('idash_theme')` |
| Service Worker | `sw.js` | Network-first caching for ASPX pages (7s timeout), cache-first for static assets |
| Documentation Hub | `documentation/index.aspx` | Role-aware documentation portal with 70+ technical reference pages |

---

## 📋 Web Pages Reference

### Reporting & Analytics (8 pages)

| Page | File | Description |
|------|------|-------------|
| Hub Dashboard | `index.aspx` | Main navigation hub with KPI tiles and role-based module access |
| Asset Statistics | `va_asset_stats.aspx` | Executive KPI dashboard — tagged, untagged, in-use, dollar values |
| Tagging Dashboard | `va_tag_stats.aspx` | 4-tab dashboard: Executive Overview, Employee Activity, Tag Type Analysis, Site Detail |
| CMR Statistics | `va_cmr_stats.aspx` | EIL/CMR compliance and tagged asset counts by equipment list |
| Asset Master | `va_asset_master.aspx` | Searchable full asset list with column pills and drag-reorder |
| Data Quality | `va_data_quality.aspx` | Data completeness analysis and missing-field detection |
| Data Research | `va_data_research.aspx` | Ad-hoc asset lookup and cross-referencing tool |
| Assets by Location | `va_assets_by_location.aspx` | Location-grouped asset inventory browser |

### Scanning & Field Operations (12 pages)

| Page | File | Description |
|------|------|-------------|
| Tag Team Scan | `va_tagteam_scan.aspx` | Primary tagging tool — scan, print labels, update assets |
| Site Inventory | `va_inventory.aspx` | Location-based inventory with offline support |
| ENNX Scanner | `va_ennx.aspx` | EA/Nil/No-eXcuse inventory session management |
| ENNX Mobile | `va_ennx_mobile.aspx` | Mobile-optimized ENNX scanning interface |
| ENNX Live Scan | `va_ennx_live_scan.aspx` | Real-time RFID reader integration for ENNX |
| EIL Live Scan | `va_eil_live_scan.aspx` | Equipment list live scanning |
| Universal Scan | `va_universal_ennx.aspx` | Cross-site universal scanning tool |
| RFID Asset Locator | `va_rfid_locator.aspx` | Dedicated missing-asset hunter with proximity meter, audio feedback, DataWedge + WebSerial USB support |
| Fixed Reader Config | `va_reader_config.aspx` | Fixed RFID reader registrations, antenna/power maps, live status |
| Site Maps | `va_site_maps.aspx` | SVG-based facility maps with tagging progress overlay |
| Location History | `va_previous_location.aspx` | Asset movement trail lookup |

### Printing & Labels (4 pages)

| Page | File | Description |
|------|------|-------------|
| Print Administration | `va_print_admin.aspx` | Template management, printer setup, test print, setup wizard |
| Printer Routing | `va_printer_routing.aspx` | Printer-to-site assignment and queue management |
| Print Mapping | `va_print_mapping.aspx` | Label template field mapping configuration |
| Excel Import & Print | `va_excel_print.aspx` | Bulk import from Excel with automatic label printing |

### Data Pipeline & Import (7 pages)

| Page | File | Description |
|------|------|-------------|
| Field Server Sync | `va_field_sync.aspx` | Nightly `.bak` restore and cross-database merge from field servers |
| Data Import | `va_data_import.aspx` | Bulk CSV/Excel asset import |
| Remote DB Update | `api/va_remote_import.ashx` | Network-safe import from any workstation via PowerShell (SqlBulkCopy) |
| Excel Merge | `va_excel.aspx` | Multi-file Excel merge for tagging team data |
| SQL Upload | `va_sql_upload.aspx` | Direct SQL script execution tool |
| DB Restore | `va_db_restore.aspx` | Database backup restoration interface |
| Site Data Export | `va_sitedata_export.aspx` | Filtered data export by site |

### Administration (10 pages)

| Page | File | Description |
|------|------|-------------|
| User Management | `va_user_management.aspx` | iDash role and tile access management |
| Scanner Users | `va_aw_user_management.aspx` | RFID scanner user and database credential administration |
| DB Update | `va_dbupdate.aspx` | Database update script runner |
| DB Workbench | `va_dbupdate_workbench.aspx` | Interactive SQL query workbench with saved profiles |
| Auto DB Update | `va_autodbupdate.aspx` | Scheduled database maintenance tasks |
| Report Automation | `va_report_automation.aspx` | Automated report scheduling and delivery |
| Site Configuration | `va_site_config.aspx` | Server configuration, print setup, and system settings |
| Log Viewer | `va_log_viewer.aspx` | Application log real-time viewer |
| System Diagnostics | `va_system_diagnostics.aspx` | Health checks: IIS, SQL Server, BarTender, print pipeline |
| License Manager | `va_license_manager.aspx` | iDash license activation and management |

---

## 🔒 Security Model

### User Access Control
- **Tile-based permissions** — Each page/feature is gated by a tile key (e.g., `scan_maps`, `report_stats`, `admin_users`)
- **Site-level filtering** — `UserManager.BuildSiteFilter()` generates SQL WHERE clauses restricting data to the user's assigned sites
- **Session-based auth** — Users authenticate via the iDash login portal; sessions track role, tiles, and site assignments
- **Wildcard access** — Admin users with `*` tile see all pages and all sites

### File System Permissions

```
NT SERVICE\MSSQL$SQLEXPRESS  → Read on incoming\, Full Control on staging_db\
BUILTIN\IIS_IUSRS            → Modify on C:\VA_RFID\va_sync\
```

See [Field Sync Documentation — Section 10](documentation/va_field_sync.html) for the complete guide on identifying the SQL Server service account and granting share/folder permissions.

---

## 🚀 Deployment

### Prerequisites
- Windows Server 2016+ with IIS enabled
- SQL Server Express (or full SQL Server)
- .NET Framework 4.7.2+
- PowerShell 5.1+
- BarTender 2022+ (for label printing)

### Installation
1. **Deploy iDash folder** to `C:\inetpub\wwwroot\iDash\`
2. **Configure IIS site** on port **8181** pointing to `C:\inetpub\wwwroot\iDash\`
3. **Configure `web.config`** with SQL Server connection string:
   ```xml
   <connectionStrings>
       <add name="iDash" connectionString="Server=SERVERNAME\SQLEXPRESS;Database=idash;User Id=idashadmin;Password=...;" />
   </connectionStrings>
   ```
4. **Create print directory** at `C:\idash_prints\` and place `.btw` BarTender templates
5. **Create sync folder structure** (for Field Sync):
   ```
   C:\VA_RFID\va_sync\
   ├── incoming\      ← .bak files land here
   ├── processed\     ← completed .bak files moved here
   └── staging_db\    ← SQL Server restores .mdf/.ldf here
   ```
6. **Set permissions** — Grant IIS_IUSRS modify access to the sync folder, and the SQL service account read/write as documented in the [Field Sync](documentation/va_field_sync.html) guide.

### Configuration

| Setting | Location | Description |
|---------|----------|-------------|
| DB Connection | `web.config` → `ConnectionStrings["iDash"]` | Primary SQL Server connection |
| Print Templates | `C:\idash_prints\` | BarTender `.btw` label template files |
| Theme | `localStorage` → `idash_theme` | `"light"` or `"dark"` |
| User tiles | `Session["IdashTileAccess"]` | `List<string>` of tile keys |
| User sites | `Session["IdashSiteAccess"]` | `List<string>` of company IDs |
| Service Worker | `sw.js` | Auto-registers on page load |

---

## 📚 Documentation

iDash includes a **self-hosted documentation hub** at `/iDash/documentation/index.aspx` with **70+ technical reference pages** covering every module. Documentation is role-aware — users only see docs for features they have access to.

### Key Reference Pages

| Document | Topic |
|----------|-------|
| [Architecture Rationale](documentation/idash_architecture_rationale.html) | Why the hybrid SQL + direct SDK design was chosen |
| [Deployment Guide](documentation/idash_deployment_guide.html) | Step-by-step server setup playbook |
| [Printing Guide](documentation/va_printing_guide.html) | Direct BarTender SDK printing, template management, and troubleshooting |
| [Field Server Sync](documentation/va_field_sync.html) | Nightly sync pipeline, SQL permissions, troubleshooting |
| [Section 508 Compliance](documentation/section508_compliance.html) | WCAG 2.0 AA accessibility criteria matrix |
| [System Architecture](documentation/va_system_architecture.html) | External state, dependencies, and server configuration map |
| [Component Manifest](documentation/va_site_config.html) | Full technical inventory for OIT security review |

---

## 🎨 UI Design

- **Light/Dark mode** — CSS custom properties with instant toggle, persisted in `localStorage`
- **Column pills** — Drag-and-drop pill buttons to show/hide and reorder table columns (Asset Master, Tag Stats)
- **Sort indicators** — ▲/▼ arrows on sortable column headers
- **Per-column filters** — Inline text filter inputs on data tables
- **Glass card layout** — Semi-transparent card containers with subtle backdrop blur
- **Responsive** — Flexbox-based layouts that adapt to screen width
- **Section 508 compliant** — Keyboard navigation, screen reader support, focus indicators, WCAG 2.0 AA color contrast

---

## 📝 License

Proprietary — **iDash** RFID Asset Intelligence Platform.  
Developed by **ID Integration Inc.** for the U.S. Department of Veterans Affairs, VISN 5.

---

**Last Updated:** September 20, 2026  
**Branch:** `main`  
**Port:** 8181 (Standalone)  
**Total ASPX Pages:** 59 | **Documentation Pages:** 70+

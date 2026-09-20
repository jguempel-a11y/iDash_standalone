# iDash — RFID Asset Intelligence Platform

![System](https://img.shields.io/badge/Platform-RFID%20Asset%20Intelligence-0066cc)
![Stack](https://img.shields.io/badge/Stack-ASP.NET%20%7C%20C%23%20%7C%20SQL%20Server-512BD4)
![Printing](https://img.shields.io/badge/Printing-BarTender%20SDK-00796B)
![Compliance](https://img.shields.io/badge/Section%20508-WCAG%202.0%20AA-10b981)
![License](https://img.shields.io/badge/License-Commercial-f59e0b)

**iDash** is a backend-agnostic RFID asset intelligence platform that transforms raw asset data into actionable operational tools. It connects to any SQL Server data source — whether from RFID middleware, ERP systems, or custom databases — and provides a rich suite of reporting dashboards, field scanning tools, label printing workflows, and administrative utilities through a single unified web interface.

Built by **[ID Integration Inc.](https://www.idintegration.com)**, iDash is designed for organizations managing large-scale physical asset inventories across multiple facilities. Currently deployed across the U.S. Department of Veterans Affairs and expanding into private sector healthcare and enterprise environments.

---

## What iDash Does

**iDash sits between your data and your people.** It doesn't replace your backend — it makes it usable.

- 📊 **See your data** — Executive dashboards, KPI cards, compliance reports, and drill-down analytics across every facility
- 📱 **Work in the field** — Mobile-ready scanning tools for inventory, tagging, and asset location with offline support
- 🏷️ **Print labels** — Direct BarTender SDK integration for RFID label printing — no middleware, no print servers, no MQTT brokers
- 🔄 **Sync everything** — Automated nightly database synchronization from remote field servers across distributed sites
- 🔐 **Control access** — Role-based permissions with site-level data isolation and tile-based feature gating

---

## 🎯 Core Capabilities

### Executive Reporting & Analytics
| Module | Description |
|--------|-------------|
| **Asset Master** | Searchable master view of all assets with drag-and-drop column pills, per-column filters, and bulk export |
| **Asset Statistics** | KPI dashboard — tagged, untagged, in-use, dollar values with site-level filtering |
| **Tagging Dashboard** | 4-tab analytics: Executive Overview, Employee Activity, Tag Type Analysis, Site Detail |
| **CMR/EIL Statistics** | Equipment inventory list compliance reporting |
| **Data Quality** | Data completeness analysis and missing-field detection |
| **Fixed Reader Report** | Observation-based reporting from fixed RFID reader infrastructure |

### Field Operations & Scanning
| Module | Description |
|--------|-------------|
| **Tag Team Scan** | Rapid physical inventory — scan assets, print labels, update records in real time |
| **Site Inventory** | Location-based inventory scanning with Service Worker offline support |
| **ENNX Scanner** | EA/Nil/No-eXcuse inventory session management with VistA integration |
| **RFID Asset Locator** | Missing-asset hunter with geiger-style proximity meter, audio feedback, DataWedge + WebSerial USB |
| **Fixed Reader Config** | Manage fixed RFID reader registrations, antenna/power mappings, and live status |
| **Site Location Maps** | SVG-based facility maps with tagging progress overlay |

### Direct Label Printing
| Module | Description |
|--------|-------------|
| **Print Administration** | Template management, printer routing, test print, and one-click setup wizard |
| **Excel Import & Print** | Bulk import from Excel with automatic label printing |
| **Printer Routing** | Site-to-printer assignment and queue management |
| **Print Mapping** | Label template field mapping configuration |

> **No external print server required.** iDash prints directly through the BarTender SDK — labels go from screen to printer with zero middleware.

### Data Pipeline & Integration
| Module | Description |
|--------|-------------|
| **Field Server Sync** | Automated nightly `.bak` restore and cross-database merge from remote sites |
| **Data Import** | Bulk CSV/Excel asset import with validation |
| **Remote DB Update** | Network-safe import from any workstation via PowerShell (`SqlBulkCopy`) |
| **Site Data Export** | Filtered CSV/Excel exports by site, status, or custom criteria |
| **FHIR Bridge** | HL7 FHIR integration for healthcare interoperability |

### Administration & Operations
| Module | Description |
|--------|-------------|
| **User Management** | Role-based access with tile-level permissions, site assignment, and user templates |
| **System Diagnostics** | Health checks for IIS, SQL Server, BarTender, and print pipeline |
| **Database Workbench** | Interactive SQL query interface with saved profiles |
| **Automated Reports** | Scheduled report generation and email delivery |
| **Log Viewer** | Real-time application log monitoring |
| **License Manager** | Per-site license activation and management |

---

## 🏗️ Architecture

### Design Philosophy

iDash is a **presentation and operations layer** — not a database platform. It connects to your existing data infrastructure and provides the tools your teams actually need to do their work.

```
┌─────────────────────────────────────────────────────┐
│                    iDash Platform                    │
│                                                     │
│   Dashboards  │  Scanning  │  Printing  │  Admin    │
└───────────────┼────────────┼────────────┼───────────┘
                │            │            │
         ┌──────▼──────┐  ┌──▼──┐  ┌─────▼─────┐
         │  SQL Server  │  │RFID │  │ BarTender │
         │  (any source) │  │HW   │  │    SDK    │
         └─────────────┘  └─────┘  └───────────┘
```

### Technology Stack

| Layer | Technology |
|-------|-----------|
| **Backend** | C# ASP.NET Web Forms — `.aspx` pages with `.aspx.cs` code-behind |
| **Frontend** | HTML5, CSS3, vanilla JavaScript — zero framework dependencies |
| **Database** | SQL Server (Express or Standard) — direct `SqlConnection` queries |
| **Printing** | BarTender SDK — direct in-process printing, no middleware |
| **Web Server** | IIS on Windows Server |
| **Offline** | Service Worker with network-first caching strategy |
| **Theming** | CSS custom properties — light/dark mode with `localStorage` persistence |
| **Accessibility** | Section 508 / WCAG 2.0 AA compliant |

### Key Design Decisions

- **No JavaScript frameworks** — Vanilla JS keeps the stack simple, fast, and maintainable without build tooling
- **No ORM** — Direct SQL via `SqlConnection` / `SqlCommand` for full query control and performance
- **No external print service** — BarTender SDK runs in-process; labels print directly without MQTT, queues, or polling
- **Backend-agnostic** — Connects to any SQL Server database schema; field mappings are configurable per deployment
- **Self-contained** — Documentation, print templates, tools, and configuration all ship inside the application directory

### Directory Structure

```
iDash/
├── App_Code/              # Shared C# classes
│   ├── UserManager.cs     # Role/site-based access control & data filtering
│   ├── VAssetData.cs      # Database helper and asset data access
│   ├── BarTenderApiHelper.cs  # Direct BarTender SDK printing engine
│   ├── PrintApiHelper.cs  # Print job orchestration
│   └── EmailHelper.cs     # SMTP email utilities
├── documentation/         # 70+ self-hosted HTML reference pages
├── Controls/              # Shared ASCX controls (footer, nav)
├── printing/              # Print scripts and label preview service
├── sql/                   # Database schema and setup scripts
├── tools/                 # Licensing, migration, and deployment tools
├── services/              # Background services (CrossSiteTagObserver)
├── 59 .aspx pages         # Application pages
├── theme.css              # Global light/dark theme system
├── sw.js                  # Service Worker for offline support
└── web.config             # IIS configuration and connection strings
```

---

## 🚀 Deployment

### Prerequisites
- Windows Server 2016+ with IIS
- SQL Server Express or Standard
- .NET Framework 4.7.2+
- BarTender 2022+ (for label printing features)

### Quick Start
1. Deploy `iDash/` to your IIS web root
2. Create an IIS site on your chosen port (default: **8181**)
3. Configure `web.config` with your database connection:
   ```xml
   <connectionStrings>
       <add name="iDash" connectionString="Server=YOUR_SERVER;Database=idash;User Id=idashadmin;Password=...;" />
   </connectionStrings>
   ```
4. Place BarTender `.btw` templates in `C:\idash_prints\`
5. Browse to `http://your-server:8181/` and log in

### Configuration

| Setting | Location | Description |
|---------|----------|-------------|
| DB Connection | `web.config` → `ConnectionStrings["iDash"]` | Primary SQL Server connection |
| Print Templates | `C:\idash_prints\` | BarTender `.btw` label template files |
| User Auth | `App_Data/idash_users.json` | Local user accounts (or integrate with your IdP) |
| Theme | `localStorage` → `idash_theme` | `"light"` or `"dark"` — user preference |

---

## 🔒 Security

- **Tile-based permissions** — Every page and feature is gated by a tile key; users only see what they're authorized to access
- **Site-level data isolation** — SQL WHERE clauses are dynamically generated per user, restricting data to assigned facilities
- **Role hierarchy** — Admin, User, and custom roles with granular tile and site assignments
- **Session-based authentication** — Supports local auth or integration with external identity providers
- **Section 508 / WCAG 2.0 AA** — Keyboard navigation, screen reader support, focus indicators, and color contrast compliance

---

## 📚 Documentation

iDash ships with a **self-hosted documentation hub** containing **70+ technical reference pages** — accessible from within the application at `/documentation/`. Documentation is role-aware; users only see guides for features they have access to.

| Document | Topic |
|----------|-------|
| Architecture Rationale | Design decisions and technology choices |
| Deployment Guide | Step-by-step server setup playbook |
| Printing Guide | BarTender SDK setup, template management, troubleshooting |
| Field Server Sync | Distributed database synchronization pipeline |
| Section 508 Compliance | WCAG 2.0 AA accessibility criteria matrix |
| System Architecture | Dependencies, external state, and server configuration |

---

## 🎨 UI Design

- **Light/Dark mode** — Instant toggle with CSS custom properties, persisted per user
- **Drag-and-drop columns** — Pill buttons to show, hide, and reorder table columns
- **Per-column search** — Inline filter inputs on every data table
- **Glass card layout** — Modern semi-transparent containers with backdrop blur
- **Responsive** — Flexbox layouts that adapt from desktop to mobile
- **Micro-animations** — Smooth transitions on hover, sort, and filter interactions

---

## 📝 License

**iDash** is a commercial product developed by **[ID Integration Inc.](https://www.idintegration.com)**  
Licensed per deployment. Contact [ID Integration](https://www.idintegration.com) for pricing and evaluation.

---

*Built with ❤️ by ID Integration Inc.*

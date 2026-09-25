<%@ Page Language="C#" AutoEventWireup="true" Inherits="System.Web.UI.Page" MaintainScrollPositionOnPostback="true" %>
    <%@ Register Src="~/Controls/iDashFooter.ascx" TagPrefix="idash" TagName="Footer" %>
        <%@ Import Namespace="System" %>
            <%@ Import Namespace="System.Data" %>
                <%@ Import Namespace="System.Data.SqlClient" %>
                    <%@ Import Namespace="System.Linq" %>
                        <%@ Import Namespace="System.Text" %>
                            <%@ Import Namespace="System.Net" %>
                                <%@ Import Namespace="System.Net.Mail" %>
                                    <%@ Import Namespace="System.IO" %>
                                        <%@ Import Namespace="System.Configuration" %>
                                            <%@ Import Namespace="System.Collections.Generic" %>
                                                <%@ Import Namespace="System.Web.Configuration" %>

                                                    <!DOCTYPE html>
                                                    <html>

                                                    <head>
                                                        <meta charset="utf-8" />
                                                        <title>VA AssetWorx ENNX History</title>
            <link rel="icon" type="image/png" href="/iDash/Assets/branding/rfid.png" />
            <link rel="stylesheet" href="theme.css" />
            <script src="theme-init.js"></script>
                                                        <style>
                                                            /* ============================================================
           GLOBAL THEME
           ============================================================ */
                                                            :root {
                                                                --chip-br: var(--line);
                                                                --table-head: var(--chip);
                                                                --table-row-hover: rgba(0,0,0,0.02);
                                                            }

                                                            body {
                                                                margin: 0;
                                                                background: var(--bg);
                                                                color: var(--text);
                                                                font-family: Segoe UI, Tahoma, Arial, sans-serif;
                                                            }

                                                            * {
                                                                box-sizing: border-box;
                                                            }

                                                            a {
                                                                text-decoration: none;
                                                                color: inherit;
                                                            }

                                                            /* ============================================================
           LAYOUT
           ============================================================ */
                                                            .page {
                                                                max-width: 1400px;
                                                                margin: 40px auto;
                                                                padding: 0 40px;
                                                            }

                                                             /* PAGE HEADER */
                                                             .page-header {
                                                                 background: linear-gradient(135deg, color-mix(in srgb, var(--accent), var(--card) 88%) 0%, var(--card) 60%);
                                                                 border-bottom: 2px solid color-mix(in srgb, var(--accent), transparent 75%);
                                                                 padding: 14px 28px;
                                                                 display: flex;
                                                                 align-items: center;
                                                                 justify-content: space-between;
                                                                 position: sticky; top: 0; z-index: 100;
                                                                 box-shadow: 0 1px 12px color-mix(in srgb, var(--accent), transparent 90%);
                                                             }
                                                             .ph-brand { display: flex; align-items: center; gap: 12px; }
                                                             .ph-icon {
                                                                 width: 38px; height: 38px; border-radius: 10px;
                                                                 display: flex; align-items: center; justify-content: center;
                                                                 background: linear-gradient(135deg, var(--accent), color-mix(in srgb, var(--accent), #8B5CF6 40%));
                                                                 font-size: 18px; color: #fff;
                                                                 box-shadow: 0 2px 8px color-mix(in srgb, var(--accent), transparent 60%);
                                                                 flex-shrink: 0;
                                                             }
                                                             .ph-title { font-size: 18px; font-weight: 700; color: var(--text); line-height: 1.2; margin: 0; }
                                                             .ph-sub   { font-size: 11px; color: var(--muted); margin-top: 1px; }
                                                             .ph-nav { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
                                                             .ph-div { width: 1px; height: 22px; background: var(--line); margin: 0 2px; }

                                                             /* NAV PILLS */
                                                             .nav-pill {
                                                                 display: inline-flex; align-items: center; gap: 5px;
                                                                 padding: 6px 14px; border-radius: 20px;
                                                                 font-size: 12px; font-weight: 600;
                                                                 text-decoration: none; cursor: pointer;
                                                                 border: 1.5px solid var(--line);
                                                                 background: var(--chip); color: var(--text);
                                                                 transition: border-color .2s, background .2s, box-shadow .15s, transform .12s;
                                                                 line-height: 1; white-space: nowrap;
                                                             }
                                                             .nav-pill:hover {
                                                                 border-color: var(--accent); transform: translateY(-1px);
                                                                 box-shadow: 0 2px 8px color-mix(in srgb, var(--accent), transparent 80%);
                                                             }
                                                             .nav-pill-primary {
                                                                 background: color-mix(in srgb, var(--accent), transparent 88%);
                                                                 color: var(--accent); border-color: color-mix(in srgb, var(--accent), transparent 60%);
                                                             }
                                                             .nav-pill-primary:hover { background: color-mix(in srgb, var(--accent), transparent 78%); border-color: var(--accent); }
                                                             .nav-pill-ghost {}

                                                            /* CARD */
                                                            .card {
                                                                background: var(--card);
                                                                border: 1px solid var(--line);
                                                                border-radius: 14px;
                                                                padding: 24px;
                                                                margin-bottom: 24px;
                                                                box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
                                                            }

                                                            .card h2 {
                                                                margin: 0 0 20px 0;
                                                                font-size: 20px;
                                                                font-weight: 600;
                                                                color: var(--accent);
                                                                border-bottom: 1px solid var(--line);
                                                                padding-bottom: 10px;
                                                            }

                                                            /* CONTROLS */
                                                            .controls {
                                                                margin-top: 10px;
                                                            }

                                                            .btn-blue {
                                                                background: var(--accent) !important;
                                                                color: #fff !important;
                                                                border: none !important;
                                                                padding: 8px 16px !important;
                                                                border-radius: 6px !important;
                                                                cursor: pointer;
                                                                font-size: 14px;
                                                                font-weight: 600;
                                                                display: inline-block;
                                                            }

                                                            .btn-blue:hover {
                                                                opacity: 0.9;
                                                            }

                                                            .btn-outline {
                                                                background: transparent !important;
                                                                border: 1px solid var(--muted) !important;
                                                                color: var(--muted) !important;
                                                                padding: 6px 12px !important;
                                                                border-radius: 6px !important;
                                                                cursor: pointer;
                                                                font-size: 12px;
                                                            }

                                                            .btn-outline:hover {
                                                                border-color: var(--text) !important;
                                                                color: var(--text) !important;
                                                            }

                                                            .btn-danger {
                                                                background: var(--danger) !important;
                                                                color: white !important;
                                                                border: none !important;
                                                                padding: 6px 12px !important;
                                                                border-radius: 6px !important;
                                                            }

                                                            /* GRIDS & TABLES */
                                                            .grid {
                                                                border-collapse: collapse;
                                                                width: 100%;
                                                                margin-top: 10px;
                                                                font-size: 14px;
                                                            }

                                                            .grid th {
                                                                background: var(--table-head);
                                                                color: var(--accent);
                                                                text-align: left;
                                                                padding: 12px 8px;
                                                                border-bottom: 2px solid var(--line);
                                                                border-top: none;
                                                                border-left: none;
                                                                border-right: none;
                                                            }

                                                            .grid td {
                                                                padding: 8px;
                                                                border-bottom:1px solid var(--line);
                                                                color: var(--text);
                                                                border-left: none;
                                                                border-right: none;
                                                                border-top: none;
                                                            }

                                                            .grid tr:hover {
                                                                background: var(--table-row-hover);
                                                            }

                                                            /* PREVIEW BOX */
                                                            .preview {
                                                                width: 100%;
                                                                height: 300px;
                                                                background: var(--chip);
                                                                color: var(--text);
                                                                border: 1px solid var(--line);
                                                                border-radius: 6px;
                                                                padding: 12px;
                                                                font-family: Consolas, monospace;
                                                                white-space: pre;
                                                                overflow: auto;
                                                                margin-top: 10px;
                                                                font-size: 13px;
                                                            }

                                                            /* RECIPIENT PANEL */
                                                            .recipient-panel {
                                                                margin-top: 20px;
                                                                border: 1px solid var(--line);
                                                                padding: 20px;
                                                                border-radius: 8px;
                                                                background-color: var(--chip);
                                                            }

                                                            .recipient-panel h3 {
                                                                margin-top: 0;
                                                                color: var(--text);
                                                                font-size: 18px;
                                                            }

                                                            /* INPUTS */
                                                            input[type="text"],
                                                            input[type="date"],
                                                            select {
                                                                background: var(--chip);
                                                                border: 1px solid var(--line);
                                                                color: var(--text);
                                                                padding: 8px;
                                                                border-radius: 6px;
                                                                font-size: 14px;
                                                            }

                                                            select {
                                                                padding-right: 24px;
                                                            }

                                                            .message {
                                                                margin-top: 10px;
                                                                display: block;
                                                                font-weight: 500;
                                                            }

                                                            .caption {
                                                                color: var(--muted);
                                                                font-size: 14px;
                                                                margin-top: 20px;
                                                                margin-bottom: 6px;
                                                            }
                                                        </style>
                                                        <style>
                                                            .sortable-grid th { cursor: pointer; user-select: none; white-space: nowrap; }
                                                            .sortable-grid th:last-child { cursor: default; }
                                                            .sortable-grid th .si { display: inline-block; margin-left: 5px; font-size: 10px; opacity: 0.35; transition: opacity .15s; }
                                                            .sortable-grid th.sort-asc .si,
                                                            .sortable-grid th.sort-desc .si { opacity: 1; color: var(--accent); }
                                                        </style>
                                                        <script>
                                                        document.addEventListener('DOMContentLoaded', function () {
                                                            document.querySelectorAll('table.sortable-grid').forEach(function (tbl) {
                                                                var tbody = tbl.querySelector('tbody');
                                                                if (!tbody) return;
                                                                var ths = Array.from(tbl.querySelectorAll('thead tr:first-child th'));
                                                                var lastCol = -1, asc = true;

                                                                ths.forEach(function (th, ci) {
                                                                    if (ci === ths.length - 1) return; // skip Actions
                                                                    var txt = th.innerText.trim();
                                                                    th.innerHTML = txt + ' <span class="si">&#9650;&#9660;</span>';
                                                                    th.title = 'Click to sort';
                                                                    th.addEventListener('click', function () {
                                                                        asc = (lastCol === ci) ? !asc : true;
                                                                        lastCol = ci;

                                                                        ths.forEach(function (h) {
                                                                            h.classList.remove('sort-asc', 'sort-desc');
                                                                            var s = h.querySelector('.si');
                                                                            if (s) s.innerHTML = '&#9650;&#9660;';
                                                                        });
                                                                        th.classList.add(asc ? 'sort-asc' : 'sort-desc');
                                                                        var s = th.querySelector('.si');
                                                                        if (s) s.innerHTML = asc ? '&#9650;' : '&#9660;';

                                                                        var rows = Array.from(tbody.querySelectorAll('tr'));
                                                                        // Keep filter input row pinned at top if present
                                                                        var filterRow = (rows.length && rows[0].querySelector('input[type="text"],input[type="search"]')) ? rows.shift() : null;

                                                                        rows.sort(function (a, b) {
                                                                            var av = a.cells[ci] ? a.cells[ci].innerText.trim() : '';
                                                                            var bv = b.cells[ci] ? b.cells[ci].innerText.trim() : '';
                                                                            var an = parseFloat(av), bn = parseFloat(bv);
                                                                            if (!isNaN(an) && !isNaN(bn)) return asc ? an - bn : bn - an;
                                                                            var ad = Date.parse(av), bd = Date.parse(bv);
                                                                            if (!isNaN(ad) && !isNaN(bd)) return asc ? ad - bd : bd - ad;
                                                                            return asc ? av.localeCompare(bv) : bv.localeCompare(av);
                                                                        });

                                                                        if (filterRow) tbody.insertBefore(filterRow, tbody.firstChild);
                                                                        rows.forEach(function (r) { tbody.appendChild(r); });
                                                                    });
                                                                });
                                                            });
                                                        });
                                                        </script>
                                                    </head>

                                                    <body>
                                                        <form id="form1" runat="server">
                                                            <div class="page-header">
                                                                <div class="ph-brand">
                                                                    <div class="ph-icon">&#128197;</div>
                                                                    <div>
                                                                        <div class="ph-title">ENNX Report History</div>
                                                                        <div class="ph-sub">View and manage ENNX report sessions</div>
                                                                    </div>
                                                                </div>
                                                                <div class="ph-nav">
                                                                    <a href="va_ennx.aspx" class="nav-pill nav-pill-primary">&#128228; New Export</a>
                                                                    <div class="ph-div"></div>
                                                                    <a href="index.aspx" class="nav-pill nav-pill-ghost">&#8962; Hub</a>
                                                                </div>
                                                            </div>

                                                            <div class="page">
                                                                <div class="card">

                                                                     <div
                                                                        style="display: flex; align-items: center; gap: 20px; margin-bottom: 20px; flex-wrap:wrap;">
                                                                        <!-- Filter Controls -->
                                                                        <div>
                                                                            <span style="color: var(--muted); margin-right: 10px;">Site:</span>
                                                                            <asp:DropDownList ID="DdlSiteFilter"
                                                                                runat="server" AutoPostBack="true"
                                                                                OnSelectedIndexChanged="DdlSiteFilter_SelectedIndexChanged"
                                                                                style="background:var(--chip); color:var(--text); border:1px solid var(--line); padding:4px; border-radius:4px;">
                                                                            </asp:DropDownList>
                                                                        </div>

                                                                        <div>
                                                                            <span
                                                                                style="color: var(--muted); margin-right: 10px;">Filter
                                                                                by User:</span>
                                                                            <asp:DropDownList ID="DdlUserFilter"
                                                                                runat="server" AutoPostBack="true"
                                                                                OnSelectedIndexChanged="DdlUserFilter_SelectedIndexChanged"
                                                                                style="background:var(--chip); color:var(--text); border:1px solid var(--line); padding:4px; border-radius:4px;">
                                                                            </asp:DropDownList>
                                                                        </div>

                                                                        <div>
                                                                            <span style="color: var(--muted); margin-right: 10px;">From:</span>
                                                                            <asp:TextBox ID="TxtFrom" runat="server" TextMode="Date" AutoPostBack="true" OnTextChanged="DateFilter_Changed" style="background:var(--chip); color:var(--text); border:1px solid var(--line); padding:4px; border-radius:4px;" />
                                                                         </div>

                                                                         <div>
                                                                             <span style="color: var(--muted); margin-right: 10px;">To:</span>
                                                                             <asp:TextBox ID="TxtTo" runat="server" TextMode="Date" AutoPostBack="true" OnTextChanged="DateFilter_Changed" style="background:var(--chip); color:var(--text); border:1px solid var(--line); padding:4px; border-radius:4px;" />
                                                                         </div></div>

                                                                        <asp:CheckBox ID="ChkHideEmptyUsers"
                                                                            runat="server" AutoPostBack="true"
                                                                            Text="Hide rows with no user"
                                                                            OnCheckedChanged="ChkHideEmptyUsers_CheckedChanged"
                                                                            style="color: var(--text);" />

                                                                        <asp:Button ID="BtnTotalTagged" runat="server" CssClass="btn-blue" Text="View All Tagged Assets" OnClick="BtnTotalTagged_Click" style="margin-left:auto;" />
                                                                    </div>
                                                                    
                                                                    <asp:Literal ID="LitHeader" runat="server" />

                                                                     <asp:GridView ID="GridSessions" runat="server"
                                                                        CssClass="grid sortable-grid" AutoGenerateColumns="false"
                                                                        OnRowCommand="GridSessions_RowCommand"
                                                                        GridLines="None">
                                                                        <Columns>
                                                                            <asp:BoundField DataField="Site"
                                                                                HeaderText="Site" />
                                                                            <asp:BoundField DataField="User"
                                                                                HeaderText="User" />
                                                                            <asp:BoundField DataField="Date"
                                                                                HeaderText="Date" />
                                                                            <asp:BoundField DataField="Count"
                                                                                HeaderText="Assets" />

                                                                            <asp:TemplateField HeaderText="Actions">
                                                                                <ItemTemplate>
                                                                                    <asp:Button ID="BtnPreviewItem"
                                                                                        runat="server" Text="Preview"
                                                                                        CommandName="Preview"
                                                                                        CommandArgument="<%# ((GridViewRow)Container).RowIndex %>"
                                                                                        CssClass="btn-outline" />

                                                                                    <asp:Button ID="BtnHidePreviewItem"
                                                                                        runat="server"
                                                                                        Text="Hide Preview"
                                                                                        CommandName="HidePreview"
                                                                                        CommandArgument="<%# ((GridViewRow)Container).RowIndex %>"
                                                                                        CssClass="btn-outline"
                                                                                        Visible="false" />

                                                                                </ItemTemplate>
                                                                            </asp:TemplateField>
                                                                        </Columns>
                                                                    </asp:GridView>

                                                                    <asp:GridView ID="GridTagged" runat="server" CssClass="grid" AutoGenerateColumns="true" GridLines="None" Visible="false"></asp:GridView>
                                                                    <div style="margin-top: 10px;">
                                                                        <asp:Button ID="BtnExportTagged" runat="server" CssClass="btn-blue" Text="Export Tagged as CSV" OnClick="BtnExportTagged_Click" Visible="false" />
                                                                    </div>

                                                                    <!-- Explicit ENNX Column Order -->
                                                                    <asp:GridView ID="GridPreview" runat="server"
                                                                        CssClass="grid" AutoGenerateColumns="False"
                                                                        GridLines="None">
                                                                        <Columns>
                                                                            <asp:BoundField DataField="Name"
                                                                                HeaderText="Name" />
                                                                            <asp:BoundField DataField="EIL"
                                                                                HeaderText="EIL" />
                                                                            <asp:BoundField DataField="CMR"
                                                                                HeaderText="CMR" />
                                                                            <asp:BoundField DataField="Description"
                                                                                HeaderText="Description" />
                                                                            <asp:BoundField DataField="Station_Number"
                                                                                HeaderText="Station Number" />
                                                                            <asp:BoundField DataField="Sub_Station"
                                                                                HeaderText="Sub Station" />
                                                                            <asp:BoundField DataField="Tag_Type"
                                                                                HeaderText="Tag Type" />
                                                                            <asp:BoundField DataField="Empl_ID"
                                                                                HeaderText="Empl ID" />
                                                                            <asp:BoundField
                                                                                DataField="Previous_Inventory_Date"
                                                                                HeaderText="Previous Inventory Date" />
                                                                            <asp:BoundField DataField="Tag_Date"
                                                                                HeaderText="Tag Date" />
                                                                            <asp:BoundField
                                                                                DataField="Scanned_Location"
                                                                                HeaderText="Scanned Location" />
                                                                            <asp:BoundField DataField="LocationTagged"
                                                                                HeaderText="Location Tagged" />
                                                                            <asp:BoundField DataField="RFID_Tag"
                                                                                HeaderText="RFID Tag" />
                                                                            <asp:BoundField DataField="DisposalStatus"
                                                                                HeaderText="Disposal Status" />
                                                                            <asp:BoundField DataField="Notes"
                                                                                HeaderText="Notes" />
                                                                            <asp:BoundField DataField="lastmodifiedby"
                                                                                HeaderText="Last Modified By" />
                                                                        </Columns>
                                                                    </asp:GridView>

                                                                    <div class="caption">ENNX Asset Text Preview</div>
                                                                    <asp:TextBox ID="TxtPreview" runat="server"
                                                                        CssClass="preview" TextMode="MultiLine"
                                                                        ReadOnly="true" />

                                                                    <div class="controls">

                                                                        <asp:Button ID="BtnDownloadPreview"
                                                                            runat="server" CssClass="btn-blue"
                                                                            Text="Download ENNX"
                                                                            OnClick="BtnDownloadPreview_Click" />

                                                                        <asp:Button ID="BtnEmailPreview" runat="server"
                                                                            CssClass="btn-blue" Text="Email ENNX"
                                                                            OnClick="BtnEmailPreview_Click" />

                                                                        <asp:Button ID="BtnExportCsv" runat="server"
                                                                            CssClass="btn-blue"
                                                                            Text="Export ENNX to CSV"
                                                                            OnClick="BtnExportCsv_Click" />

                                                                        <asp:Button ID="BtnEmailCsvUpload"
                                                                            runat="server" CssClass="btn-blue"
                                                                            Text="Email Previewed Session"
                                                                            OnClick="BtnEmailCsvUpload_Click" />

                                                                        <asp:Button ID="BtnEmailBatch"
                                                                            runat="server" CssClass="btn-blue"
                                                                            Text="Batch Email Everything (All Displayed Users/Sessions)"
                                                                            OnClick="BtnEmailBatch_Click" style="background:#1e3a8a; border-color:#3b82f6;" />

                                                                    <!-- Manage Recipients button removed and centralized to index.aspx -->

                                                                    </div>

                                                                    <asp:Label ID="LblMessage" runat="server"
                                                                        CssClass="message" />

                                                                    <!-- Manage Recipients panel removed and centralized to index.aspx -->
                                                                </div>

                                                                <idash:Footer runat="server" />
                                                            </div>
                                                        </form>

                                                        <script runat="server">

    // ============================================================
    // INLINE SERVER CODE
    // ============================================================

    protected void Page_Load(object sender, EventArgs e)
                                                            {
                                                                // Auth check
                                                                bool isLoggedIn = Session["IsAdminAuthenticated"] != null && (bool)Session["IsAdminAuthenticated"];
                                                                if (!isLoggedIn) { Response.Redirect("index.aspx"); return; }

                                                                // Tile check
                                                                var tiles = Session["IdashTileAccess"] as List<string>;
                                                                string role = System.Convert.ToString(Session["IdashUserRole"]);
                                                                if (!UserManager.CanAccessTile(role, tiles, "rpt_ennx") && !UserManager.CanAccessTile(role, tiles, "rpt_sessions"))
                                                                {
                                                                    Response.Redirect("index.aspx?err=access"); return;
                                                                }

                                                                if (!IsPostBack) {
                                                                    ChkHideEmptyUsers.Checked = true;
                                                                    PopulateSiteDropdown();
                                                                    PopulateUserDropdown();
                                                                    LoadSessions();
                                                                    GridPreview.Visible = false;
                                                                    TxtPreview.Visible = false;
                                                                }
                                                            }

    private string CleanCell(object val)
                                                            {
                                                                if (val == null) return string.Empty;
        string s = val.ToString().Trim();
                                                                if (s == "&nbsp;" || s == "&#160;" || s == "&amp;nbsp;") return string.Empty;
                                                                return s;
                                                            }

    private void PopulateSiteDropdown()
                                                            {
                                                                string connStr = GetConnectionString();
                                                                var allowedIds = UserManager.GetAllowedCompanyIds(Session, connStr);

                                                                DdlSiteFilter.Items.Clear();

                                                                string baseSql = "SELECT id, name FROM dbo.company WHERE id IN (SELECT DISTINCT companyid FROM dbo.v_asset WHERE lastinventoried IS NOT NULL AND lastinventoried >= '2020-01-01' AND lastmodifiedby IS NOT NULL)";

                                                                using (var conn = new SqlConnection(connStr))
                                                                {
                                                                    conn.Open();
                                                                    SqlCommand cmd;

                                                                    if (allowedIds == null)
                                                                    {
                                                                        // Admin / wildcard - show all
                                                                        cmd = new SqlCommand(baseSql + " ORDER BY name", conn);
                                                                        DdlSiteFilter.Items.Add(new System.Web.UI.WebControls.ListItem("All Sites", "0"));
                                                                    }
                                                                    else if (allowedIds.Count == 0)
                                                                    {
                                                                        DdlSiteFilter.Items.Add(new System.Web.UI.WebControls.ListItem("-- No sites assigned --", "0"));
                                                                        return;
                                                                    }
                                                                    else
                                                                    {
                                                                        var parms = new List<string>();
                                                                        cmd = new SqlCommand();
                                                                        cmd.Connection = conn;
                                                                        for (int i = 0; i < allowedIds.Count; i++) { parms.Add("@id" + i); cmd.Parameters.AddWithValue("@id" + i, allowedIds[i]); }
                                                                        cmd.CommandText = baseSql + " AND id IN (" + string.Join(",", parms) + ") ORDER BY name";
                                                                        // Only add "All Sites" if user has multiple sites
                                                                        if (allowedIds.Count > 1)
                                                                            DdlSiteFilter.Items.Add(new System.Web.UI.WebControls.ListItem("All My Sites", "0"));
                                                                    }

                                                                    using (var rdr = cmd.ExecuteReader())
                                                                        while (rdr.Read())
                                                                            DdlSiteFilter.Items.Add(new System.Web.UI.WebControls.ListItem(rdr["name"].ToString(), rdr["id"].ToString()));

                                                                    // Auto-select if exactly one site
                                                                    if (DdlSiteFilter.Items.Count == 1)
                                                                        DdlSiteFilter.SelectedIndex = 0;
                                                                }
                                                            }

    private void PopulateUserDropdown()
                                                            {
        DataTable dt = GetSqlData();
                                                                var users = dt.AsEnumerable()
                                                                    .Select(r => Convert.ToString(r["lastmodifiedby"]))
                                                                    .Where(u => !string.IsNullOrWhiteSpace(u))
                                                                    .Distinct(StringComparer.OrdinalIgnoreCase)
                                                                    .OrderBy(u => u);

                                                                DdlUserFilter.Items.Clear();
                                                                DdlUserFilter.Items.Add(new System.Web.UI.WebControls.ListItem("All Users", ""));

                                                                foreach(string user in users)
                                                                {
                                                                    DdlUserFilter.Items.Add(new System.Web.UI.WebControls.ListItem(user, user));
                                                                }
                                                            }

    protected void DdlSiteFilter_SelectedIndexChanged(object sender, EventArgs e)
                                                            {
                                                                PopulateUserDropdown();
                                                                LoadSessions();
                                                                HideAllActionPanels();
                                                            }

    protected void DdlUserFilter_SelectedIndexChanged(object sender, EventArgs e)
                                                            {
                                                                LoadSessions();
                                                                HideAllActionPanels();
                                                            }

    private string GetConnectionString()
                                                            {
                                                                return ConfigurationManager.ConnectionStrings["Assetworx"].ConnectionString;
                                                            }

                                                            protected void DateFilter_Changed(object sender, EventArgs e)
                                                            {
                                                                LoadSessions();
                                                                HideAllActionPanels();
                                                            }

                                                                private DataTable GetSqlData()
                                                            {
                                                                string connStr = GetConnectionString();
                                                                string siteFilterVal = (DdlSiteFilter != null && DdlSiteFilter.SelectedValue != "0") ? DdlSiteFilter.SelectedValue : null;

                                                                 string sql = @"
                                                                 SELECT
                                                                     a.name AS[Name],
                                                                     ISNULL(c.name, 'Unknown Site') AS [SiteName],
                                                                     a.companyid,
                                                                     ISNULL(l.name, a.locationname) AS locationname,
                                                                     a.text6 AS [Previous_Location],
                                                                     ISNULL(NULLIF(a.text16, ''), ISNULL(lh.HistoryLocationName, a.text6)) AS [Scanned_Location],
                                                                     CASE WHEN CHARINDEX(' ', a.name) > 0 THEN SUBSTRING(a.name, CHARINDEX(' ', a.name) + 1, LEN(a.name)) ELSE a.name END AS [EIL],
                                                                     a.text8 AS [CMR],
                                                                     a.description AS[Description],
                                                                     a.text7 AS[Station_Number],
                                                                     a.text14 AS[Sub_Station],
                                                                     a.text19 AS[Tag_Type],
                                                                     a.text13 AS[Empl_ID],
                                                                     a.text10 AS[Previous_Inventory_Date],
                                                                     a.text17 AS[Tag_Date],
                                                                     ISNULL(NULLIF(a.text16, ''), ISNULL(lh.HistoryLocationName, '')) AS [LocationTagged],
                                                                     a.rfidtag AS[RFID_Tag],
                                                                     a.listvalue1 AS[DisposalStatus],
                                                                     a.text20 AS[Notes],
                                                                     a.lastmodifiedby,
                                                                     a.lastinventoried,
                                                                     ISNULL(lh.HistoryLocationName, '') AS [HistoryLocation]
                                                                 FROM dbo.v_asset a
                                                                 LEFT JOIN dbo.location l ON l.id = a.locationid
                                                                 LEFT JOIN dbo.company c ON c.id = a.companyid
                                                                 OUTER APPLY (
                                                                     SELECT TOP 1 hloc.name AS HistoryLocationName
                                                                     FROM dbo.locationhistory lh WITH (NOLOCK)
                                                                     INNER JOIN dbo.location hloc WITH (NOLOCK) ON lh.locationid = hloc.id
                                                                     WHERE lh.assetid = a.id
                                                                       AND ABS(DATEDIFF(second, lh.timeseen, a.lastinventoried)) <= 60
                                                                     ORDER BY ABS(DATEDIFF(second, lh.timeseen, a.lastinventoried)) ASC
                                                                 ) lh
                                                                 WHERE a.lastinventoried IS NOT NULL
                                                                   AND a.lastinventoried >= '2020-01-01'";

                                                                if (siteFilterVal != null)
                                                                    sql += " AND a.companyid = @SiteId";
                                                                else
                                                                {
                                                                    // No explicit site filter selected — still enforce allowed sites
                                                                    var enforcedIds = UserManager.GetAllowedCompanyIds(Session, connStr);
                                                                    if (enforcedIds != null && enforcedIds.Count > 0)
                                                                    {
                                                                        var inParms = new List<string>();
                                                                        for (int i = 0; i < enforcedIds.Count; i++)
                                                                            inParms.Add(enforcedIds[i].ToString());
                                                                        sql += " AND a.companyid IN (" + string.Join(",", inParms) + ")";
                                                                    }
                                                                }
                                                                if (TxtFrom != null && !string.IsNullOrEmpty(TxtFrom.Text)) sql += " AND a.lastinventoried >= @FromDate";
                                                                if (TxtTo   != null && !string.IsNullOrEmpty(TxtTo.Text))   sql += " AND a.lastinventoried <= @ToDate";

                                                                using(var conn = new SqlConnection(connStr))
                                                                using (var cmd = new SqlCommand(sql, conn))
                                                                {
                                                                    if (siteFilterVal != null) { int sid; if (int.TryParse(siteFilterVal, out sid)) cmd.Parameters.AddWithValue("@SiteId", sid); }
                                                                    if (TxtFrom != null && !string.IsNullOrEmpty(TxtFrom.Text)) { DateTime fd; if (DateTime.TryParse(TxtFrom.Text, out fd)) cmd.Parameters.AddWithValue("@FromDate", fd); }
                                                                    if (TxtTo   != null && !string.IsNullOrEmpty(TxtTo.Text))   { DateTime td; if (DateTime.TryParse(TxtTo.Text,   out td)) cmd.Parameters.AddWithValue("@ToDate",   td.AddDays(1).AddSeconds(-1)); }

                                                                    cmd.CommandText = sql;
                                                                    var da = new SqlDataAdapter(cmd);
                                                                    var dt = new DataTable();
                                                                    da.Fill(dt);
                                                                    return dt;
                                                                }
                                                            }

    protected void ChkHideEmptyUsers_CheckedChanged(object sender, EventArgs e)
                                                            {
                                                                LoadSessions();
                                                                HideAllActionPanels();
                                                            }

    private void HideAllActionPanels()
                                                            {
                                                                GridPreview.Visible = false;
                                                                TxtPreview.Visible = false;
                                                                GridTagged.Visible = false;
                                                                BtnExportTagged.Visible = false;
                                                                LitHeader.Text = "";
                                                                LblMessage.Text = "";
                                                            }

    private void LoadSessions()
                                                            {
                                                                GridSessions.Visible = true;
        DataTable dt = GetSqlData();
                                                                var summary = new DataTable();
                                                                summary.Columns.Add("Site");
                                                                summary.Columns.Add("User");
                                                                summary.Columns.Add("Date");
                                                                summary.Columns.Add("Count", typeof (int));

                                                                var rows = dt.AsEnumerable();

                                                                if (ChkHideEmptyUsers.Checked)
                                                                    rows = rows.Where(r => !r.IsNull("lastmodifiedby") &&
                                                                        !string.IsNullOrWhiteSpace(Convert.ToString(r["lastmodifiedby"])));

        string selectedUser = DdlUserFilter.SelectedValue;
                                                                if (!string.IsNullOrEmpty(selectedUser)) {
                                                                    rows = rows.Where(r =>
                                                                        Convert.ToString(r["lastmodifiedby"])
                                                                            .Trim()
                                                                            .Equals(selectedUser, StringComparison.OrdinalIgnoreCase)
                                                                    );
                                                                }

                                                                var groups = rows.GroupBy(r => new {
                                                                    Site = Convert.ToString(r["SiteName"]).Trim(),
                                                                    User = Convert.ToString(r["lastmodifiedby"]).Trim(),
                                                                    Date = (r["lastinventoried"] is DateTimeOffset)
                                                                    ? ((DateTimeOffset)r["lastinventoried"]).UtcDateTime.Date
                                                                    : Convert.ToDateTime(r["lastinventoried"]).Date
                                                            }).OrderByDescending(g => g.Key.Date).ThenBy(g => g.Key.Site).ThenBy(g => g.Key.User);

                                                            foreach(var g in groups)
                                                            summary.Rows.Add(g.Key.Site, g.Key.User, g.Key.Date.ToString("yyyy-MM-dd"), g.Count());

                                                            GridSessions.DataSource = summary;
                                                            GridSessions.DataBind();
                                                            if (GridSessions.HeaderRow != null)
                                                                GridSessions.HeaderRow.TableSection = TableRowSection.TableHeader;
    }

    protected void GridSessions_RowCommand(object sender, GridViewCommandEventArgs e)
                                                            {
                                                                HideAllActionPanels();
        int index = Convert.ToInt32(e.CommandArgument);
        GridViewRow row = GridSessions.Rows[index];

        Button btnHide = row.FindControl("BtnHidePreviewItem") as Button;

                                                                if (e.CommandName == "Preview") {
            string site = row.Cells[0].Text;
            string user = row.Cells[1].Text;
            DateTime date = DateTime.Parse(row.Cells[2].Text);
                                                                    LoadPreview(site, user, date);
                                                                    if (btnHide != null) btnHide.Visible = true;
                                                                }
                                                                else if (e.CommandName == "HidePreview") {
                                                                    HideAllActionPanels();
                                                                    if (btnHide != null) btnHide.Visible = false;
                                                                }
                                                            }

    private void LoadPreview(string site, string user, DateTime date)
                                                            {
        DataTable dt = GetSqlData();
                                                                var filteredRows = dt.AsEnumerable().Where(r => {
            string rowSite = Convert.ToString(r["SiteName"]).Trim();
            string usr = Convert.ToString(r["lastmodifiedby"]);
            DateTime rowDate = (r["lastinventoried"] is DateTimeOffset)
                                                                    ? ((DateTimeOffset)r["lastinventoried"]).UtcDateTime.Date
                : Convert.ToDateTime(r["lastinventoried"]).Date;
                                                                return rowSite.Equals(site, StringComparison.OrdinalIgnoreCase) &&
                                                                       usr.Equals(user, StringComparison.OrdinalIgnoreCase) &&
                                                                       rowDate == date.Date;
                                                            });

        DataTable filtered = filteredRows.Any() ? filteredRows.CopyToDataTable() : dt.Clone();

        if (!filtered.Columns.Contains("ResolvedLocation"))
            filtered.Columns.Add("ResolvedLocation", typeof(string));

        foreach (DataRow r in filtered.Rows)
        {
            string locTagged = Convert.ToString(r["LocationTagged"]).Trim();
            string histLoc = filtered.Columns.Contains("HistoryLocation") ? Convert.ToString(r["HistoryLocation"]).Trim() : "";
            string prevLoc = Convert.ToString(r["Previous_Location"]).Trim();
            string sqlLoc = Convert.ToString(r["locationname"]).Trim();

            string res;
            if (!string.IsNullOrWhiteSpace(locTagged))
                res = locTagged;
            else if (!string.IsNullOrWhiteSpace(histLoc))
                res = histLoc;
            else if (!string.IsNullOrWhiteSpace(prevLoc))
                res = prevLoc;
            else if (!string.IsNullOrWhiteSpace(sqlLoc))
                res = sqlLoc;
            else
                res = "MISSING";

            r["ResolvedLocation"] = res;
        }

        GridPreview.DataSource = filtered;
        GridPreview.DataBind();
        if (GridPreview.HeaderRow != null)
            GridPreview.HeaderRow.TableSection = TableRowSection.TableHeader;

        // Classic ENNX text format: Location + Name only (MATCHES ennx_batch)
        StringBuilder sb = new StringBuilder();

        // Sort by final ResolvedLocation and Name so locations are grouped into ONE clean header block!
        DataView v = filtered.DefaultView;
        v.Sort = "ResolvedLocation ASC, Name ASC";
        DataTable sorted = v.ToTable();

        int lineCount = 0;

        sb.AppendLine("ENNX"); lineCount++;
        sb.AppendLine("ID"); lineCount++;

        string curLoc = null;

        foreach(DataRow r in sorted.Rows)
        {
            string resolvedLoc = Convert.ToString(r["ResolvedLocation"]).Trim();
            if (string.IsNullOrWhiteSpace(resolvedLoc)) resolvedLoc = "MISSING";

            // Emit location header ONLY when it truly changes
            if (curLoc == null || !resolvedLoc.Equals(curLoc, StringComparison.OrdinalIgnoreCase)) {
                sb.AppendLine(resolvedLoc);
                lineCount++;
                curLoc = resolvedLoc;
            }

            // Asset name (NULL-prefixed names are allowed, empty names are not)
            string name = Convert.ToString(r["Name"]).Trim();
            if (!string.IsNullOrWhiteSpace(name)) {
                sb.AppendLine(name);
                lineCount++;
            }
        }

// ---- FINAL END COUNT (MATCHES ENNX EXACTLY) ----

// Remove trailing newline so we do not count a phantom line
string body = sb.ToString().TrimEnd('\r', '\n');

// Count lines exactly as ENNX will see them
int finalLineCount = body.Split(new [] { "\r\n", "\n" }, StringSplitOptions.None).Length;

                                                            // Rebuild output with correct END
                                                            sb.Clear();
                                                            sb.AppendLine(body);
                                                            // ENNX spec: END count excludes the ENNX header line
                                                            sb.AppendLine("***END***^" + (finalLineCount - 1));


                                                            TxtPreview.Text = sb.ToString();

                                                            LitHeader.Text = string.Format(
                                                                "<h3>{0} &mdash; {1} &mdash; {2:yyyy-MM-dd} ({3} assets)</h3>",
                                                                site, user, date, sorted.Rows.Count);

                                                            GridPreview.Visible = true;
                                                            TxtPreview.Visible = true;

}

    // ============================================================
    // TOTAL TAGGED CODE MERGED
    // ============================================================

    protected void BtnTotalTagged_Click(object sender, EventArgs e)
    {
        HideAllActionPanels();
        
        string userFilter = DdlUserFilter.SelectedValue;
        string sql = @"
            SELECT 
                ISNULL(NULLIF(a.text7, ''), 'UNKNOWN SITE') AS [Site (Station Number)],
                COUNT(*) AS [Total Tagged]
            FROM dbo.v_asset a WITH(NOLOCK)
            WHERE a.text18 = '1'";
            
        if (!string.IsNullOrEmpty(userFilter))
        {
            sql += " AND a.lastmodifiedby = @user";
        }
        
        sql += " GROUP BY ISNULL(NULLIF(a.text7, ''), 'UNKNOWN SITE') ORDER BY [Site (Station Number)] ASC";

        DataTable dt = new DataTable();
        string connStr = GetConnectionString();
        int grandTotal = 0;
        
        using (SqlConnection cn = new SqlConnection(connStr))
        using (SqlCommand cmd = new SqlCommand(sql, cn))
        {
            if (!string.IsNullOrEmpty(userFilter))
            {
                cmd.Parameters.AddWithValue("@user", userFilter.Trim());
            }
            using (SqlDataAdapter da = new SqlDataAdapter(cmd))
            {
                da.Fill(dt);
            }
        }
        
        foreach (DataRow row in dt.Rows)
        {
            grandTotal += Convert.ToInt32(row["Total Tagged"]);
        }

        GridTagged.DataSource = dt;
        GridTagged.DataBind();
        if (GridTagged.HeaderRow != null) GridTagged.HeaderRow.TableSection = TableRowSection.TableHeader;
        
        GridTagged.Visible = true;
        BtnExportTagged.Visible = true;
        GridSessions.Visible = true; // KEEP history grid visible
        
        string displayUser = string.IsNullOrEmpty(userFilter) ? "All Users" : userFilter;
        LitHeader.Text = string.Format("<div style='margin-bottom:10px;font-size:16px;font-weight:bold;color:var(--accent);'>Total Tagged Assets: {0:N0} &mdash; filter: <i>{1}</i></div>", grandTotal, displayUser);
    }

    protected void BtnExportTagged_Click(object sender, EventArgs e)
    {
        string userFilter = DdlUserFilter.SelectedValue;
        string sql = @"
            SELECT
                a.name AS [Name],
                CASE WHEN CHARINDEX(' ', a.name) > 0 THEN SUBSTRING(a.name, CHARINDEX(' ', a.name) + 1, LEN(a.name)) ELSE a.name END AS [EIL],
                a.description AS [Description],
                a.text2 AS [Model],
                a.text3 AS [Serial_Number],
                a.text19 AS [Tag_Type],
                a.text13 AS [Empl_ID],
                ISNULL(l.name, a.locationname) AS [locationname],
                a.text16 AS [LocationTagged],
                a.text17 AS [Tag_Date],
                a.listvalue1 AS [DisposalStatus],
                a.lastinventoried AS [LastInventoried],
                a.text20 AS [Notes],
                ISNULL(a.lastmodifiedby, 'UNKNOWN') AS [User_ID]
            FROM dbo.v_asset a WITH(NOLOCK)
            LEFT JOIN dbo.location l ON l.id = a.locationid
            WHERE a.text18 = '1'";

        if (!string.IsNullOrEmpty(userFilter))
        {
            sql += " AND a.lastmodifiedby = @user";
        }
        
        sql += " ORDER BY a.lastmodifiedby ASC, a.text17 DESC, a.name ASC";

        DataTable dt = new DataTable();
        string connStr = GetConnectionString();
        using (SqlConnection cn = new SqlConnection(connStr))
        using (SqlCommand cmd = new SqlCommand(sql, cn))
        {
            if (!string.IsNullOrEmpty(userFilter))
                cmd.Parameters.AddWithValue("@user", userFilter.Trim());
            using (SqlDataAdapter da = new SqlDataAdapter(cmd))
            {
                da.Fill(dt);
            }
        }

        if (dt.Rows.Count == 0) return;

        var sb = new StringBuilder();
        
        int cols = dt.Columns.Count;
        string[] h = new string[cols];
        for(int i = 0; i < cols; i++) 
            h[i] = "\"" + dt.Columns[i].ColumnName.Replace("\"", "\"\"").Trim() + "\"";
        sb.AppendLine(string.Join(",", h));

        foreach(DataRow row in dt.Rows)
        {
            string[] vals = new string[cols];
            for (int i = 0; i < cols; i++)
            {
                string text = Convert.ToString(row[i]).Replace("&nbsp;", "").Trim();
                text = text.Replace("\"", "\"\"");
                vals[i] = "\"=\"\"" + text + "\"\"\"";
            }
            sb.AppendLine(string.Join(",", vals));
        }

        byte[] csvBytes = Encoding.UTF8.GetBytes(sb.ToString());
        string timestamp = DateTime.Now.ToString("MM-dd-yy h.mmtt");
        HttpResponse response = HttpContext.Current.Response;
        response.Clear();
        response.ClearHeaders();
        response.ClearContent();
        response.Buffer = false;
        response.ContentType = "text/csv";
        response.AddHeader("Content-Disposition", string.Format("attachment; filename=Total_Tagged_{0}.csv", timestamp));
        response.AddHeader("Content-Length", csvBytes.Length.ToString());
        response.OutputStream.Write(csvBytes, 0, csvBytes.Length);
        response.Flush();
        HttpContext.Current.ApplicationInstance.CompleteRequest();
    }


    // ============================================================
    // DOWNLOAD HANDLERS
    // ============================================================

    protected void BtnDownloadPreview_Click(object sender, EventArgs e)
                                                            {
                                                                if (string.IsNullOrEmpty(TxtPreview.Text)) {
                                                                    LblMessage.Text = "Please preview a session first before downloading.";
                                                                    return;
                                                                }

                                                                byte[] data = Encoding.UTF8.GetBytes(TxtPreview.Text);
        string timestamp = DateTime.Now.ToString("MM-dd-yy h.mmtt");

        HttpResponse response = HttpContext.Current.Response;

                                                                response.Clear();
                                                                response.ClearHeaders();
                                                                response.ClearContent();
                                                                response.Buffer = false;
                                                                response.ContentType = "text/plain";

                                                                response.AddHeader("Content-Disposition",
                                                                    string.Format("attachment; filename=ENNX Preview {0}.txt", timestamp));

                                                                response.AddHeader("Content-Length", data.Length.ToString());
                                                                response.OutputStream.Write(data, 0, data.Length);
                                                                response.Flush();

                                                                HttpContext.Current.ApplicationInstance.CompleteRequest();
                                                            }

protected void BtnExportCsv_Click(object sender, EventArgs e)
                                                            {
                                                                if (GridPreview.Rows.Count == 0) {
                                                                    LblMessage.Text = "Please preview a session first before exporting.";
                                                                    return;
                                                                }

                                                                var sb = new StringBuilder();

                                                                // CSV HEADER â€&rdquo; must match the 14-column order
                                                                sb.AppendLine("Name,EIL,Description,Station_Number,Sub_Station,Tag_Type,Empl_ID,Previous_Inventory_Date,Tag_Date,Previous_Location,LocationTagged,DisposalStatus,Notes,Last_Modified_By");


                                                                // EXPORT ROWS
                                                                foreach(GridViewRow row in GridPreview.Rows)
                                                                {
                                                                    string[] vals = new string[14];

                                                                    for (int i = 0; i < 14; i++)
                                                                    {
            string text = row.Cells[i].Text;

                                                                        // remove html non-breaking spaces
                                                                        text = text.Replace("&nbsp;", "").Trim();

                                                                        // escape quotes for csv
                                                                        text = text.Replace("\"", "\"\"");

                                                                        // enforce Excel text format to prevent auto-numbering
                                                                        vals[i] = "\"=\"\"" + text + "\"\"\"";
                                                                    }

                                                                    sb.AppendLine(string.Join(",", vals));
                                                                }

                                                                // Convert to bytes
                                                                byte[] csvBytes = Encoding.UTF8.GetBytes(sb.ToString());

    // Safe timestamp for a filename
    string timestamp = DateTime.Now.ToString("MM-dd-yy h.mmtt");

    HttpResponse response = HttpContext.Current.Response;
                                                                response.Clear();
                                                                response.ClearHeaders();
                                                                response.ClearContent();
                                                                response.Buffer = false;
                                                                response.ContentType = "text/csv";

                                                                response.AddHeader(
                                                                    "Content-Disposition",
                                                                    string.Format("attachment; filename=ENNX Export {0}.csv", timestamp)
                                                                );

                                                                response.AddHeader("Content-Length", csvBytes.Length.ToString());
                                                                response.OutputStream.Write(csvBytes, 0, csvBytes.Length);
                                                                response.Flush();

                                                                HttpContext.Current.ApplicationInstance.CompleteRequest();
                                                            }

    // ============================================================
    // RECIPIENT MANAGEMENT (web.config version)
    // ============================================================

    // ============================================================
    // RECIPIENT MANAGEMENT (Delegated to EmailHelper)
    // ============================================================

    // Recipient management centralized to index.aspx &mdash; handlers removed.

    // ============================================================
    // EMAIL BUTTONS (Read from web.config list)
    // ============================================================

    protected void BtnEmailPreview_Click(object sender, EventArgs e)
                                                            {
                                                                if (string.IsNullOrEmpty(TxtPreview.Text)) {
                                                                    LblMessage.Text = "Please preview a session first before emailing.";
                                                                    return;
                                                                }

                                                                var recipients = EmailHelper.GetRecipients();
                                                                if (recipients.Count == 0) {
                                                                    LblMessage.Text = "No recipients configured. Please manage recipients first.";
                                                                    return;
                                                                }

                                                                try {
            string body = TxtPreview.Text;
            string subject = "ENNX Upload + Excel";

            // Wrap in pre tag for proper formatting since EmailHelper sends HTML
            string htmlBody = "<pre style='font-family:Consolas,monospace; font-size:12px;'>" + Server.HtmlEncode(body) + "</pre>";

                                                                    EmailHelper.SendEmail(subject, htmlBody, null);

                                                                    LblMessage.Text = string.Format("ENNX preview emailed successfully to: <b>{0}</b>.", string.Join("; ", recipients));
                                                                }
                                                                catch (Exception ex)
                                                                {
                                                                    LblMessage.Text = "Error sending email: " + ex.Message;
                                                                }
                                                            }

    protected void BtnEmailBatch_Click(object sender, EventArgs e)
    {
        var recipients = EmailHelper.GetRecipients();
        if (recipients.Count == 0) {
            LblMessage.Text = "No recipients configured. Please manage recipients first.";
            return;
        }

        List<Attachment> atts = new List<Attachment>();
        string connStr = GetConnectionString();
        
        if (GridTagged.Visible)
        {
            string userFilter = DdlUserFilter.SelectedValue;
            string sql = @"
                SELECT
                    a.name AS [Name],
                    CASE WHEN CHARINDEX(' ', a.name) > 0 THEN SUBSTRING(a.name, CHARINDEX(' ', a.name) + 1, LEN(a.name)) ELSE a.name END AS [EIL],
                    a.description AS [Description],
                    a.text2 AS [Model],
                    a.text3 AS [Serial_Number],
                    a.text19 AS [Tag_Type],
                    a.text13 AS [Empl_ID],
                    ISNULL(l.name, a.locationname) AS [locationname],
                    a.text16 AS [LocationTagged],
                    a.text17 AS [Tag_Date],
                    a.listvalue1 AS [DisposalStatus],
                    a.lastinventoried AS [LastInventoried],
                    a.text20 AS [Notes],
                    ISNULL(a.lastmodifiedby, 'UNKNOWN') AS [User_ID],
                    a.text6 as [Previous_Location]
                FROM dbo.v_asset a WITH(NOLOCK)
                LEFT JOIN dbo.location l ON l.id = a.locationid
                WHERE a.text18 = '1'";

            if (!string.IsNullOrEmpty(userFilter))
                sql += " AND a.lastmodifiedby = @user";

            DataTable dt = new DataTable();
            using (SqlConnection cn = new SqlConnection(connStr))
            using (SqlCommand cmd = new SqlCommand(sql, cn))
            {
                if (!string.IsNullOrEmpty(userFilter))
                    cmd.Parameters.AddWithValue("@user", userFilter.Trim());
                using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    da.Fill(dt);
            }
            
            if (dt.Rows.Count == 0) {
                LblMessage.Text = "No tagged assets matched for batch generation.";
                return;
            }

            var users = dt.AsEnumerable().Select(r => Convert.ToString(r["User_ID"]).Trim()).Distinct();
            foreach (string u in users)
            {
                var userRows = dt.AsEnumerable().Where(r => Convert.ToString(r["User_ID"]).Trim().Equals(u, StringComparison.OrdinalIgnoreCase));
                if (userRows.Any())
                {
                    DataTable userDt = userRows.CopyToDataTable();
                    string safeUser = string.Join("_", u.Split(System.IO.Path.GetInvalidFileNameChars()));
                    
                    atts.Add(CreateEnnxAttachment(userDt, string.Format("TotalTagged_ENNX_{0}.txt", safeUser)));
                    atts.Add(CreateCsvAttachment(userDt, string.Format("TotalTagged_CSV_{0}.csv", safeUser)));
                }
            }
        }
        else
        {
            if (GridSessions.Rows.Count == 0) {
                LblMessage.Text = "No sessions listed for batch generation.";
                return;
            }

            DataTable fullDt = GetSqlData();
            foreach (GridViewRow row in GridSessions.Rows)
            {
                string u = row.Cells[0].Text.Replace("&nbsp;", "").Trim();
                string d = row.Cells[1].Text.Replace("&nbsp;", "").Trim();
                DateTime date;
                if (!DateTime.TryParse(d, out date)) continue;

                var userRows = fullDt.AsEnumerable().Where(r => {
                    string usr = Convert.ToString(r["lastmodifiedby"]).Trim();
                    DateTime rowDate = (r["lastinventoried"] is DateTimeOffset)
                        ? ((DateTimeOffset)r["lastinventoried"]).UtcDateTime.Date
                        : Convert.ToDateTime(r["lastinventoried"]).Date;
                    return usr.Equals(u, StringComparison.OrdinalIgnoreCase) && rowDate == date.Date;
                });

                if (userRows.Any())
                {
                    DataTable userDt = userRows.CopyToDataTable();
                    string safeUser = string.Join("_", u.Split(System.IO.Path.GetInvalidFileNameChars()));
                    string safeDate = date.ToString("yyyy-MM-dd");

                    atts.Add(CreateEnnxAttachment(userDt, string.Format("Session_ENNX_{0}_{1}.txt", safeUser, safeDate)));
                    atts.Add(CreateCsvAttachment(userDt, string.Format("Session_CSV_{0}_{1}.csv", safeUser, safeDate)));
                }
            }
        }

        if (atts.Count == 0) {
            LblMessage.Text = "No valid data to attach.";
            return;
        }

        try
        {
            EmailHelper.SendEmail("Batch ENNX and CSV Export", "Attached are the individual batch exports mapping to your current dashboard view.", atts);
            LblMessage.Text = string.Format("Batch successfully emailed ({0} attachments) to: <b>{1}</b>.", atts.Count, string.Join("; ", recipients));
        }
        catch (Exception ex)
        {
            LblMessage.Text = "Error sending batch email: " + ex.Message;
        }
    }

    private Attachment CreateEnnxAttachment(DataTable dt, string filename)
    {
        StringBuilder sb = new StringBuilder();
        if (dt.Columns.Contains("LocationTagged") && dt.Columns.Contains("Previous_Location") && dt.Columns.Contains("locationname") && dt.Columns.Contains("Name"))
        {
            DataView v = dt.DefaultView;
            v.Sort = "LocationTagged ASC, Previous_Location ASC, locationname ASC, Name ASC";
            dt = v.ToTable();
        }

        sb.AppendLine("ENNX");
        sb.AppendLine("ID");

        string curLoc = null;
        int lineCount = 0;
        foreach (DataRow r in dt.Rows)
        {
            string resolvedLoc;
            string locTagged = dt.Columns.Contains("LocationTagged") ? Convert.ToString(r["LocationTagged"]).Trim() : "";
            string prevLoc = dt.Columns.Contains("Previous_Location") ? Convert.ToString(r["Previous_Location"]).Trim() : "";
            string sqlLoc = dt.Columns.Contains("locationname") ? Convert.ToString(r["locationname"]).Trim() : "";

            if (!string.IsNullOrWhiteSpace(locTagged)) resolvedLoc = locTagged;
            else if (!string.IsNullOrWhiteSpace(prevLoc)) resolvedLoc = prevLoc;
            else if (!string.IsNullOrWhiteSpace(sqlLoc)) resolvedLoc = sqlLoc;
            else resolvedLoc = "MISSING";

            if (curLoc == null || !resolvedLoc.Equals(curLoc, StringComparison.OrdinalIgnoreCase)) {
                sb.AppendLine(resolvedLoc);
                curLoc = resolvedLoc;
                lineCount++;
            }

            string name = dt.Columns.Contains("Name") ? Convert.ToString(r["Name"]).Trim() : "";
            if (!string.IsNullOrWhiteSpace(name)) {
                sb.AppendLine(name);
                lineCount++;
            }
        }

        string body = sb.ToString().TrimEnd('\r', '\n');
        int finalLineCount = body.Split(new [] { "\r\n", "\n" }, StringSplitOptions.None).Length;
        sb.Clear();
        sb.AppendLine(body);
        sb.AppendLine("***END***^" + (finalLineCount - 1));

        var ms = new MemoryStream(Encoding.UTF8.GetBytes(sb.ToString()));
        var att = new Attachment(ms, filename, "text/plain");
        return att;
    }

    private Attachment CreateCsvAttachment(DataTable dt, string filename)
    {
        var sb = new StringBuilder();
        int cols = dt.Columns.Count;
        string[] h = new string[cols];
        for(int i = 0; i < cols; i++) h[i] = "\"" + dt.Columns[i].ColumnName.Replace("\"", "\"\"").Trim() + "\"";
        sb.AppendLine(string.Join(",", h));

        foreach (DataRow row in dt.Rows)
        {
            string[] vals = new string[cols];
            for (int i = 0; i < cols; i++)
            {
                string text = Convert.ToString(row[i]).Replace("&nbsp;", "").Trim();
                text = text.Replace("\"", "\"\"");
                vals[i] = "\"=\"\"" + text + "\"\"\"";
            }
            sb.AppendLine(string.Join(",", vals));
        }

        var ms = new MemoryStream(Encoding.UTF8.GetBytes(sb.ToString()));
        return new Attachment(ms, filename, "text/csv");
    }

    protected void BtnEmailCsvUpload_Click(object sender, EventArgs e)
    {
                                                                if (GridPreview.Rows.Count == 0 || string.IsNullOrEmpty(TxtPreview.Text)) {
                                                                    LblMessage.Text = "Please preview a session first before emailing.";
                                                                    return;
                                                                }

                                                                var recipients = EmailHelper.GetRecipients();
                                                                if (recipients.Count == 0) {
                                                                    LblMessage.Text = "No recipients configured. Please manage recipients first.";
                                                                    return;
                                                                }

                                                                try {
                                                                    List < Attachment > atts = new List < Attachment > ();

                                                                    // 1. CSV Attachment
                                                                    var csvBuilder = new StringBuilder();
                                                                    csvBuilder.AppendLine("Name,EIL,Description,Station_Number,Sub_Station,Tag_Type,Empl_ID,Previous_Inventory_Date,Tag_Date,Previous_Location,LocationTagged,DisposalStatus,Notes,Last_Modified_By");

                                                                    foreach(GridViewRow row in GridPreview.Rows)
                                                                    {
                                                                        string[] vals = new string[14];
                                                                        for (int i = 0; i < 14; i++)
                                                                        {
                    string text = row.Cells[i].Text.Replace("&nbsp;", "").Trim();
                                                                            text = text.Replace("\"", "\"\"");
                                                                            vals[i] = "\"=\"\"" + text + "\"\"\"";
                                                                        }
                                                                        csvBuilder.AppendLine(string.Join(",", vals));
                                                                    }

                                                                    atts.Add(new Attachment(
                                                                        new MemoryStream(Encoding.UTF8.GetBytes(csvBuilder.ToString())),
                                                                        "ENNX_Export.csv",
                                                                        "text/csv"
                                                                    ));

            // 2. Text Preview Attachment
            string previewTextContent = TxtPreview.Text;
                                                                    if (!string.IsNullOrEmpty(previewTextContent)) {
                                                                        atts.Add(new Attachment(
                                                                            new MemoryStream(Encoding.UTF8.GetBytes(previewTextContent)),
                                                                            "ENNX_Preview.txt",
                                                                            "text/plain"
                                                                        ));
                                                                    }

            string subject = "ENNX CSV + Upload";
            string body = "Attached are your ENNX CSV export and the text preview file.";

                                                                    EmailHelper.SendEmail(subject, body, atts);

                                                                    LblMessage.Text = string.Format("ENNX CSV and Text Preview files emailed successfully to: <b>{0}</b>.", string.Join("; ", recipients));
                                                                }
                                                                catch (Exception ex)
                                                                {
                                                                    LblMessage.Text = "Error sending email: " + ex.Message;
                                                                }
                                                            }

                                                        </script>

                                                        <script>
                                                            document.addEventListener("DOMContentLoaded", function () {
                                                                var form = document.getElementById("form1");
                                                                if (form) {
                                                                    form.addEventListener("click", function (e) {
                                                                        if (e.target && e.target.id && e.target.id.indexOf("BtnHidePreviewItem") >= 0) {
                                                                            window.scrollTo({ top: 0, behavior: "smooth" });
                                                                        }
                                                                    });
                                                                }

                                                                const grids = document.querySelectorAll('.grid');
                                                                grids.forEach((table, gridIndex) => {
                                                                    if (table.id && table.id.indexOf("GridRecipients") >= 0) return;
                                                                    // Skip tables already handled by the sortable-grid script above
                                                                    if (table.classList.contains('sortable-grid')) return;
                                                                    if (table.rows.length <= 1) return;

                                                                    let thead = table.querySelector('thead');
                                                                    if (!thead) {
                                                                        thead = document.createElement('thead');
                                                                        const firstRow = table.rows[0];
                                                                        if (firstRow) {
                                                                            thead.appendChild(firstRow);
                                                                            table.insertBefore(thead, table.firstChild);
                                                                        }
                                                                    }

                                                                    let tbody = table.querySelector('tbody');
                                                                    if (!tbody) {
                                                                        tbody = document.createElement('tbody');
                                                                        while (table.rows.length > 1) { 
                                                                            tbody.appendChild(table.rows[1]);
                                                                        }
                                                                        table.appendChild(tbody);
                                                                    }

                                                                    const headers = thead.querySelectorAll('th');
                                                                    if (headers.length === 0) return;

                                                                    const filterRow = document.createElement('tr');

                                                                    headers.forEach((th, index) => {
                                                                        // Only add sort/filter if it's not the Actions column
                                                                        if (th.innerText === 'Actions') {
                                                                            const filterTh = document.createElement('th');
                                                                            filterRow.appendChild(filterTh);
                                                                            return;
                                                                        }

                                                                        th.style.cursor = 'pointer';
                                                                        th.style.userSelect = 'none';
                                                                        th.innerHTML = th.innerHTML + ' <span style="font-size:10px; margin-left:4px;">&#9650;&#9660;</span>';
                                                                        th.onclick = () => sortTable(table, index, gridIndex);

                                                                        const filterTh = document.createElement('th');
                                                                        filterTh.innerHTML = '<input type="text" class="filter-input-" data-col="' + index + '" placeholder="..." style="width:100%; box-sizing:border-box; background:var(--chip); color:#fff; border:1px solid var(--line); padding:4px 6px; border-radius:4px; font-size:12px; font-weight:normal;" onkeyup="filterTable(this)" />';
                                                                        filterRow.appendChild(filterTh);
                                                                    });

                                                                    thead.appendChild(filterRow);
                                                                });
                                                            });

                                                            let sortDir = {};
                                                            function sortTable(table, colIndex, gridIndex) {
                                                                const tbody = table.querySelector('tbody');
                                                                if (!tbody) return;

                                                                const rows = Array.from(tbody.querySelectorAll('tr'));
                                                                let dirKey = gridIndex + '-' + colIndex;
                                                                let dir = sortDir[dirKey] === 'asc' ? 'desc' : 'asc';
                                                                sortDir[dirKey] = dir;

                                                                rows.sort((a, b) => {
                                                                    let textA = a.cells[colIndex] ? a.cells[colIndex].innerText.trim() : '';
                                                                    let textB = b.cells[colIndex] ? b.cells[colIndex].innerText.trim() : '';

                                                                    let numA = parseFloat(textA.replace(/[^0-9.-]/g, ''));
                                                                    let numB = parseFloat(textB.replace(/[^0-9.-]/g, ''));

                                                                    let isNumA = !isNaN(numA) && textA.match(/\d/);
                                                                    let isNumB = !isNaN(numB) && textB.match(/\d/);

                                                                    if (isNumA && isNumB) {
                                                                        return dir === 'asc' ? numA - numB : numB - numA;
                                                                    }

                                                                    return dir === 'asc' ? textA.localeCompare(textB) : textB.localeCompare(textA);
                                                                });

                                                                tbody.innerHTML = '';
                                                                rows.forEach(r => tbody.appendChild(r));
                                                            }

                                                            function filterTable(inputElem) {
                                                                const table = inputElem.closest('table');
                                                                const tbody = table.querySelector('tbody');
                                                                if (!tbody) return;

                                                                const rows = tbody.querySelectorAll('tr');
                                                                const inputs = Array.from(table.querySelectorAll('thead input'));

                                                                for (let i = 0; i < rows.length; i++) {
                                                                    let show = true;
                                                                    for (let j = 0; j < inputs.length; j++) {
                                                                        const input = inputs[j];
                                                                        if (!input) continue;

                                                                        const val = input.value.toLowerCase();
                                                                        const colIndex = parseInt(input.getAttribute('data-col'), 10);
                                                                        
                                                                        const cellText = rows[i].cells[colIndex] ? rows[i].cells[colIndex].innerText.toLowerCase() : '';
                                                                        if (val && cellText.indexOf(val) === -1) {
                                                                            show = false;
                                                                            break;
                                                                        }
                                                                    }
                                                                    rows[i].style.display = show ? '' : 'none';
                                                                }
                                                            }
                                                        </script>

                                                    </body>

                                                    </html>


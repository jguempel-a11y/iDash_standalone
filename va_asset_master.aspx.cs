using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Configuration;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.Services;
using System.Web.Script.Services;
using System.Web.Script.Serialization;
using System.Text;
using System.IO;
using ClosedXML.Excel;

public partial class va_asset_master : System.Web.UI.Page
{
    private static string ConnStr
    {
        get
        {
            var cs = ConfigurationManager.ConnectionStrings["iDash"];
            return (cs == null) ? "" : cs.ConnectionString;
        }
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        // ── Detail Panel API endpoints ──
        string api = Request.QueryString["api"];
        if (!string.IsNullOrEmpty(api))
        {
            HandleDetailApi(api);
            return;
        }

        // Handle export requests via querystring or POST form
        if (!string.IsNullOrEmpty(Request["export"]))
        {
            HandleExport();
            return;
        }

        // Handle print job submission
        if (Request.QueryString["action"] == "print")
        {
            HandlePrintRequest();
            return;
        }

        if (!IsPostBack)
        {
            LoadCompanies();
        }

        // Always inject print config so templates are available
        InjectPrintConfig();
    }

    private void LoadCompanies()
    {
        try
        {
            UserManager.FilterCompanyDropdown(DdlCompany, Session, ConnStr);
        }
        catch { }
    }

    // ===================================================================
    // AJAX WebMethod — server-side search for DataTables
    // ===================================================================
    [WebMethod(EnableSession = true)]
    [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static string SearchAssets(int draw, int start, int length,
        string search, string site, string status, string cmr,
        string location, string days, string fixedReader, string sortCol, string sortDir,
        Dictionary<string, string> colSearch)
    {
        var json = new JavaScriptSerializer { MaxJsonLength = 50000000 };

        try
        {
            // Build WHERE clause
            var where = new List<string>();
            var pars = new List<SqlParameter>();

            // Global search (across multiple fields)
            // Supports pipe-delimited names from Watch List deep-link (e.g., "613 EE11855|512 EE10542")
            if (!string.IsNullOrWhiteSpace(search))
            {
                if (search.Contains("|"))
                {
                    // Watch List mode: exact name match for each pipe-delimited term
                    var terms = search.Split(new[] { '|' }, StringSplitOptions.RemoveEmptyEntries);
                    var nameOrs = new List<string>();
                    for (int i = 0; i < terms.Length; i++)
                    {
                        var pName = "@wn" + i;
                        nameOrs.Add("a.name = " + pName);
                        pars.Add(new SqlParameter(pName, terms[i].Trim()));
                    }
                    if (nameOrs.Count > 0)
                        where.Add("(" + string.Join(" OR ", nameOrs) + ")");
                }
                else
                {
                    where.Add(@"(a.name LIKE @q OR a.text8 LIKE @q OR a.text3 LIKE @q 
                        OR a.locationname LIKE @q OR a.description LIKE @q 
                        OR a.text1 LIKE @q OR a.text6 LIKE @q)");
                    pars.Add(new SqlParameter("@q", "%" + search.Trim() + "%"));
                }
            }

            // Site filter
            if (!string.IsNullOrEmpty(site) && site != "0")
            {
                where.Add("a.companyid = @site");
                pars.Add(new SqlParameter("@site", int.Parse(site)));
            }

            // Status filter
            if (!string.IsNullOrEmpty(status))
            {
                where.Add("a.listvalue1 = @status");
                pars.Add(new SqlParameter("@status", status));
            }

            // CMR filter
            if (!string.IsNullOrWhiteSpace(cmr))
            {
                where.Add("a.text8 LIKE @cmr");
                pars.Add(new SqlParameter("@cmr", "%" + cmr.Trim() + "%"));
            }

            // Location filter — matches current location OR last-observed location (fixed reader)
            if (!string.IsNullOrWhiteSpace(location))
            {
                where.Add("(a.locationname LIKE @loc OR a.lastobservedlocation LIKE @loc)");
                pars.Add(new SqlParameter("@loc", "%" + location.Trim() + "%"));
            }

            // Days Since filter: type 90 = show assets NOT inventoried in 90+ days
            int daysVal;
            if (!string.IsNullOrEmpty(days) && int.TryParse(days, out daysVal) && daysVal >= 0)
            {
                where.Add("DATEDIFF(DAY, a.lastinventoried, GETDATE()) >= @daysFilter");
                pars.Add(new SqlParameter("@daysFilter", daysVal));
            }

            // Fixed Reader Report filter
            if (!string.IsNullOrWhiteSpace(fixedReader))
            {
                switch (fixedReader.ToLower())
                {
                    case "today":
                        where.Add("a.lastobservedtime >= CAST(GETDATE() AS DATE)");
                        break;
                    case "week":
                        where.Add("a.lastobservedtime >= DATEADD(DAY, -7, GETDATE())");
                        break;
                    case "month":
                        where.Add("a.lastobservedtime >= DATEADD(MONTH, -1, GETDATE())");
                        break;
                    case "all":
                        where.Add("a.lastobservedtime IS NOT NULL");
                        break;
                }
            }

            // Per-column search (DataTables column filters)
            if (colSearch != null)
            {
                int paramIdx = 0;
                foreach (var kv in colSearch)
                {
                    if (string.IsNullOrWhiteSpace(kv.Value)) continue;
                    string dbCol = MapKeyToColumn(kv.Key);
                    if (dbCol == null) continue;
                    string pName = "@cs" + paramIdx;
                    where.Add(dbCol + " LIKE " + pName);
                    pars.Add(new SqlParameter(pName, "%" + kv.Value.Trim() + "%"));
                    paramIdx++;
                }
            }

            // Enforce site-level access restriction (server-side security)
            var session = HttpContext.Current.Session;
            string siteAccessFilter = UserManager.BuildSiteFilter(session, ConnStr, "a");
            if (!string.IsNullOrEmpty(siteAccessFilter))
            {
                // siteAccessFilter is " AND a.companyid IN (...)" — strip leading " AND " for where list
                where.Add(siteAccessFilter.TrimStart().Substring(4)); // removes "AND "
            }

            string whereStr = where.Count > 0 ? "WHERE " + string.Join(" AND ", where) : "";

            // Validate sort column
            string orderCol = MapKeyToColumn(sortCol) ?? "a.name";
            string orderDir = (sortDir ?? "").ToUpper() == "DESC" ? "DESC" : "ASC";

            // Count queries (totalSql also gets site restriction for correct KPI baseline)
            string countSql = "SELECT COUNT(*) FROM dbo.v_asset a WITH(NOLOCK) " + whereStr;
            string totalSql = "SELECT COUNT(*) FROM dbo.v_asset a WITH(NOLOCK)";
            if (!string.IsNullOrEmpty(siteAccessFilter))
                totalSql += " WHERE 1=1" + siteAccessFilter;

            // KPI query (run on filtered set)
            string kpiSql = @"
                SELECT 
                    COUNT(*) AS Total,
                    COUNT(DISTINCT a.locationname) AS Locations,
                    SUM(CASE WHEN a.text8 IS NOT NULL AND a.text8 <> '' THEN 1 ELSE 0 END) AS WithCmr,
                    SUM(CASE WHEN a.lastinventoried >= DATEADD(MONTH, -12, GETDATE()) THEN 1 ELSE 0 END) AS Recent,
                    SUM(CASE WHEN a.lastinventoried < DATEADD(MONTH, -12, GETDATE()) OR a.lastinventoried IS NULL THEN 1 ELSE 0 END) AS Overdue
                FROM dbo.v_asset a WITH(NOLOCK) " + whereStr;

            // Data query with pagination
            string dataSql = string.Format(@"
                SELECT 
                    a.id, a.name, a.description, a.locationname, a.text8, a.listvalue1,
                    a.text4, a.text1, a.text2, a.text3, a.text5, a.text6,
                    a.text7, a.text9, a.text11, a.lastinventoried,
                    DATEDIFF(DAY, a.lastinventoried, GETDATE()) AS daysSince,
                    a.rfidtag,
                    a.text18,
                    a.lastobservedtime, a.lastobservedlocation
                FROM dbo.v_asset a WITH(NOLOCK)
                {0}
                ORDER BY {1} {2}
                OFFSET @start ROWS FETCH NEXT @len ROWS ONLY",
                whereStr, orderCol, orderDir);

            int recordsTotal = 0;
            int recordsFiltered = 0;
            var kpis = new Dictionary<string, int>();
            var rows = new List<Dictionary<string, object>>();

            using (var cn = new SqlConnection(ConnStr))
            {
                cn.Open();

                // Total count (unfiltered)
                using (var cmd = new SqlCommand(totalSql, cn))
                {
                    recordsTotal = (int)cmd.ExecuteScalar();
                }

                // Filtered count
                using (var cmd = new SqlCommand(countSql, cn))
                {
                    AddParams(cmd, pars);
                    recordsFiltered = (int)cmd.ExecuteScalar();
                }

                // KPIs
                using (var cmd = new SqlCommand(kpiSql, cn))
                {
                    AddParams(cmd, pars);
                    using (var rdr = cmd.ExecuteReader())
                    {
                        if (rdr.Read())
                        {
                            kpis["total"] = rdr.IsDBNull(0) ? 0 : rdr.GetInt32(0);
                            kpis["locations"] = rdr.IsDBNull(1) ? 0 : rdr.GetInt32(1);
                            kpis["withCmr"] = rdr.IsDBNull(2) ? 0 : rdr.GetInt32(2);
                            kpis["recent"] = rdr.IsDBNull(3) ? 0 : rdr.GetInt32(3);
                            kpis["overdue"] = rdr.IsDBNull(4) ? 0 : rdr.GetInt32(4);
                        }
                    }
                }

                // Data page
                using (var cmd = new SqlCommand(dataSql, cn))
                {
                    AddParams(cmd, pars);
                    cmd.Parameters.AddWithValue("@start", start);
                    cmd.Parameters.AddWithValue("@len", length);

                    using (var rdr = cmd.ExecuteReader())
                    {
                        var colNames = new List<string>();
                        for (int i = 0; i < rdr.FieldCount; i++)
                            colNames.Add(rdr.GetName(i));

                        while (rdr.Read())
                        {
                            var row = new Dictionary<string, object>();
                            foreach (var col in colNames)
                            {
                                var val = rdr[col];
                                row[col] = (val == null || val == DBNull.Value) ? null : val;
                            }
                            rows.Add(row);
                        }
                    }
                }
            }

            return json.Serialize(new
            {
                draw = draw,
                recordsTotal = recordsTotal,
                recordsFiltered = recordsFiltered,
                data = rows,
                kpis = kpis
            });
        }
        catch (Exception ex)
        {
            return json.Serialize(new
            {
                draw = draw,
                recordsTotal = 0,
                recordsFiltered = 0,
                data = new object[] { },
                error = ex.Message
            });
        }
    }

    // ===================================================================
    // AJAX WebMethod — Get asset name prefix for a site
    // ===================================================================
    [WebMethod(EnableSession = true)]
    [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static string GetSitePrefix(string siteId)
    {
        var json = new JavaScriptSerializer();
        try
        {
            if (string.IsNullOrEmpty(siteId) || siteId == "0")
                return json.Serialize(new { prefix = "" });

            using (var cn = new SqlConnection(ConnStr))
            {
                cn.Open();
                // Discover the most common EE-style prefix from actual asset names for this site.
                // Asset names follow patterns like "613 EE10001", "512 EE 575293".
                // We extract the non-numeric prefix portion and find the most common one.
                using (var cmd = new SqlCommand(
                    @"SELECT TOP 1 
                        LEFT(a.name, LEN(a.name) - LEN(
                            REVERSE(LEFT(REVERSE(a.name), PATINDEX('%[^0-9]%', REVERSE(a.name) + 'X') - 1))
                        ) ) AS prefix
                      FROM dbo.asset a WITH(NOLOCK)
                      WHERE a.companyid = @siteId
                        AND a.name LIKE '% EE%'
                      GROUP BY LEFT(a.name, LEN(a.name) - LEN(
                            REVERSE(LEFT(REVERSE(a.name), PATINDEX('%[^0-9]%', REVERSE(a.name) + 'X') - 1))
                        ) )
                      ORDER BY COUNT(*) DESC", cn))
                {
                    cmd.Parameters.AddWithValue("@siteId", int.Parse(siteId));
                    var result = cmd.ExecuteScalar();
                    string prefix = (result == null || result == DBNull.Value) ? "" : result.ToString().Trim();
                    
                    // If no EE-style prefix found, try to derive from company name
                    // Company names are like "613 Martinsburg" — extract the station number
                    if (string.IsNullOrEmpty(prefix))
                    {
                        using (var cmd2 = new SqlCommand(
                            "SELECT name FROM dbo.company WHERE id = @siteId", cn))
                        {
                            cmd2.Parameters.AddWithValue("@siteId", int.Parse(siteId));
                            var nameResult = cmd2.ExecuteScalar();
                            if (nameResult != null && nameResult != DBNull.Value)
                            {
                                string companyName = nameResult.ToString().Trim();
                                // Extract leading number (e.g. "613" from "613 Martinsburg")
                                var match = System.Text.RegularExpressions.Regex.Match(companyName, @"^(\d+)");
                                if (match.Success)
                                    prefix = match.Groups[1].Value + " EE";
                            }
                        }
                    }
                    
                    return json.Serialize(new { prefix = prefix });
                }
            }
        }
        catch (Exception ex)
        {
            return json.Serialize(new { prefix = "", error = ex.Message });
        }
    }

    // ===================================================================
    // AJAX WebMethod — Get available print templates
    // ===================================================================
    [WebMethod(EnableSession = true)]
    [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static string GetPrintTemplates()
    {
        var json = new JavaScriptSerializer();
        try
        {
            var templates = new List<Dictionary<string, object>>();
            string siteFilter = UserManager.BuildSiteFilter(System.Web.HttpContext.Current.Session, ConnStr);
            using (var cn = new SqlConnection(ConnStr))
            {
                cn.Open();
                using (var cmd = new SqlCommand(
                    "SELECT id, name FROM dbo.template WHERE printclientid > 0" + siteFilter + " ORDER BY name", cn))
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                    {
                        templates.Add(new Dictionary<string, object> {
                            { "id", rdr.GetInt32(0) },
                            { "name", rdr.GetString(1) }
                        });
                    }
                }
            }
            return json.Serialize(new { templates = templates });
        }
        catch (Exception ex)
        {
            return json.Serialize(new { templates = new object[] { }, error = ex.Message });
        }
    }

    // ===================================================================
    // AJAX WebMethod — Get asset data for print preview by name list
    // ===================================================================
    [WebMethod(EnableSession = true)]
    [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static string GetAssetsForPrint(string siteId, string assetNamesJson)
    {
        var json = new JavaScriptSerializer { MaxJsonLength = 50000000 };
        try
        {
            var names = json.Deserialize<List<string>>(assetNamesJson);
            if (names == null || names.Count == 0)
                return json.Serialize(new { data = new object[] { }, error = "No asset names provided." });

            // Cap at 500 to prevent abuse
            if (names.Count > 500)
                names = names.GetRange(0, 500);

            var where = new List<string>();
            var pars = new List<SqlParameter>();

            // Build IN clause for asset names
            var inParams = new List<string>();
            for (int i = 0; i < names.Count; i++)
            {
                string pName = "@n" + i;
                inParams.Add(pName);
                pars.Add(new SqlParameter(pName, names[i].Trim()));
            }
            where.Add("a.name IN (" + string.Join(",", inParams) + ")");

            // Site filter
            if (!string.IsNullOrEmpty(siteId) && siteId != "0")
            {
                where.Add("a.companyid = @site");
                pars.Add(new SqlParameter("@site", int.Parse(siteId)));
            }

            // Enforce site-level access restriction
            var session = HttpContext.Current.Session;
            string siteAccessFilter = UserManager.BuildSiteFilter(session, ConnStr, "a");
            if (!string.IsNullOrEmpty(siteAccessFilter))
                where.Add(siteAccessFilter.TrimStart().Substring(4));

            string whereStr = where.Count > 0 ? "WHERE " + string.Join(" AND ", where) : "";

            string sql = string.Format(@"
                SELECT 
                    a.id, a.name, a.description, a.locationname, a.text8, a.listvalue1,
                    a.text4, a.text1, a.text2, a.text3, a.text5, a.text6,
                    a.text7, a.text9, a.text11, a.lastinventoried,
                    DATEDIFF(DAY, a.lastinventoried, GETDATE()) AS daysSince
                FROM dbo.v_asset a WITH(NOLOCK)
                {0}
                ORDER BY a.name ASC", whereStr);

            var rows = new List<Dictionary<string, object>>();
            using (var cn = new SqlConnection(ConnStr))
            {
                cn.Open();
                using (var cmd = new SqlCommand(sql, cn))
                {
                    AddParams(cmd, pars);
                    using (var rdr = cmd.ExecuteReader())
                    {
                        var colNames = new List<string>();
                        for (int i = 0; i < rdr.FieldCount; i++)
                            colNames.Add(rdr.GetName(i));

                        while (rdr.Read())
                        {
                            var row = new Dictionary<string, object>();
                            foreach (var col in colNames)
                            {
                                var val = rdr[col];
                                row[col] = (val == null || val == DBNull.Value) ? null : val;
                            }
                            rows.Add(row);
                        }
                    }
                }
            }

            // Also return list of names that were NOT found
            var foundNames = rows.Select(r => (r["name"] ?? "").ToString()).ToList();
            var notFound = names.Where(n => !foundNames.Any(f => f.Equals(n.Trim(), StringComparison.OrdinalIgnoreCase))).ToList();

            return json.Serialize(new { data = rows, notFound = notFound });
        }
        catch (Exception ex)
        {
            return json.Serialize(new { data = new object[] { }, error = ex.Message });
        }
    }

    // ===================================================================
    // AJAX WebMethod — Submit print jobs for selected assets
    // ===================================================================
    [WebMethod(EnableSession = true)]
    [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static string SubmitPrintJobs(string siteId, string assetNamesJson, long templateId)
    {
        var json = new JavaScriptSerializer();
        try
        {
            var names = json.Deserialize<List<string>>(assetNamesJson);
            if (names == null || names.Count == 0)
                return json.Serialize(new { success = false, error = "No asset names provided." });

            int companyId = 0;
            if (!string.IsNullOrEmpty(siteId) && siteId != "0")
                companyId = int.Parse(siteId);

            // If no site selected, resolve from template
            if (companyId <= 0 && templateId > 0)
                companyId = PrintApiHelper.GetCompanyIdForTemplate(templateId);

            int jobsCreated = 0;
            var errors = new List<string>();

            // Still need DB lookup to resolve asset names → IDs
            var assetIds = new List<long>();
            using (var cn = new SqlConnection(ConnStr))
            {
                cn.Open();

                foreach (var name in names)
                {
                    string trimmed = name.Trim();
                    using (var cmd = new SqlCommand(
                        "SELECT TOP 1 id FROM dbo.asset WHERE name = @name" +
                        (companyId > 0 ? " AND companyid = @cid" : ""), cn))
                    {
                        cmd.Parameters.AddWithValue("@name", trimmed);
                        if (companyId > 0) cmd.Parameters.AddWithValue("@cid", companyId);
                        var result = cmd.ExecuteScalar();
                        if (result == null || result == DBNull.Value)
                        {
                            errors.Add("Asset not found: " + trimmed);
                            continue;
                        }
                        assetIds.Add(Convert.ToInt64(result));
                    }
                }
            }

            // Direct BarTender printing — no iDash Print Service / MQTT
            List<string> printErrors;
            jobsCreated = PrintApiHelper.PrintAssetsDirect(
                assetIds, templateId, out printErrors);
            errors.AddRange(printErrors);

            return json.Serialize(new { 
                success = true, 
                jobsCreated = jobsCreated, 
                errors = errors 
            });
        }
        catch (Exception ex)
        {
            return json.Serialize(new { success = false, error = ex.Message });
        }
    }

    // ===================================================================
    // Print request handler — receives JSON payload, inserts printjob rows
    // (mirrors va_tagteam_scan HandlePrintRequest pattern)
    // ===================================================================
    private void HandlePrintRequest()
    {
        try
        {
            string body = "";
            using (var sr = new System.IO.StreamReader(Request.InputStream))
                body = sr.ReadToEnd();

            if (string.IsNullOrWhiteSpace(body))
            {
                Response.StatusCode = 400;
                Response.Write("Empty request body");
                Response.End();
                return;
            }

            var js = new System.Web.Script.Serialization.JavaScriptSerializer();
            var jobs = js.Deserialize<System.Collections.Generic.List<System.Collections.Generic.Dictionary<string, object>>>(body);

            if (jobs == null || jobs.Count == 0)
            {
                Response.StatusCode = 400;
                Response.Write("No jobs in payload");
                Response.End();
                return;
            }

            // Direct BarTender printing — no iDash Print Service / MQTT
            var errors = new System.Collections.Generic.List<string>();
            int count = PrintApiHelper.PrintJobsDirect(jobs, out errors);

            Response.StatusCode = 200;
            Response.ContentType = "application/json";
            Response.Write("{\"ok\":true, \"count\":" + count + "}");
            Response.End();
        }
        catch (System.Threading.ThreadAbortException)
        {
            // Response.End() always throws this — not a real error
        }
        catch (Exception ex)
        {
            Response.StatusCode = 500;
            Response.Write(ex.Message);
            try { Response.End(); } catch (System.Threading.ThreadAbortException) { }
        }
    }

    // ===================================================================
    // Inject print config JSON + JS functions into the page
    // (mirrors va_tagteam_scan InjectPrintScript pattern)
    // ===================================================================
    private void InjectPrintConfig()
    {
        try
        {
            string apiBase = Request.Url.GetLeftPart(UriPartial.Authority) + "/api";

            string tmJson = "{}";
            try {
                string path = Server.MapPath("print_mapping_config.json");
                if (System.IO.File.Exists(path)) tmJson = System.IO.File.ReadAllText(path);
            } catch { }

            var templateRoutes = new System.Collections.Generic.Dictionary<string, string>();
            var availableClients = new System.Collections.Generic.List<string>();
            var printTemplates = new System.Collections.Generic.List<object>();

            try {
                using (var con = new System.Data.SqlClient.SqlConnection(ConnStr)) {
                    con.Open();
                    string siteFilter = UserManager.BuildSiteFilter(Session, ConnStr, "t");
                    using (var cmd = new System.Data.SqlClient.SqlCommand(@"
                        SELECT t.id,
                               t.name,
                               ISNULL(NULLIF(t.usewithservice, ''), p.username) as finalRouting
                        FROM template t
                        LEFT JOIN printclient p ON t.printclientid = p.id
                        WHERE t.printclientid > 0" + siteFilter + @"
                        ORDER BY t.name", con))
                    using (var r = cmd.ExecuteReader()) {
                        while (r.Read()) {
                            string idStr = Convert.ToInt64(r[0]).ToString();
                            string name = r[1].ToString();
                            string routing = r[2] == DBNull.Value ? "" : r[2].ToString();
                            if (!string.IsNullOrEmpty(routing)) templateRoutes[idStr] = routing;
                            printTemplates.Add(new { id = Convert.ToInt64(r[0]), name = name });
                        }
                    }

                    using (var cmdClients = new System.Data.SqlClient.SqlCommand(
                        "SELECT username FROM printclient UNION SELECT username FROM mqttclient ORDER BY username", con))
                    using (var rClient = cmdClients.ExecuteReader()) {
                        while (rClient.Read()) availableClients.Add(rClient[0].ToString());
                    }
                }
            } catch { }

            var jss = new System.Web.Script.Serialization.JavaScriptSerializer();
            string trJson = jss.Serialize(templateRoutes);
            string clJson = jss.Serialize(availableClients);
            string ptJson = jss.Serialize(printTemplates);

            LitPrintConfig.Text = string.Format(@"<script>
    window.awPrintConfigAM = {{
        apiBase: '{0}',
        templateMappings: {1},
        templateRoutes: {2},
        availableClients: {3},
        printTemplates: {4}
    }};
</script>", apiBase, tmJson, trJson, clJson, ptJson);
        }
        catch (Exception ex)
        {
            LitPrintConfig.Text = "<!-- AM Print Config Error: " + ex.Message + "-->";
        }
    }

    // ===================================================================
    // Export handler — CSV or Excel via querystring
    // ===================================================================
    private void HandleExport()
    {
        string fmt = Request["fmt"] ?? "csv";
        string idsStr = Request["ids"] ?? "";
        string search = Request["search"] ?? "";
        string site = Request["site"] ?? "0";
        string status = Request["status"] ?? "";
        string cmr = Request["cmr"] ?? "";
        string location = Request["location"] ?? "";
        string days = Request["days"] ?? "";
        string colsStr = Request["cols"] ?? "";

        // Build WHERE
        var where = new List<string>();
        var pars = new List<SqlParameter>();

        bool isSelectedExport = false;
        if (!string.IsNullOrWhiteSpace(idsStr))
        {
            var idList = idsStr.Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries)
                               .Select(s => { long id; return long.TryParse(s.Trim(), out id) ? (long?)id : null; })
                               .Where(id => id.HasValue)
                               .Select(id => id.Value)
                               .ToList();
            if (idList.Count > 0)
            {
                isSelectedExport = true;
                where.Add("a.id IN (" + string.Join(",", idList) + ")");
            }
        }

        if (!isSelectedExport)
        {
            if (!string.IsNullOrWhiteSpace(search))
            {
                where.Add("(a.name LIKE @q OR a.text8 LIKE @q OR a.text3 LIKE @q OR a.locationname LIKE @q OR a.description LIKE @q OR a.text1 LIKE @q OR a.text6 LIKE @q)");
                pars.Add(new SqlParameter("@q", "%" + search.Trim() + "%"));
            }
            if (!string.IsNullOrEmpty(site) && site != "0")
            {
                where.Add("a.companyid = @site");
                pars.Add(new SqlParameter("@site", int.Parse(site)));
            }
            if (!string.IsNullOrEmpty(status))
            {
                where.Add("a.listvalue1 = @status");
                pars.Add(new SqlParameter("@status", status));
            }
            if (!string.IsNullOrWhiteSpace(cmr))
            {
                where.Add("a.text8 LIKE @cmr");
                pars.Add(new SqlParameter("@cmr", "%" + cmr.Trim() + "%"));
            }
            if (!string.IsNullOrWhiteSpace(location))
            {
                where.Add("(a.locationname LIKE @loc OR a.lastobservedlocation LIKE @loc)");
                pars.Add(new SqlParameter("@loc", "%" + location.Trim() + "%"));
            }
            int exportDaysVal;
            if (!string.IsNullOrEmpty(days) && int.TryParse(days, out exportDaysVal) && exportDaysVal >= 0)
            {
                where.Add("DATEDIFF(DAY, a.lastinventoried, GETDATE()) >= @daysFilterExp");
                pars.Add(new SqlParameter("@daysFilterExp", exportDaysVal));
            }

            // Fixed Reader Report filter
            string fixedReader = Request["fixedReader"] ?? "";
            if (!string.IsNullOrWhiteSpace(fixedReader))
            {
                switch (fixedReader.ToLower())
                {
                    case "today": where.Add("a.lastobservedtime >= CAST(GETDATE() AS DATE)"); break;
                    case "week":  where.Add("a.lastobservedtime >= DATEADD(DAY, -7, GETDATE())"); break;
                    case "month": where.Add("a.lastobservedtime >= DATEADD(MONTH, -1, GETDATE())"); break;
                    case "all":   where.Add("a.lastobservedtime IS NOT NULL"); break;
                }
            }
        }

        // Site-level access restriction — use site dropdown value only (no UserManager dependency)
        string whereStr = where.Count > 0 ? "WHERE " + string.Join(" AND ", where) : "";

        // Build column SELECT list from user's visible columns
        var selectedCols = new List<string>();
        var colLabels = new Dictionary<string, string>
        {
            {"name","Asset Name"}, {"description","Description"}, {"locationname","Location"},
            {"text8","CMR"}, {"listvalue1","Status"}, {"text4","Category"},
            {"text1","Manufacturer"}, {"text2","Model"}, {"text3","Serial #"},
            {"text5","Service"}, {"text6","Room"}, {"text7","Station"},
            {"text9","PO #"}, {"text11","Previous Location"}, {"lastinventoried","Last Inventoried"},
            {"daysSince","Days Since"}, {"rfidtag","RFID Tag"}, {"text18","Tagged"},
            {"lastobservedtime","Last Observed"}, {"lastobservedlocation","Observed Location"}
        };

        var requestedCols = (colsStr ?? "").Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
        if (requestedCols.Length == 0)
            requestedCols = new[] { "name", "locationname", "text8", "listvalue1", "text4", "text1", "text7", "lastinventoried" };

        var selectParts = new List<string>();
        var headers = new List<string>();
        foreach (var key in requestedCols)
        {
            string dbCol = MapKeyToColumn(key);
            if (dbCol == null && key == "daysSince")
            {
                selectParts.Add("DATEDIFF(DAY, a.lastinventoried, GETDATE()) AS [Days Since]");
                headers.Add("Days Since");
            }
            else if (dbCol != null)
            {
                string label = colLabels.ContainsKey(key) ? colLabels[key] : key;
                selectParts.Add(dbCol + " AS [" + label + "]");
                headers.Add(label);
            }
        }

        if (selectParts.Count == 0) return;

        string sql = "SELECT " + string.Join(", ", selectParts) + " FROM dbo.v_asset a WITH(NOLOCK) "
            + whereStr + " ORDER BY a.name ASC";

        DataTable dt = new DataTable();
        using (var cn = new SqlConnection(ConnStr))
        using (var da = new SqlDataAdapter(sql, cn))
        {
            foreach (var p in pars)
                da.SelectCommand.Parameters.AddWithValue(p.ParameterName, p.Value ?? "");
            da.Fill(dt);
        }

        if (fmt == "excel")
        {
            ExportExcel(dt, isSelectedExport);
        }
        else
        {
            ExportCsv(dt, isSelectedExport);
        }
    }

    private void ExportCsv(DataTable dt, bool isSelected = false)
    {
        var sb = new StringBuilder();
        sb.AppendLine(string.Join(",", dt.Columns.Cast<DataColumn>().Select(c => CsvEscape(c.ColumnName))));
        foreach (DataRow row in dt.Rows)
        {
            sb.AppendLine(string.Join(",", dt.Columns.Cast<DataColumn>().Select(c => CsvEscape(Convert.ToString(row[c])))));
        }

        string filename = isSelected ? "AssetMaster_Selected_Export.csv" : "AssetMaster_Export.csv";
        Response.Clear();
        Response.ClearHeaders();
        Response.Buffer = true;
        Response.ContentType = "text/csv; charset=utf-8";
        Response.AddHeader("Content-Disposition", "attachment; filename=" + filename);
        Response.ContentEncoding = Encoding.UTF8;
        Response.Write(sb.ToString());
        Response.Flush();
        Response.SuppressContent = true;
        HttpContext.Current.ApplicationInstance.CompleteRequest();
    }

    private void ExportExcel(DataTable dt, bool isSelected = false)
    {
        try
        {
            // Sanitize DataTable: ClosedXML does not accept DateTimeOffset, convert to formatted string
            DataTable exportDt = new DataTable();
            foreach (DataColumn col in dt.Columns)
            {
                if (col.DataType == typeof(DateTimeOffset))
                    exportDt.Columns.Add(col.ColumnName, typeof(string));
                else
                    exportDt.Columns.Add(col.ColumnName, col.DataType);
            }

            foreach (DataRow row in dt.Rows)
            {
                var newRow = exportDt.NewRow();
                for (int i = 0; i < dt.Columns.Count; i++)
                {
                    var val = row[i];
                    if (val is DateTimeOffset)
                        newRow[i] = ((DateTimeOffset)val).ToString("yyyy-MM-dd HH:mm:ss");
                    else
                        newRow[i] = val;
                }
                exportDt.Rows.Add(newRow);
            }

            byte[] bytes;
            using (var wb = new XLWorkbook())
            {
                var ws = wb.Worksheets.Add(isSelected ? "Selected Assets" : "Asset Master");

                // Ensure unique, valid column headers for ClosedXML
                var usedColNames = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                for (int c = 0; c < exportDt.Columns.Count; c++)
                {
                    string colName = string.IsNullOrWhiteSpace(exportDt.Columns[c].ColumnName) ? "Column" + (c + 1) : exportDt.Columns[c].ColumnName.Trim();
                    string uniqueName = colName;
                    int counter = 1;
                    while (usedColNames.Contains(uniqueName))
                    {
                        uniqueName = colName + "_" + counter++;
                    }
                    usedColNames.Add(uniqueName);
                    exportDt.Columns[c].ColumnName = uniqueName;
                }

                // Bulk insert table with AutoFilters and styling
                var table = ws.Cell(1, 1).InsertTable(exportDt, "AssetMasterTable", false);
                table.ShowAutoFilter = true;
                table.Theme = XLTableTheme.TableStyleMedium2;

                // Adjust column widths by sampling up to first 50 rows (sub-second performance)
                int sampleRows = Math.Min(50, exportDt.Rows.Count + 1);
                ws.Columns(1, exportDt.Columns.Count).AdjustToContents(1, sampleRows);

                using (var ms = new MemoryStream())
                {
                    wb.SaveAs(ms);
                    bytes = ms.ToArray();
                }
            }

            string filename = isSelected ? "AssetMaster_Selected_Export.xlsx" : "AssetMaster_Export.xlsx";
            Response.Clear();
            Response.ClearHeaders();
            Response.Buffer = true;
            Response.ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
            Response.AddHeader("Content-Disposition", "attachment; filename=" + filename);
            Response.AddHeader("Content-Length", bytes.Length.ToString());
            Response.BinaryWrite(bytes);
            Response.Flush();
            Response.SuppressContent = true;
            HttpContext.Current.ApplicationInstance.CompleteRequest();
        }
        catch (System.Threading.ThreadAbortException)
        {
            // Normal response termination - do not fall back to CSV!
        }
        catch (Exception)
        {
            // Only fall back to CSV if Excel generation genuinely failed
            ExportCsv(dt, isSelected);
        }
    }

    // ===================================================================
    // Helpers
    // ===================================================================
    private static string MapKeyToColumn(string key)
    {
        if (string.IsNullOrEmpty(key)) return null;
        switch (key.ToLower())
        {
            case "name":            return "a.name";
            case "description":     return "a.description";
            case "locationname":    return "a.locationname";
            case "text8":           return "a.text8";
            case "listvalue1":      return "a.listvalue1";
            case "text4":           return "a.text4";
            case "text1":           return "a.text1";
            case "text2":           return "a.text2";
            case "text3":           return "a.text3";
            case "text5":           return "a.text5";
            case "text6":           return "a.text6";
            case "text7":           return "a.text7";
            case "text9":           return "a.text9";
            case "text11":          return "a.text11";
            case "lastinventoried": return "a.lastinventoried";
            case "rfidtag":         return "a.rfidtag";   // Raw RFID tag number
            case "text18":          return "a.text18";    // Tagged flag (1=Tagged)
            case "lastobservedtime":  return "a.lastobservedtime";
            case "lastobservedlocation": return "a.lastobservedlocation";
            default:                return null;
        }
    }

    private static void AddParams(SqlCommand cmd, List<SqlParameter> pars)
    {
        foreach (var p in pars)
        {
            if (!cmd.Parameters.Contains(p.ParameterName))
                cmd.Parameters.AddWithValue(p.ParameterName, p.Value ?? "");
        }
    }

    private static string CsvEscape(string s)
    {
        if (string.IsNullOrEmpty(s)) return "";
        s = s.Replace("\"", "\"\"");
        bool mustQuote = (s.IndexOfAny(new char[] { ',', '"', '\n', '\r' }) >= 0);
        return mustQuote ? "\"" + s + "\"" : s;
    }

    // ===================================================================
    // Detail Panel API — dispatcher
    // ===================================================================
    private void HandleDetailApi(string api)
    {
        Response.ContentType = "application/json";
        Response.Cache.SetCacheability(HttpCacheability.NoCache);
        var json = new JavaScriptSerializer { MaxJsonLength = 10000000 };

        try
        {
            string idStr = Request.QueryString["id"];
            int assetId = 0;
            if (!string.IsNullOrEmpty(idStr))
                int.TryParse(idStr, out assetId);

            if (assetId <= 0)
            {
                Response.Write(json.Serialize(new { error = "Missing or invalid asset id." }));
                Response.End();
                return;
            }

            // Enforce site-level access
            string siteFilter = UserManager.BuildSiteFilter(Session, ConnStr, "a");
            if (!string.IsNullOrEmpty(siteFilter))
            {
                using (var authCn = new SqlConnection(ConnStr))
                {
                    authCn.Open();
                    string authSql = "SELECT 1 FROM dbo.v_asset a WITH(NOLOCK) WHERE a.id = @id" + siteFilter;
                    using (var authCmd = new SqlCommand(authSql, authCn))
                    {
                        authCmd.Parameters.AddWithValue("@id", assetId);
                        object authObj = authCmd.ExecuteScalar();
                        if (authObj == null || authObj == DBNull.Value)
                        {
                            Response.Write(json.Serialize(new { error = "Asset not found or access denied." }));
                            Response.End();
                            return;
                        }
                    }
                }
            }

            string result;
            switch (api.ToLower())
            {
                case "detail":          result = GetAssetDetail(assetId, siteFilter, json); break;
                case "locationhistory": result = GetLocationHistory(assetId, siteFilter, json); break;
                case "checkouthistory": result = GetCheckoutHistory(assetId, siteFilter, json); break;
                case "maintenance":     result = GetMaintenanceHistory(assetId, siteFilter, json); break;
                case "children":        result = GetChildren(assetId, siteFilter, json); break;
                case "update":          result = UpdateAsset(assetId, siteFilter, json); break;
                default:
                    result = json.Serialize(new { error = "Unknown api: " + api });
                    break;
            }

            Response.Write(result);
        }
        catch (System.Threading.ThreadAbortException)
        {
            // Expected from Response.End()
        }
        catch (Exception ex)
        {
            Response.Write(json.Serialize(new { error = ex.Message }));
        }

        try { Response.End(); } catch (System.Threading.ThreadAbortException) { }
    }

    // ── Full asset detail (single row from v_asset) ──
    private string GetAssetDetail(int assetId, string siteFilter, JavaScriptSerializer json)
    {
        using (var cn = new SqlConnection(ConnStr))
        {
            cn.Open();
            string sql = @"
                SELECT a.id, a.name, a.description, a.rfidtag, a.assettype,
                       a.locationname, a.locationsite, a.locationbuilding, a.locationfloor, a.locationroom,
                       a.departmentcode, a.lastobservedlocation, a.lastobservedtime,
                       a.checkinstatus, a.checkedoutto,
                       a.listvalue1, a.listvalue2, a.listvalue3, a.listvalue4, a.listvalue5,
                       a.text1, a.text2, a.text3, a.text4, a.text5, a.text6, a.text7, a.text8,
                       a.text9, a.text10, a.text11, a.text12, a.text13, a.text14, a.text15,
                       a.maintenancestartdate, a.maintenancesingledate, a.nextmaintenance,
                       a.lastmaintenance, a.maintenancemethod, a.maintenanceintervalmonths,
                       a.lastinventoried, a.created, a.lastmodified, a.lastmodifiedby,
                       COALESCE(a.nearestfixed, r.name) AS nearestfixedname, a.assetchildcount, a.companyid,
                       a.date1, a.date2, a.date3, a.date4, a.date5,
                       a.additionalinformation, a.disposalstatus, a.disposalmethod,
                       a.disposaldate, a.disposaldestination,
                       a.batterylevel, a.vtagid, a.vtagtype
                FROM dbo.v_asset a WITH(NOLOCK)
                LEFT JOIN dbo.reader r WITH(NOLOCK) ON r.id = a.readerid
                WHERE a.id = @id" + (string.IsNullOrEmpty(siteFilter) ? "" : siteFilter);

            using (var cmd = new SqlCommand(sql, cn))
            {
                cmd.Parameters.AddWithValue("@id", assetId);
                using (var rdr = cmd.ExecuteReader())
                {
                    if (!rdr.Read())
                        return json.Serialize(new { error = "Asset not found or access denied." });

                    var row = new Dictionary<string, object>();
                    for (int i = 0; i < rdr.FieldCount; i++)
                    {
                        var val = rdr.GetValue(i);
                        row[rdr.GetName(i)] = (val == null || val == DBNull.Value) ? null : val;
                    }
                    return json.Serialize(new { asset = row });
                }
            }
        }
    }

    // ── Location history ──
    private string GetLocationHistory(int assetId, string siteFilter, JavaScriptSerializer json)
    {
        using (var cn = new SqlConnection(ConnStr))
        {
            cn.Open();
            string sql = @"
                SELECT TOP 200 lh.id, lh.timeseen, lh.timeleft, 
                       loc.name AS locationname, loc.building, loc.floor, loc.room
                FROM dbo.locationhistory lh WITH(NOLOCK)
                LEFT JOIN dbo.location loc WITH(NOLOCK) ON loc.id = lh.locationid
                WHERE lh.assetid = @id
                ORDER BY lh.timeseen DESC";

            using (var cmd = new SqlCommand(sql, cn))
            {
                cmd.Parameters.AddWithValue("@id", assetId);
                var rows = new List<Dictionary<string, object>>();
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                    {
                        var row = new Dictionary<string, object>();
                        for (int i = 0; i < rdr.FieldCount; i++)
                        {
                            var val = rdr.GetValue(i);
                            row[rdr.GetName(i)] = (val == null || val == DBNull.Value) ? null : val;
                        }
                        rows.Add(row);
                    }
                }
                return json.Serialize(new { records = rows, total = rows.Count });
            }
        }
    }

    // ── Checkout history ──
    private string GetCheckoutHistory(int assetId, string siteFilter, JavaScriptSerializer json)
    {
        using (var cn = new SqlConnection(ConnStr))
        {
            cn.Open();
            string sql = @"
                SELECT TOP 200 ch.id, ch.checkinstatus, ch.individual, ch.transactiontime,
                       loc.name AS locationname
                FROM dbo.checkouthistory ch WITH(NOLOCK)
                LEFT JOIN dbo.location loc WITH(NOLOCK) ON loc.id = ch.locationid
                WHERE ch.assetid = @id
                ORDER BY ch.transactiontime DESC";

            using (var cmd = new SqlCommand(sql, cn))
            {
                cmd.Parameters.AddWithValue("@id", assetId);
                var rows = new List<Dictionary<string, object>>();
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                    {
                        var row = new Dictionary<string, object>();
                        for (int i = 0; i < rdr.FieldCount; i++)
                        {
                            var val = rdr.GetValue(i);
                            row[rdr.GetName(i)] = (val == null || val == DBNull.Value) ? null : val;
                        }
                        rows.Add(row);
                    }
                }
                return json.Serialize(new { records = rows, total = rows.Count });
            }
        }
    }

    // ── Maintenance history ──
    private string GetMaintenanceHistory(int assetId, string siteFilter, JavaScriptSerializer json)
    {
        using (var cn = new SqlConnection(ConnStr))
        {
            cn.Open();
            string sql = @"
                SELECT TOP 200 mh.id, mh.whenperformed, mh.actionperformed, mh.notes,
                       mh.performedby, mh.regularmaintenance
                FROM dbo.maintenancehistory mh WITH(NOLOCK)
                WHERE mh.assetid = @id
                ORDER BY mh.whenperformed DESC";

            using (var cmd = new SqlCommand(sql, cn))
            {
                cmd.Parameters.AddWithValue("@id", assetId);
                var rows = new List<Dictionary<string, object>>();
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                    {
                        var row = new Dictionary<string, object>();
                        for (int i = 0; i < rdr.FieldCount; i++)
                        {
                            var val = rdr.GetValue(i);
                            row[rdr.GetName(i)] = (val == null || val == DBNull.Value) ? null : val;
                        }
                        rows.Add(row);
                    }
                }
                return json.Serialize(new { records = rows, total = rows.Count });
            }
        }
    }

    // ── Child assets ──
    private string GetChildren(int assetId, string siteFilter, JavaScriptSerializer json)
    {
        using (var cn = new SqlConnection(ConnStr))
        {
            cn.Open();
            string sql = @"
                SELECT a.id, a.name, a.description, a.locationname, a.listvalue1,
                       a.text8, a.text1, a.rfidtag, a.lastinventoried
                FROM dbo.v_asset a WITH(NOLOCK)
                WHERE a.assetparentid = @id
                ORDER BY a.name";

            using (var cmd = new SqlCommand(sql, cn))
            {
                cmd.Parameters.AddWithValue("@id", assetId);
                var rows = new List<Dictionary<string, object>>();
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                    {
                        var row = new Dictionary<string, object>();
                        for (int i = 0; i < rdr.FieldCount; i++)
                        {
                            var val = rdr.GetValue(i);
                            row[rdr.GetName(i)] = (val == null || val == DBNull.Value) ? null : val;
                        }
                        rows.Add(row);
                    }
                }
                return json.Serialize(new { records = rows, total = rows.Count });
            }
        }
    }

    // ===================================================================
    // Update Asset — inline edit from detail panel
    // ===================================================================
    private string UpdateAsset(int assetId, string siteFilter, JavaScriptSerializer json)
    {
        // Whitelist of editable columns (column name → max length, 0 = int)
        var allowed = new Dictionary<string, int>
        {
            { "description", 500 },
            { "listvalue1", 100 },       // Status
            { "checkinstatus", 50 },
            { "checkedoutto", 50 },
            { "departmentcode", 50 },
            { "text1", 500 },             // Manufacturer
            { "text2", 500 },             // Model
            { "text3", 500 },             // Serial #
            { "text4", 500 },             // Category
            { "text5", 500 },             // Service
            { "text6", 500 },             // Room
            { "text7", 500 },             // Station
            { "text8", 500 },             // CMR
            { "text9", 500 },             // PO #
            { "text10", 500 },
            { "text11", 500 },            // Previous Location
            { "additionalinformation", 5000 },
            { "maintenancemethod", 50 },
            { "maintenanceintervalmonths", 0 },
            { "disposalstatus", 50 },
            { "disposalmethod", 50 },
            { "disposaldestination", 50 }
        };

        // Read POST body as JSON
        string body;
        using (var sr = new StreamReader(Request.InputStream))
            body = sr.ReadToEnd();

        if (string.IsNullOrWhiteSpace(body))
            return json.Serialize(new { error = "No data provided." });

        var fields = json.Deserialize<Dictionary<string, object>>(body);
        if (fields == null || fields.Count == 0)
            return json.Serialize(new { error = "No fields to update." });

        // Build SET clause from whitelisted fields only
        var setClauses = new List<string>();
        var pars = new List<SqlParameter>();

        foreach (var kv in fields)
        {
            string col = kv.Key.ToLower();
            if (!allowed.ContainsKey(col)) continue;

            string paramName = "@f_" + col;
            int maxLen = allowed[col];

            if (kv.Value == null || string.IsNullOrEmpty(kv.Value.ToString()))
            {
                setClauses.Add(col + " = NULL");
            }
            else if (maxLen == 0) // integer column
            {
                int intVal;
                if (int.TryParse(kv.Value.ToString(), out intVal))
                {
                    setClauses.Add(col + " = " + paramName);
                    pars.Add(new SqlParameter(paramName, intVal));
                }
            }
            else // varchar column
            {
                string val = kv.Value.ToString();
                if (val.Length > maxLen) val = val.Substring(0, maxLen);
                setClauses.Add(col + " = " + paramName);
                pars.Add(new SqlParameter(paramName, val));
            }
        }

        if (setClauses.Count == 0)
            return json.Serialize(new { error = "No valid fields to update." });

        // Add audit trail
        setClauses.Add("lastmodified = SYSDATETIMEOFFSET()");
        string user = (Session["username"] ?? Session["user"] ?? "iDash").ToString();
        setClauses.Add("lastmodifiedby = @modby");
        pars.Add(new SqlParameter("@modby", user.Length > 50 ? user.Substring(0, 50) : user));

        // Execute update with site-level access control
        string sql = "UPDATE dbo.asset SET " + string.Join(", ", setClauses) +
                     " WHERE id = @id";

        // Re-apply site filter: ensure user has access to this asset's companyid
        if (!string.IsNullOrEmpty(siteFilter))
        {
            // siteFilter is like " AND a.companyid IN (...)"
            // Replace alias 'a.' with table name for update context
            sql += siteFilter.Replace("a.companyid", "companyid");
        }

        using (var cn = new SqlConnection(ConnStr))
        {
            cn.Open();
            using (var cmd = new SqlCommand(sql, cn))
            {
                cmd.Parameters.AddWithValue("@id", assetId);
                foreach (var p in pars)
                    cmd.Parameters.Add(p);

                int rows = cmd.ExecuteNonQuery();
                if (rows == 0)
                    return json.Serialize(new { error = "Asset not found or access denied." });

                return json.Serialize(new { success = true, updated = setClauses.Count - 2, message = "Asset updated successfully." });
            }
        }
    }
}

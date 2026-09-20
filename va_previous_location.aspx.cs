using System;
using System.Data.SqlClient;
using System.Configuration;
using System.Web.Script.Serialization;
using System.Collections.Generic;

public partial class va_previous_location : System.Web.UI.Page
{
    private string ConnStr = ConfigurationManager.ConnectionStrings["iDash"].ConnectionString;

    protected void Page_Load(object sender, EventArgs e)
    {
        // Auth check (applies to both page load and ?api=search calls)
        bool isLoggedIn = Session["IsAdminAuthenticated"] != null && (bool)Session["IsAdminAuthenticated"];
        if (!isLoggedIn) { Response.Redirect("index.aspx"); return; }

        // Tile key check
        var tiles = Session["IdashTileAccess"] as List<string>;
        string role = System.Convert.ToString(Session["IdashUserRole"]);
        if (!UserManager.CanAccessTile(role, tiles, "search_location"))
        {
            Response.Redirect("index.aspx?err=access"); return;
        }

        if (Request["api"] == "search")
        {
            HandleApiSearch();
            return;
        }

        if (!IsPostBack)
        {
            LoadCompanies(); // Initial UI page load
        }
    }

    private void LoadCompanies()
    {
        try
        {
            using (SqlConnection conn = new SqlConnection(ConnStr))
            {
                conn.Open();
                string sql = "SELECT id, name FROM dbo.company ORDER BY name";
                using (SqlCommand cmd = new SqlCommand(sql, conn))
                using (SqlDataReader rdr = cmd.ExecuteReader())
                {
                    DdlCompany.DataSource = rdr;
                    DdlCompany.DataTextField = "name";
                    DdlCompany.DataValueField = "id";
                    DdlCompany.DataBind();
                }
                DdlCompany.Items.Insert(0, new System.Web.UI.WebControls.ListItem("All Sites", "0"));
            }
        }
        catch (Exception)
        {
            // Ignore error for visual JS page binding silently
        }
    }

    private void HandleApiSearch()
    {
        string q = Request["q"] ?? "";
        q = q.Trim();

        string site = Request["site"] ?? "0";
        string fromDate = Request["from"] ?? "";
        string toDate = Request["to"] ?? "";

        var results = new List<Dictionary<string, object>>();

        try
        {
            using (var conn = new SqlConnection(ConnStr))
            {
                conn.Open();

                string siteFilter = "";
                if (site != "0" && !string.IsNullOrEmpty(site))
                {
                    siteFilter = " AND a.companyid = @site";
                }

                string dateFilter = "";
                if (!string.IsNullOrEmpty(fromDate))
                {
                    dateFilter += " AND ISNULL(h.timeseen, a.lastinventoried) >= @fromDate";
                }
                if (!string.IsNullOrEmpty(toDate))
                {
                    dateFilter += " AND ISNULL(h.timeseen, a.lastinventoried) < DATEADD(day, 1, @toDate)";
                }

                // Retrieve history from Asset + locationhistory (or fallback to current loc)
                string sql = @"
                    SELECT TOP 2000 
                        a.name AS barCode,
                        a.description AS descr,
                        a.text8 AS eil,
                        a.text3 AS serial,
                        ISNULL(h.locationname, a.text6) AS scanLoc,
                        ISNULL(h.timeseen, a.lastinventoried) AS scanDate,
                        a.text11 AS prevLoc,
                        a.lastobservedlocation AS lastObsLoc,
                        a.text6 AS curLoc
                    FROM dbo.v_asset a WITH(NOLOCK)
                    LEFT JOIN dbo.v_locationhistory h WITH(NOLOCK) ON a.id = h.assetid
                    WHERE (@q = '' OR a.name LIKE '%' + @q + '%' OR a.text3 = @q OR a.text8 = @q)" + siteFilter + dateFilter + @"
                    ORDER BY ISNULL(h.timeseen, a.lastinventoried) DESC
                ";

                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@q", q);
                    if (site != "0" && !string.IsNullOrEmpty(site)) cmd.Parameters.AddWithValue("@site", site);
                    if (!string.IsNullOrEmpty(fromDate)) cmd.Parameters.AddWithValue("@fromDate", fromDate);
                    if (!string.IsNullOrEmpty(toDate)) cmd.Parameters.AddWithValue("@toDate", toDate);

                    using (var rdr = cmd.ExecuteReader())
                    {
                        while (rdr.Read())
                        {
                            var row = new Dictionary<string, object>();
                            row["Asset"] = rdr["barCode"].ToString();
                            row["Description"] = rdr["descr"].ToString();
                            row["EIL"] = rdr["eil"].ToString();
                            row["Serial"] = rdr["serial"].ToString();
                            row["Location"] = rdr["scanLoc"].ToString();
                            row["PreviousLocation"] = Convert.ToString(rdr["prevLoc"]);
                            row["LastObservedLocation"] = Convert.ToString(rdr["lastObsLoc"]);
                            row["CurrentLocation"] = Convert.ToString(rdr["curLoc"]);
                            
                            object dt = rdr["scanDate"];
                            if (dt != DBNull.Value && dt != null) {
                                if (dt is DateTimeOffset) {
                                    row["Date"] = ((DateTimeOffset)dt).ToString("yyyy-MM-dd HH:mm:ss");
                                } else if (dt is DateTime) {
                                    row["Date"] = ((DateTime)dt).ToString("yyyy-MM-dd HH:mm:ss");
                                } else {
                                    DateTime parsedDt;
                                    if (DateTime.TryParse(dt.ToString(), out parsedDt)) {
                                        row["Date"] = parsedDt.ToString("yyyy-MM-dd HH:mm:ss");
                                    } else {
                                        row["Date"] = dt.ToString();
                                    }
                                }
                            } else {
                                row["Date"] = "";
                            }

                            results.Add(row);
                        }
                    }
                }
            }
            
            SendJson(new { success = true, count = results.Count, data = results });
        }
        catch (Exception ex)
        {
            SendJson(new { success = false, error = ex.Message });
        }
    }

    private void SendJson(object obj)
    {
        Response.Clear();
        Response.ContentType = "application/json; charset=utf-8";
        var js = new JavaScriptSerializer() { MaxJsonLength = int.MaxValue };
        Response.Write(js.Serialize(obj));
        Response.Flush();
        Response.SuppressContent = true;
        System.Web.HttpContext.Current.ApplicationInstance.CompleteRequest();
    }
}

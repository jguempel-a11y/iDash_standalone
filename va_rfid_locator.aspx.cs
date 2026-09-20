using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Web;
using System.Web.Services;
using System.Web.Script.Serialization;

public partial class va_rfid_locator : System.Web.UI.Page
{
    private string ConnStr
    {
        get
        {
            var cs = ConfigurationManager.ConnectionStrings["iDash"];
            return cs == null ? "" : cs.ConnectionString;
        }
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            // Session auth check
            bool isLoggedIn = Session["IsAdminAuthenticated"] != null && (bool)Session["IsAdminAuthenticated"];
            if (!isLoggedIn) { Response.Redirect("index.aspx"); return; }

            // Tile key check — must have scan_locator
            var tiles = Session["IdashTileAccess"] as List<string>;
            string role = System.Convert.ToString(Session["IdashUserRole"]);
            if (!UserManager.CanAccessTile(role, tiles, "scan_locator"))
            {
                Response.Redirect("index.aspx?err=access"); return;
            }
        }
    }

    /// <summary>
    /// Looks up one or more assets by their EE number, barcode, serial, or RFID tag.
    /// Returns name, rfidtag, location, EIL (text8), and site for each match.
    /// </summary>
    [WebMethod]
    public static object LookupAssets(string[] identifiers)
    {
        // Guard: WebMethod is static so we access session via HttpContext
        var ctx = System.Web.HttpContext.Current;
        if (ctx == null || ctx.Session == null
            || ctx.Session["IsAdminAuthenticated"] == null
            || !(bool)ctx.Session["IsAdminAuthenticated"])
        {
            return new { error = "Not authenticated", assets = new object[0] };
        }

        var cs = ConfigurationManager.ConnectionStrings["iDash"];
        string connStr = (cs != null) ? cs.ConnectionString : null;
        if (string.IsNullOrEmpty(connStr) || identifiers == null || identifiers.Length == 0)
            return new { assets = new object[0] };

        var results = new List<object>();
        var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        using (SqlConnection conn = new SqlConnection(connStr))
        {
            conn.Open();

            foreach (string raw in identifiers)
            {
                string id = (raw ?? "").Trim();
                if (string.IsNullOrEmpty(id) || seen.Contains(id)) continue;
                seen.Add(id);

                // Normalize: strip spaces for alternate matching (e.g. "512 EE17360" -> "512EE17360")
                string idNoSpace = id.Replace(" ", "");

                string sql = @"
                    SELECT TOP 1
                        a.id,
                        a.name,
                        a.rfidtag,
                        a.text3           AS serial,
                        a.text8           AS eil,
                        a.text12          AS barcode,
                        ISNULL(l.name,'') AS locationName,
                        ISNULL(c.name,'') AS siteName
                    FROM dbo.asset a WITH (NOLOCK)
                    LEFT JOIN dbo.location l ON a.locationid = l.id
                    LEFT JOIN dbo.company  c ON a.companyid  = c.id
                    WHERE a.name                          = @id
                       OR a.rfidtag                       = @id
                       OR a.text12                        = @id
                       OR a.text3                         = @id
                       OR REPLACE(a.name, ' ', '')        = @idNoSpace
                       OR REPLACE(a.rfidtag, ' ', '')     = @idNoSpace";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@id", id);
                    cmd.Parameters.AddWithValue("@idNoSpace", idNoSpace);
                    using (SqlDataReader rdr = cmd.ExecuteReader())
                    {
                        if (rdr.Read())
                        {
                            results.Add(new
                            {
                                input     = id,
                                assetId   = rdr.GetInt32(0),
                                name      = rdr.IsDBNull(1) ? "" : rdr.GetString(1),
                                rfidtag   = rdr.IsDBNull(2) ? "" : rdr.GetString(2),
                                serial    = rdr.IsDBNull(3) ? "" : rdr.GetString(3),
                                eil       = rdr.IsDBNull(4) ? "" : rdr.GetString(4),
                                barcode   = rdr.IsDBNull(5) ? "" : rdr.GetString(5),
                                location  = rdr.IsDBNull(6) ? "" : rdr.GetString(6),
                                site      = rdr.IsDBNull(7) ? "" : rdr.GetString(7),
                                found     = false
                            });
                        }
                        else
                        {
                            results.Add(new
                            {
                                input     = id,
                                assetId   = 0,
                                name      = "",
                                rfidtag   = "",
                                serial    = "",
                                eil       = "",
                                barcode   = "",
                                location  = "",
                                site      = "",
                                found     = false
                            });
                        }
                    }
                }
            }
        }

        return new { assets = results };
    }
}

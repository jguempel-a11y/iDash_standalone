using System;
using System.Data.SqlClient;
using System.Configuration;

public partial class aw_scan_api : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        Response.ContentType = "text/html";

        string epc = Request["epc"];

        if (string.IsNullOrEmpty(epc))
        {
            Response.Write("No EPC provided");
            return;
        }

        string conn = ConfigurationManager.ConnectionStrings["iDash"].ConnectionString;

        using (SqlConnection c = new SqlConnection(conn))
        {
            c.Open();

            string sql = @"
            SELECT TOP 1
                name,
                description,
                locationname,
                lastinventoried,
                lastobservedtime,
                text6,
                text8,
                text12
            FROM dbo.asset WITH (NOLOCK)
            WHERE rfidtag = @epc
               OR name = @epc
               OR text12 = @epc
               OR text3 = @epc";

            using (SqlCommand cmd = new SqlCommand(sql, c))
            {
                cmd.Parameters.AddWithValue("@epc", epc);

                using (SqlDataReader r = cmd.ExecuteReader())
                {
                    if (r.Read())
                    {
                        Response.Write("<b>Asset:</b> " + r["name"] + "<br/>");
                        Response.Write("<b>Description:</b> " + r["description"] + "<br/>");
                        Response.Write("<b>Location:</b> " + r["locationname"] + "<br/>");
                        Response.Write("<b>Last Inventoried:</b> " + r["lastinventoried"] + "<br/>");
                        Response.Write("<b>Last Observed:</b> " + r["lastobservedtime"] + "<br/>");
                    }
                    else
                    {
                        Response.Write("Asset not found.");
                    }
                }
            }
        }
    }
}

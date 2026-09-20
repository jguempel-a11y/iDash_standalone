<%@ WebHandler Language="C#" Class="VAssetApi" %>

using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Web;
using System.Configuration;
using System.Web.SessionState;
using System.Web.Script.Serialization;

public class VAssetApi : IHttpHandler, IRequiresSessionState
{
    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "application/json";

        // ── Security Check: Require authenticated session ──
        bool isLoggedIn = context.Session != null && (
            (context.Session["IsAdminAuthenticated"] != null && (bool)context.Session["IsAdminAuthenticated"]) ||
            context.Session["IdashUserRole"] != null ||
            (context.User != null && context.User.Identity != null && context.User.Identity.IsAuthenticated)
        );

        if (!isLoggedIn)
        {
            context.Response.StatusCode = 401;
            context.Response.Write("{\"error\":\"Authentication required.\"}");
            return;
        }

        using (SqlConnection cn = new SqlConnection(
            ConfigurationManager.ConnectionStrings["iDash"].ConnectionString))
        {
            DataTable dt = VAssetData.GetAssets(500);
            using (SqlDataAdapter da = new SqlDataAdapter("SELECT * FROM dbo.v_asset", cn))
            {
                da.Fill(dt);
            }

            var rows = new List<Dictionary<string, object>>();
            foreach (DataRow dr in dt.Rows)
            {
                var row = new Dictionary<string, object>();
                foreach (DataColumn col in dt.Columns)
                {
                    row[col.ColumnName] = dr[col] == DBNull.Value ? null : dr[col];
                }
                rows.Add(row);
            }

            var jss = new JavaScriptSerializer();
            jss.MaxJsonLength = int.MaxValue;
            context.Response.Write(jss.Serialize(rows));
        }
    }

    public bool IsReusable { get { return false; } }
}

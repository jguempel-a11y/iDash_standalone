using System;
using System.Data;
using System.Data.SqlClient;
using System.Configuration;

public static class VAssetData
{
    public static DataTable GetAssets(int maxRows)
    {
        using (SqlConnection cn = new SqlConnection(
            ConfigurationManager.ConnectionStrings["iDash"].ConnectionString))
        {
            SqlDataAdapter da = new SqlDataAdapter(
                "SELECT TOP " + maxRows + " * FROM dbo.v_asset ORDER BY id DESC",
                cn);

            DataTable dt = new DataTable();
            da.Fill(dt);
            return dt;
        }
    }
}

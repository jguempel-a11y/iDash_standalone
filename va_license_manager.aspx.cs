using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.IO;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;

public partial class va_license_manager : Page
{
    private string ConnStr
    {
        get
        {
            foreach (ConnectionStringSettings css in ConfigurationManager.ConnectionStrings)
                if (css.Name != "LocalSqlServer" && !string.IsNullOrEmpty(css.ConnectionString))
                    return css.ConnectionString;
            return "";
        }
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        // ── Authentication & RBAC Guard ─────────────────────────────
        bool isLoggedIn = Session["IsAdminAuthenticated"] != null && (bool)Session["IsAdminAuthenticated"];
        string role = Convert.ToString(Session["IdashUserRole"]);
        var tiles = Session["IdashTileAccess"] as List<string>;
        bool hasAccess = isLoggedIn && UserManager.CanAccessTile(role, tiles, "admin_license_manager");

        string action = Request.QueryString["action"];
        if (action == "api" || action == "downloadCart")
        {
            if (!isLoggedIn)
            {
                Response.StatusCode = 401;
                Response.ContentType = "application/json";
                Response.Write("{\"error\":\"Authentication required.\"}");
                Response.End();
                return;
            }
            if (!hasAccess)
            {
                Response.StatusCode = 403;
                Response.ContentType = "application/json";
                Response.Write("{\"error\":\"Access denied: Administrator privileges required.\"}");
                Response.End();
                return;
            }
        }
        else
        {
            if (!isLoggedIn)
            {
                Response.Redirect("index.aspx?err=auth");
                return;
            }
            if (!hasAccess)
            {
                Response.Redirect("index.aspx?err=access");
                return;
            }

            // Redirect browser traffic to consolidated License Management in Site Config
            Response.Redirect("va_site_config.aspx#sec-licenses");
            return;
        }

        if (action == "downloadCart" && !string.IsNullOrEmpty(Request.QueryString["id"]))
        {
            DownloadCartKey(Request.QueryString["id"]);
            return;
        }

        if (action == "api")
        {
            Response.ContentType = "application/json";
            var js = new JavaScriptSerializer();
            string cmd = Request.QueryString["cmd"] ?? "";

            // Enforce POST for state-changing operations
            if (cmd == "deleteReader" || cmd == "deleteServer" || cmd == "deleteUser" ||
                cmd == "deleteScanner" || cmd == "deleteMqtt" || cmd == "deleteCart" || cmd == "saveCart")
            {
                if (Request.HttpMethod != "POST")
                {
                    Response.StatusCode = 405;
                    Response.Write(js.Serialize(new { error = "POST method required for state-changing operations." }));
                    Response.End();
                    return;
                }
            }

            string result;

            switch (cmd)
            {
                case "getAll":        result = GetAll(); break;
                case "deleteReader":  result = DeleteItem("reader", "antenna", "readerid"); break;
                case "deleteServer":  result = DeleteItem("serverstatus", null, null); break;
                case "deleteUser":    result = DeleteItem("sysuser", null, null); break;
                case "deleteScanner": result = DeleteItem("scanner", null, null); break;
                case "deleteMqtt":    result = DeleteItem("mqttclient", null, null); break;
                case "getCarts":      result = GetCarts(); break;
                case "saveCart":      result = SaveCart(); break;
                case "deleteCart":    result = DeleteCart(); break;
                default: result = js.Serialize(new { error = "Unknown: " + cmd }); break;
            }

            Response.Write(result);
            Response.End();
        }
    }

    private string GetAll()
    {
        var js = new JavaScriptSerializer();
        var readers = new List<object>();
        var servers = new List<object>();
        var users = new List<object>();
        var scanners = new List<object>();
        var mqttClients = new List<object>();

        using (var cn = new SqlConnection(ConnStr))
        {
            cn.Open();

            // Readers
            using (var cmd = new SqlCommand(
                @"SELECT r.id, r.name, r.readermodel, r.ipaddress, r.lastseen, r.companyid,
                         l.name as locationName, c.name as companyName
                  FROM reader r
                  LEFT JOIN location l ON r.locationid = l.id
                  LEFT JOIN company c ON r.companyid = c.id
                  ORDER BY r.name", cn))
            using (var rdr = cmd.ExecuteReader())
            {
                while (rdr.Read())
                {
                    readers.Add(new
                    {
                        id = rdr["id"],
                        name = Safe(rdr, "name"),
                        model = Safe(rdr, "readermodel"),
                        ip = Safe(rdr, "ipaddress"),
                        lastSeen = rdr["lastseen"] != DBNull.Value ? ((DateTimeOffset)rdr["lastseen"]).ToString("o") : null,
                        location = Safe(rdr, "locationName"),
                        site = Safe(rdr, "companyName")
                    });
                }
            }

            // Server status
            using (var cmd = new SqlCommand(
                "SELECT id, name, servertype, version, lastseen FROM serverstatus ORDER BY id", cn))
            using (var rdr = cmd.ExecuteReader())
            {
                while (rdr.Read())
                {
                    servers.Add(new
                    {
                        id = rdr["id"],
                        name = Safe(rdr, "name"),
                        serverType = Safe(rdr, "servertype"),
                        version = Safe(rdr, "version"),
                        lastSeen = rdr["lastseen"] != DBNull.Value ? ((DateTimeOffset)rdr["lastseen"]).ToString("o") : null
                    });
                }
            }

            // Scanner users (sysuser)
            using (var cmd = new SqlCommand(
                @"SELECT u.id, u.username, u.firstname, u.lastname, u.usertype, u.companyid,
                         c.name as companyName
                  FROM sysuser u
                  LEFT JOIN company c ON u.companyid = c.id
                  ORDER BY u.username", cn))
            using (var rdr = cmd.ExecuteReader())
            {
                while (rdr.Read())
                {
                    string fn = Safe(rdr, "firstname");
                    string ln = Safe(rdr, "lastname");
                    string full = ((fn + " " + ln).Trim());
                    users.Add(new
                    {
                        id = rdr["id"],
                        username = Safe(rdr, "username"),
                        fullName = string.IsNullOrEmpty(full) ? null : full,
                        userType = Safe(rdr, "usertype"),
                        site = Safe(rdr, "companyName")
                    });
                }
            }

            // Scanners (handheld devices — reads from dbo.sysuser)
            using (var cmd = new SqlCommand(
                "SELECT id, deviceid, companyname, inactive, description, lastseen FROM scanner ORDER BY id", cn))
            using (var rdr = cmd.ExecuteReader())
            {
                while (rdr.Read())
                {
                    scanners.Add(new
                    {
                        id = rdr["id"],
                        deviceId = Safe(rdr, "deviceid"),
                        site = Safe(rdr, "companyname"),
                        inactive = rdr["inactive"] != DBNull.Value && (bool)rdr["inactive"],
                        description = Safe(rdr, "description"),
                        lastSeen = rdr["lastseen"] != DBNull.Value ? ((DateTimeOffset)rdr["lastseen"]).ToString("o") : null
                    });
                }
            }

            // MQTT Clients
            using (var cmd = new SqlCommand(
                @"SELECT m.id, m.username, m.companyid, c.name as companyName
                  FROM mqttclient m
                  LEFT JOIN company c ON m.companyid = c.id
                  ORDER BY m.id", cn))
            using (var rdr = cmd.ExecuteReader())
            {
                while (rdr.Read())
                {
                    mqttClients.Add(new
                    {
                        id = rdr["id"],
                        username = Safe(rdr, "username"),
                        site = Safe(rdr, "companyName")
                    });
                }
            }
        }

        return js.Serialize(new { readers, servers, users, scanners, mqttClients });
    }

    private string DeleteItem(string table, string childTable, string childFk)
    {
        var js = new JavaScriptSerializer();
        Request.InputStream.Position = 0;
        string body;
        using (var sr = new StreamReader(Request.InputStream)) body = sr.ReadToEnd();
        var data = js.Deserialize<Dictionary<string, object>>(body);
        int id = Convert.ToInt32(data["id"]);

        try
        {
            using (var cn = new SqlConnection(ConnStr))
            {
                cn.Open();
                // Delete children first (e.g. antennas for readers)
                if (!string.IsNullOrEmpty(childTable) && !string.IsNullOrEmpty(childFk))
                {
                    using (var cmd = new SqlCommand(
                        string.Format("DELETE FROM {0} WHERE {1} = @id", childTable, childFk), cn))
                    {
                        cmd.Parameters.AddWithValue("@id", id);
                        cmd.ExecuteNonQuery();
                    }
                }
                using (var cmd = new SqlCommand(
                    string.Format("DELETE FROM {0} WHERE id = @id", table), cn))
                {
                    cmd.Parameters.AddWithValue("@id", id);
                    int rows = cmd.ExecuteNonQuery();

                    string username = Convert.ToString(Session["IdashUsername"]) ?? "admin";
                    string clientIp = Request.UserHostAddress;
                    LoginAuditHelper.LogAdminAction(username, clientIp, "LicenseItemDelete", "Table: " + table + ", ID: " + id + ", DeletedRows: " + rows);

                    return js.Serialize(new { success = true, deleted = rows });
                }
            }
        }
        catch (Exception ex)
        {
            return js.Serialize(new { error = ex.Message });
        }
    }

    private static string Safe(SqlDataReader rdr, string col)
    {
        try { return rdr[col] != DBNull.Value ? rdr[col].ToString() : ""; }
        catch { return ""; }
    }

    private string CartLicensesFilePath
    {
        get { return Server.MapPath("~/App_Data/cart_licenses.json"); }
    }

    private string GetCarts()
    {
        try
        {
            if (!File.Exists(CartLicensesFilePath))
                return "[]";
            return File.ReadAllText(CartLicensesFilePath, System.Text.Encoding.UTF8);
        }
        catch (Exception ex)
        {
            return new JavaScriptSerializer().Serialize(new { error = ex.Message });
        }
    }

    private string SaveCart()
    {
        var js = new JavaScriptSerializer();
        try
        {
            string body;
            using (var reader = new StreamReader(Request.InputStream))
                body = reader.ReadToEnd();

            var item = js.Deserialize<Dictionary<string, object>>(body);
            if (item == null) return js.Serialize(new { error = "Invalid payload" });

            List<Dictionary<string, object>> list = new List<Dictionary<string, object>>();
            if (File.Exists(CartLicensesFilePath))
            {
                string existingJson = File.ReadAllText(CartLicensesFilePath, System.Text.Encoding.UTF8);
                list = js.Deserialize<List<Dictionary<string, object>>>(existingJson) ?? new List<Dictionary<string, object>>();
            }

            string id = item.ContainsKey("id") && item["id"] != null ? item["id"].ToString().Trim() : "";
            if (string.IsNullOrEmpty(id))
            {
                id = "cart-" + Guid.NewGuid().ToString("N").Substring(0, 8);
                item["id"] = id;
                list.Add(item);
            }
            else
            {
                int idx = list.FindIndex(x => x.ContainsKey("id") && x["id"] != null && x["id"].ToString() == id);
                if (idx >= 0)
                    list[idx] = item;
                else
                    list.Add(item);
            }

            string updatedJson = js.Serialize(list);
            File.WriteAllText(CartLicensesFilePath, updatedJson, System.Text.Encoding.UTF8);

            string username = Convert.ToString(Session["IdashUsername"]) ?? "admin";
            string clientIp = Request.UserHostAddress;
            LoginAuditHelper.LogAdminAction(username, clientIp, "CartLicenseSave", "ID: " + id);

            return js.Serialize(new { success = true, id = id });
        }
        catch (Exception ex)
        {
            return js.Serialize(new { error = ex.Message });
        }
    }

    private string DeleteCart()
    {
        var js = new JavaScriptSerializer();
        try
        {
            string id = Request.QueryString["id"] ?? "";
            if (string.IsNullOrEmpty(id))
            {
                Request.InputStream.Position = 0;
                using (var sr = new StreamReader(Request.InputStream))
                {
                    string b = sr.ReadToEnd();
                    if (!string.IsNullOrEmpty(b))
                    {
                        var data = js.Deserialize<Dictionary<string, object>>(b);
                        if (data != null && data.ContainsKey("id") && data["id"] != null)
                            id = data["id"].ToString();
                    }
                }
            }
            if (string.IsNullOrEmpty(id)) return js.Serialize(new { error = "Missing cart ID" });

            if (!File.Exists(CartLicensesFilePath)) return js.Serialize(new { success = true });

            string existingJson = File.ReadAllText(CartLicensesFilePath, System.Text.Encoding.UTF8);
            var list = js.Deserialize<List<Dictionary<string, object>>>(existingJson) ?? new List<Dictionary<string, object>>();
            list.RemoveAll(x => x.ContainsKey("id") && x["id"] != null && x["id"].ToString() == id);

            File.WriteAllText(CartLicensesFilePath, js.Serialize(list), System.Text.Encoding.UTF8);

            string username = Convert.ToString(Session["IdashUsername"]) ?? "admin";
            string clientIp = Request.UserHostAddress;
            LoginAuditHelper.LogAdminAction(username, clientIp, "CartLicenseDelete", "ID: " + id);

            return js.Serialize(new { success = true });
        }
        catch (Exception ex)
        {
            return js.Serialize(new { error = ex.Message });
        }
    }

    private void DownloadCartKey(string id)
    {
        try
        {
            if (!File.Exists(CartLicensesFilePath)) return;
            var js = new JavaScriptSerializer();
            var list = js.Deserialize<List<Dictionary<string, object>>>(File.ReadAllText(CartLicensesFilePath, System.Text.Encoding.UTF8));
            var cart = list.Find(x => x.ContainsKey("id") && x["id"] != null && x["id"].ToString() == id);
            if (cart != null && cart.ContainsKey("idashLicenseKey") && cart["idashLicenseKey"] != null)
            {
                string key = cart["idashLicenseKey"].ToString().Trim();
                string name = cart.ContainsKey("name") && cart["name"] != null ? cart["name"].ToString().Trim().ToLower().Replace(" ", "_") : "cart";
                string filename = name + ".idashlic";

                string username = Convert.ToString(Session["IdashUsername"]) ?? "admin";
                string clientIp = Request.UserHostAddress;
                LoginAuditHelper.LogAdminAction(username, clientIp, "CartLicenseDownload", "ID: " + id + ", File: " + filename);

                Response.Clear();
                Response.ContentType = "application/octet-stream";
                Response.AddHeader("Content-Disposition", "attachment; filename=\"" + filename + "\"");
                Response.Write(key);
                Response.Flush();
                Response.End();
            }
        }
        catch { }
    }
}

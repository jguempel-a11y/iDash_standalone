using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Configuration;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.Services;
using System.Web.Script.Services;
using System.Web.Script.Serialization;
using System.Text;
using System.IO;

public partial class va_mqtt_config : System.Web.UI.Page
{
    private string ConnStr
    {
        get
        {
            var cs = ConfigurationManager.ConnectionStrings["iDash"];
            return (cs == null) ? "" : cs.ConnectionString;
        }
    }

    // Path to appsettings.json for the Print Server WebClient
    private static string AppSettingsPath
    {
        get { return Path.Combine(HttpContext.Current.Server.MapPath("~"), "..", "appsettings.json"); }
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            LoadMqttSettings();
            LoadMqttClients();
            LoadSites();
        }
    }

    // ===================================================================
    // Load MQTT settings from applicationsetting table
    // ===================================================================
    private void LoadMqttSettings()
    {
        try
        {
            using (var conn = new SqlConnection(ConnStr))
            {
                conn.Open();
                string sql = @"SELECT mqttenabled, mqttlocation, mqttusername, mqttpassword,
                               enableglobalalarmmessages, enableglobaleventmessages,
                               enableglobalgatewaymessages, enableglobalsensorreadingmessages,
                               enableglobaltagmovementmessages, enableglobaltagobservationmessages
                               FROM applicationsetting";
                using (var cmd = new SqlCommand(sql, conn))
                using (var rdr = cmd.ExecuteReader())
                {
                    if (rdr.Read())
                    {
                        ChkMqttEnabled.Checked = rdr["mqttenabled"] != DBNull.Value && Convert.ToBoolean(rdr["mqttenabled"]);
                        TxtBrokerLocation.Text = (rdr["mqttlocation"] != DBNull.Value ? rdr["mqttlocation"].ToString() : "");
                        TxtGatewayUser.Text = (rdr["mqttusername"] != DBNull.Value ? rdr["mqttusername"].ToString() : "");
                        TxtGatewayPass.Text = (rdr["mqttpassword"] != DBNull.Value ? rdr["mqttpassword"].ToString() : "");
                        ChkSubAlarms.Checked = rdr["enableglobalalarmmessages"] != DBNull.Value && Convert.ToBoolean(rdr["enableglobalalarmmessages"]);
                        ChkSubEvents.Checked = rdr["enableglobaleventmessages"] != DBNull.Value && Convert.ToBoolean(rdr["enableglobaleventmessages"]);
                        ChkSubGateway.Checked = rdr["enableglobalgatewaymessages"] != DBNull.Value && Convert.ToBoolean(rdr["enableglobalgatewaymessages"]);
                        ChkSubSensor.Checked = rdr["enableglobalsensorreadingmessages"] != DBNull.Value && Convert.ToBoolean(rdr["enableglobalsensorreadingmessages"]);
                        ChkSubMoves.Checked = rdr["enableglobaltagmovementmessages"] != DBNull.Value && Convert.ToBoolean(rdr["enableglobaltagmovementmessages"]);
                        ChkSubObs.Checked = rdr["enableglobaltagobservationmessages"] != DBNull.Value && Convert.ToBoolean(rdr["enableglobaltagobservationmessages"]);
                    }
                }
            }

            // Load appsettings.json values
            string path = Path.GetFullPath(AppSettingsPath);
            if (File.Exists(path))
            {
                string json = File.ReadAllText(path);
                var jss = new JavaScriptSerializer();
                var settings = jss.Deserialize<Dictionary<string, object>>(json);
                if (settings.ContainsKey("ConfigSettings"))
                {
                    var config = (Dictionary<string, object>)settings["ConfigSettings"];
                    TxtMqttServer.Text = config.ContainsKey("MqttServer") ? (config["MqttServer"] != null ? config["MqttServer"].ToString() : "") : "";
                    TxtMqttPort.Text = config.ContainsKey("MqttServerPort") ? (config["MqttServerPort"] != null ? config["MqttServerPort"].ToString() : "8883") : "8883";
                    TxtPrintUser.Text = config.ContainsKey("PrintClientUsername") ? (config["PrintClientUsername"] != null ? config["PrintClientUsername"].ToString() : "") : "";
                    TxtPrintPass.Text = config.ContainsKey("PrintClientPassword") ? (config["PrintClientPassword"] != null ? config["PrintClientPassword"].ToString() : "") : "";
                }
            }

            LitStatus.Text = "<div class='status-ok'>Settings loaded.</div>";
        }
        catch (Exception ex)
        {
            LitStatus.Text = "<div class='status-err'>Error: " + Server.HtmlEncode(ex.Message) + "</div>";
        }
    }

    // ===================================================================
    // Save MQTT settings
    // ===================================================================
    protected void BtnSaveSettings_Click(object sender, EventArgs e)
    {
        try
        {
            using (var conn = new SqlConnection(ConnStr))
            {
                conn.Open();
                string sql = @"UPDATE applicationsetting 
                               SET mqttenabled = @enabled,
                                   mqttlocation = @location,
                                   mqttusername = @username,
                                   mqttpassword = @password,
                                   enableglobalalarmmessages = @subAlarms,
                                   enableglobaleventmessages = @subEvents,
                                   enableglobalgatewaymessages = @subGateway,
                                   enableglobalsensorreadingmessages = @subSensor,
                                   enableglobaltagmovementmessages = @subMoves,
                                   enableglobaltagobservationmessages = @subObs";
                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@enabled", ChkMqttEnabled.Checked);
                    cmd.Parameters.AddWithValue("@location", TxtBrokerLocation.Text.Trim());
                    cmd.Parameters.AddWithValue("@username", TxtGatewayUser.Text.Trim());
                    cmd.Parameters.AddWithValue("@password", TxtGatewayPass.Text.Trim());
                    cmd.Parameters.AddWithValue("@subAlarms", ChkSubAlarms.Checked);
                    cmd.Parameters.AddWithValue("@subEvents", ChkSubEvents.Checked);
                    cmd.Parameters.AddWithValue("@subGateway", ChkSubGateway.Checked);
                    cmd.Parameters.AddWithValue("@subSensor", ChkSubSensor.Checked);
                    cmd.Parameters.AddWithValue("@subMoves", ChkSubMoves.Checked);
                    cmd.Parameters.AddWithValue("@subObs", ChkSubObs.Checked);
                    cmd.ExecuteNonQuery();
                }
            }

            // Update appsettings.json
            string path = Path.GetFullPath(AppSettingsPath);
            if (File.Exists(path))
            {
                string json = File.ReadAllText(path);
                var jss = new JavaScriptSerializer();
                var settings = jss.Deserialize<Dictionary<string, object>>(json);
                if (settings.ContainsKey("ConfigSettings"))
                {
                    var config = (Dictionary<string, object>)settings["ConfigSettings"];
                    config["MqttServer"] = TxtMqttServer.Text.Trim();
                    int port;
                    config["MqttServerPort"] = int.TryParse(TxtMqttPort.Text.Trim(), out port) ? port : 8883;
                    config["PrintClientUsername"] = TxtPrintUser.Text.Trim();
                    config["PrintClientPassword"] = TxtPrintPass.Text.Trim();
                    settings["ConfigSettings"] = config;
                    
                    // Write back with formatting
                    string output = new JavaScriptSerializer { MaxJsonLength = 5000000 }.Serialize(settings);
                    // Pretty-print (basic)
                    output = FormatJson(output);
                    File.WriteAllText(path, output);
                }
            }

            LitStatus.Text = "<div class='status-ok'>&#10003; MQTT settings saved successfully.</div>";
            LoadMqttSettings();
        }
        catch (Exception ex)
        {
            LitStatus.Text = "<div class='status-err'>Error saving: " + Server.HtmlEncode(ex.Message) + "</div>";
        }
    }

    // ===================================================================
    // Load MQTT clients grid
    // ===================================================================
    private void LoadMqttClients()
    {
        try
        {
            using (var conn = new SqlConnection(ConnStr))
            {
                conn.Open();
                string sql = @"SELECT m.id, m.username, m.password, m.companyid,
                                      c.name AS SiteName,
                                      m.accessalarms, m.accessevents, m.accessgatewaymessages,
                                      m.accesstagmovements, m.accesstagobservations, m.accessvtagsensors
                               FROM mqttclient m
                               LEFT JOIN company c ON c.id = m.companyid
                               ORDER BY c.name, m.username";
                var dt = new DataTable();
                using (var da = new SqlDataAdapter(new SqlCommand(sql, conn)))
                {
                    da.Fill(dt);
                }
                Session["MqttClientsDT"] = dt;
                GridClients.DataSource = dt;
                GridClients.DataBind();

                LitClientCount.Text = dt.Rows.Count > 0
                    ? string.Format("<span class='count-badge'>{0} client(s)</span>", dt.Rows.Count)
                    : "<span class='count-badge empty'>No clients configured</span>";
            }
        }
        catch (Exception ex)
        {
            LitClientCount.Text = "<div class='status-err'>" + Server.HtmlEncode(ex.Message) + "</div>";
        }
    }

    protected override void OnPreRender(EventArgs e)
    {
        base.OnPreRender(e);
        if (GridClients != null && GridClients.HeaderRow != null)
            GridClients.HeaderRow.TableSection = TableRowSection.TableHeader;
    }

    // ===================================================================
    // Load sites for dropdown
    // ===================================================================
    private void LoadSites()
    {
        try
        {
            using (var conn = new SqlConnection(ConnStr))
            {
                conn.Open();
                string sql = "SELECT id, name FROM company ORDER BY name";
                using (var cmd = new SqlCommand(sql, conn))
                using (var rdr = cmd.ExecuteReader())
                {
                    DdlSite.DataSource = rdr;
                    DdlSite.DataTextField = "name";
                    DdlSite.DataValueField = "id";
                    DdlSite.DataBind();
                }
                DdlSite.Items.Insert(0, new ListItem("-- Select Site --", "0"));
            }
        }
        catch { }
    }

    // ===================================================================
    // Add MQTT Client
    // ===================================================================
    protected void BtnAddClient_Click(object sender, EventArgs e)
    {
        try
        {
            if (DdlSite.SelectedValue == "0" || string.IsNullOrWhiteSpace(TxtClientUser.Text))
            {
                LitClientStatus.Text = "<div class='status-err'>Site and Username are required.</div>";
                return;
            }

            using (var conn = new SqlConnection(ConnStr))
            {
                conn.Open();
                string sql = @"INSERT INTO mqttclient 
                               (username, password, companyid, accessalarms, accessevents, 
                                accessgatewaymessages, accesstagmovements, accesstagobservations, accessvtagsensors)
                               VALUES (@user, @pass, @site, @alarms, @events, @gateway, @moves, @obs, @sensors)";
                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@user", TxtClientUser.Text.Trim());
                    cmd.Parameters.AddWithValue("@pass", TxtClientPass.Text.Trim());
                    cmd.Parameters.AddWithValue("@site", int.Parse(DdlSite.SelectedValue));
                    cmd.Parameters.AddWithValue("@alarms", ChkAlarms.Checked);
                    cmd.Parameters.AddWithValue("@events", ChkEvents.Checked);
                    cmd.Parameters.AddWithValue("@gateway", ChkGateway.Checked);
                    cmd.Parameters.AddWithValue("@moves", ChkMoves.Checked);
                    cmd.Parameters.AddWithValue("@obs", ChkObs.Checked);
                    cmd.Parameters.AddWithValue("@sensors", ChkSensors.Checked);
                    cmd.ExecuteNonQuery();
                }
            }

            LitClientStatus.Text = "<div class='status-ok'>&#10003; Client added.</div>";
            TxtClientUser.Text = "";
            TxtClientPass.Text = "";
            LoadMqttClients();
        }
        catch (Exception ex)
        {
            LitClientStatus.Text = "<div class='status-err'>Error: " + Server.HtmlEncode(ex.Message) + "</div>";
        }
    }

    // ===================================================================
    // Bulk create clients (one per site)
    // ===================================================================
    protected void BtnBulkCreate_Click(object sender, EventArgs e)
    {
        try
        {
            int created = 0;
            using (var conn = new SqlConnection(ConnStr))
            {
                conn.Open();

                // Get all sites
                var sites = new List<KeyValuePair<int, string>>();
                using (var cmd = new SqlCommand("SELECT id, name FROM company ORDER BY name", conn))
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                        sites.Add(new KeyValuePair<int, string>(rdr.GetInt32(0), rdr.GetString(1)));
                }

                // Check existing clients
                var existing = new HashSet<int>();
                using (var cmd = new SqlCommand("SELECT companyid FROM mqttclient", conn))
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                        if (!rdr.IsDBNull(0)) existing.Add(rdr.GetInt32(0));
                }

                foreach (var site in sites)
                {
                    if (existing.Contains(site.Key)) continue;
                    
                    // Generate username from site name (sanitize)
                    string username = "mqtt_" + System.Text.RegularExpressions.Regex.Replace(
                        site.Value.ToLower(), @"[^a-z0-9]", "_");
                    string password = GeneratePassword(12);

                    string sql = @"INSERT INTO mqttclient 
                                   (username, password, companyid, accessalarms, accessevents, 
                                    accessgatewaymessages, accesstagmovements, accesstagobservations, accessvtagsensors)
                                   VALUES (@user, @pass, @site, 1, 1, 1, 1, 1, 1)";
                    using (var cmd = new SqlCommand(sql, conn))
                    {
                        cmd.Parameters.AddWithValue("@user", username);
                        cmd.Parameters.AddWithValue("@pass", password);
                        cmd.Parameters.AddWithValue("@site", site.Key);
                        cmd.ExecuteNonQuery();
                        created++;
                    }
                }
            }

            LitClientStatus.Text = string.Format("<div class='status-ok'>&#10003; {0} client(s) created for sites without existing clients.</div>", created);
            LoadMqttClients();
        }
        catch (Exception ex)
        {
            LitClientStatus.Text = "<div class='status-err'>Error: " + Server.HtmlEncode(ex.Message) + "</div>";
        }
    }

    // ===================================================================
    // Delete MQTT Client
    // ===================================================================
    protected void BtnDeleteClient_Click(object sender, EventArgs e)
    {
        try
        {
            string idStr = HidDeleteId.Value;
            int id;
            if (!int.TryParse(idStr, out id) || id <= 0)
            {
                LitClientStatus.Text = "<div class='status-err'>Invalid client ID.</div>";
                return;
            }

            using (var conn = new SqlConnection(ConnStr))
            {
                conn.Open();
                using (var cmd = new SqlCommand("DELETE FROM mqttclient WHERE id = @id", conn))
                {
                    cmd.Parameters.AddWithValue("@id", id);
                    cmd.ExecuteNonQuery();
                }
            }

            LitClientStatus.Text = "<div class='status-ok'>&#10003; Client deleted.</div>";
            LoadMqttClients();
        }
        catch (Exception ex)
        {
            LitClientStatus.Text = "<div class='status-err'>Error: " + Server.HtmlEncode(ex.Message) + "</div>";
        }
    }


    // ===================================================================
    // Helpers
    // ===================================================================
    private static string GeneratePassword(int length)
    {
        const string chars = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghkmnpqrstuvwxyz23456789!@#$";
        var rng = new System.Security.Cryptography.RNGCryptoServiceProvider();
        var bytes = new byte[length];
        rng.GetBytes(bytes);
        var sb = new StringBuilder(length);
        foreach (var b in bytes)
            sb.Append(chars[b % chars.Length]);
        return sb.ToString();
    }

    private static string FormatJson(string json)
    {
        // Basic JSON pretty-printer
        var sb = new StringBuilder();
        int indent = 0;
        bool inString = false;
        foreach (char c in json)
        {
            if (c == '"' && (sb.Length == 0 || sb[sb.Length - 1] != '\\'))
                inString = !inString;

            if (!inString)
            {
                if (c == '{' || c == '[')
                {
                    sb.Append(c);
                    sb.AppendLine();
                    indent++;
                    sb.Append(new string(' ', indent * 2));
                }
                else if (c == '}' || c == ']')
                {
                    sb.AppendLine();
                    indent--;
                    sb.Append(new string(' ', indent * 2));
                    sb.Append(c);
                }
                else if (c == ',')
                {
                    sb.Append(c);
                    sb.AppendLine();
                    sb.Append(new string(' ', indent * 2));
                }
                else if (c == ':')
                {
                    sb.Append(": ");
                }
                else
                {
                    sb.Append(c);
                }
            }
            else
            {
                sb.Append(c);
            }
        }
        return sb.ToString();
    }
}

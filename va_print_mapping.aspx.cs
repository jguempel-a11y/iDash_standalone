using System;
using System.Collections.Generic;
using System.IO;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI.WebControls;
using System.Linq;

public class PrintMapItem
{
    public long TemplateID { get; set; }
    public string TargetType { get; set; } // "Default", "Service", "Client"
    public string TargetValue { get; set; }
}

public partial class va_print_mapping : System.Web.UI.Page
{
    private string ConfigPath
    {
        get { return Server.MapPath("print_mapping_config.json"); }
    }

    private string ConnStr
    {
        get 
        { 
            var setting = System.Configuration.ConfigurationManager.ConnectionStrings["iDash"];
            return setting != null ? setting.ConnectionString : null;
        }
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            BindTemplates();
            BindPrintClients();
            BindGrid();
        }
    }

    private void BindTemplates()
    {
        try
        {
            DdlTemplateID.Items.Clear();
            DdlTemplateID.Items.Add(new ListItem("-- Select a Print Template --", ""));
            
            if (string.IsNullOrEmpty(ConnStr)) return;

            using (var con = new System.Data.SqlClient.SqlConnection(ConnStr))
            {
                con.Open();
                using (var cmd = new System.Data.SqlClient.SqlCommand("SELECT id, name FROM template ORDER BY name", con))
                using (var r = cmd.ExecuteReader())
                {
                    while (r.Read())
                    {
                        string id = r["id"].ToString();
                        string name = r["name"].ToString();
                        DdlTemplateID.Items.Add(new ListItem(name + " (Template ID: " + id + ")", id));
                    }
                }
            }
        }
        catch (Exception ex)
        {
            LitMessage.Text = "<div class='err'>Error loading templates: " + ex.Message + "</div>";
        }
    }

    private void BindPrintClients()
    {
        try
        {
            DdlTargetClient.Items.Clear();
            DdlTargetClient.Items.Add(new ListItem("-- Select Print Client --", ""));
            
            if (string.IsNullOrEmpty(ConnStr)) return;

            using (var con = new System.Data.SqlClient.SqlConnection(ConnStr))
            {
                con.Open();
                using (var cmd = new System.Data.SqlClient.SqlCommand("SELECT username FROM printclient UNION SELECT username FROM mqttclient ORDER BY username", con))
                using (var r = cmd.ExecuteReader())
                {
                    while (r.Read())
                    {
                        string username = r["username"].ToString();
                        DdlTargetClient.Items.Add(new ListItem(username, username));
                    }
                }
            }
        }
        catch (Exception ex)
        {
            LitMessage.Text += " <div class='err'>Error loading Print Clients: " + ex.Message + "</div>";
        }
    }

    private Dictionary<string, PrintMapItem> LoadConfig()
    {
        if (File.Exists(ConfigPath))
        {
            string json = File.ReadAllText(ConfigPath);
            if (!string.IsNullOrWhiteSpace(json) && json.Length > 2)
            {
                try
                {
                    return new JavaScriptSerializer().Deserialize<Dictionary<string, PrintMapItem>>(json);
                }
                catch { }
            }
        }
        return new Dictionary<string, PrintMapItem>(StringComparer.OrdinalIgnoreCase);
    }

    private void SaveConfig(Dictionary<string, PrintMapItem> config)
    {
        string json = new JavaScriptSerializer().Serialize(config);
        File.WriteAllText(ConfigPath, json);
    }

    private void BindGrid()
    {
        try
        {
            var config = LoadConfig();
            
            var templateNames = new Dictionary<long, string>();
            try {
                if (!string.IsNullOrEmpty(ConnStr)) {
                    using (var con = new System.Data.SqlClient.SqlConnection(ConnStr))
                    {
                        con.Open();
                        using (var cmd = new System.Data.SqlClient.SqlCommand("SELECT id, name FROM template", con))
                        using (var r = cmd.ExecuteReader())
                        {
                            while (r.Read())
                            {
                                templateNames[Convert.ToInt64(r["id"])] = r["name"].ToString();
                            }
                        }
                    }
                }
            } catch { }

            var dt = new System.Data.DataTable();
            dt.Columns.Add("Id", typeof(string));
            dt.Columns.Add("TagType", typeof(string));
            dt.Columns.Add("TemplateID", typeof(long));
            dt.Columns.Add("TemplateName", typeof(string));
            dt.Columns.Add("Routing", typeof(string));

            foreach (var kvp in config)
            {
                string tName = templateNames.ContainsKey(kvp.Value.TemplateID) ? templateNames[kvp.Value.TemplateID] : "(Unknown Template - ID " + kvp.Value.TemplateID + ")";
                
                string routing = "Template Default";
                if (kvp.Value.TargetType == "Service") routing = "Service = " + kvp.Value.TargetValue;
                if (kvp.Value.TargetType == "Client") routing = "Print Client = " + kvp.Value.TargetValue;

                dt.Rows.Add(kvp.Key, kvp.Key, kvp.Value.TemplateID, tName, routing);
            }

            GridMappings.DataSource = dt;
            GridMappings.DataBind();
        }
        catch (Exception ex)
        {
            LitMessage.Text = "<div class='err'>Error loading config: " + ex.Message + "</div>";
        }
    }

    protected void BtnSave_Click(object sender, EventArgs e)
    {
        string tagType = TxtTagType.Text.Trim();
        string tempId = DdlTemplateID.SelectedValue;
        string targetType = DdlTargetType.SelectedValue;
        
        string targetValue = "";
        if (targetType == "Service") targetValue = TxtTargetService.Text.Trim();
        if (targetType == "Client") targetValue = DdlTargetClient.SelectedValue;

        if (string.IsNullOrEmpty(tagType) || string.IsNullOrEmpty(tempId))
        {
            LitMessage.Text = "<div class='err'>Tag Type and Target Template are required.</div>";
            return;
        }

        if (targetType != "Default" && string.IsNullOrEmpty(targetValue))
        {
            LitMessage.Text = "<div class='err'>Please provide a value for the selected Routing Method.</div>";
            return;
        }

        long tId;
        if (!long.TryParse(tempId, out tId))
        {
            LitMessage.Text = "<div class='err'>Template ID must be a valid number.</div>";
            return;
        }

        try
        {
            var config = LoadConfig();
            config[tagType] = new PrintMapItem {
                TemplateID = tId,
                TargetType = targetType,
                TargetValue = targetValue
            };
            SaveConfig(config);

            TxtTagType.Text = "";
            DdlTemplateID.SelectedIndex = 0;
            DdlTargetType.SelectedIndex = 0;
            TxtTargetService.Text = "";
            DdlTargetClient.SelectedIndex = 0;

            LitMessage.Text = "<div class='ok' style='color:#a3ffaa'>Mapping saved successfully to local configuration file!</div>";
            BindTemplates();
            // Refetch clients in case they changed
            BindPrintClients();
            BindGrid();
        }
        catch (Exception ex)
        {
            LitMessage.Text = "<div class='err'>Save error: " + ex.Message + "</div>";
        }
    }

    protected void GridMappings_RowCommand(object sender, GridViewCommandEventArgs e)
    {
        if (e.CommandName == "DeleteRow")
        {
            string tagType = e.CommandArgument.ToString();
            try
            {
                var config = LoadConfig();
                if (config.ContainsKey(tagType))
                {
                    config.Remove(tagType);
                    SaveConfig(config);
                }
                LitMessage.Text = "<div class='ok' style='color:#a3ffaa'>Deleted mapping.</div>";
                BindTemplates();
                BindPrintClients();
                BindGrid();
            }
            catch (Exception ex)
            {
                LitMessage.Text = "<div class='err'>Delete error: " + HttpUtility.HtmlEncode(ex.Message) + "</div>";
            }
        }
    }
}

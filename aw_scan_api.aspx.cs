using System;

public partial class aw_scan_api : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        string epc = Request["epc"];
        string qs = string.IsNullOrEmpty(epc) ? "" : "?epc=" + Server.UrlEncode(epc);
        Response.Redirect("scan_api.aspx" + qs, true);
    }
}

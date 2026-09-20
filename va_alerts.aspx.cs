using System;
using System.Web.UI;

public partial class va_alerts : Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        bool isLoggedIn = Session["IsAdminAuthenticated"] != null && (bool)Session["IsAdminAuthenticated"];
        if (!isLoggedIn)
        {
            Response.Redirect("index.aspx");
            return;
        }
    }
}

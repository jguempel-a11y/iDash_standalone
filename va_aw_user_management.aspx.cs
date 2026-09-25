using System;

public partial class va_aw_user_management : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        Response.RedirectPermanent("va_user_management.aspx", true);
    }
}

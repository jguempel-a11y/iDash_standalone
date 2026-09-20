using System;
using System.IO;

public partial class va_printer_routing : System.Web.UI.Page
{
    string jsonPath = @"C:\idash_prints\printer_routing.json";

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            if (File.Exists(jsonPath))
            {
                TxtJson.Text = File.ReadAllText(jsonPath);
            }
            else
            {
                TxtJson.Text = "{\n  \"iDash_Metal_IQ350.btw\": \"Your First Printer Name Here\",\n  \"iDash_Std_Small.btw\": \"Printronix Auto ID T830 - PGL\"\n}";
            }
        }
    }

    protected void BtnSave_Click(object sender, EventArgs e)
    {
        try
        {
            File.WriteAllText(jsonPath, TxtJson.Text);
            LitMessage.Text = "<div class='alert success'>Master Configuration successfully permanently saved! Your Spooler Script will magically adopt the routes on the very next print payload!</div>";
        }
        catch (Exception ex)
        {
            LitMessage.Text = "<div class='alert error'>Error Saving File: " + ex.Message + "</div>";
        }
    }
}

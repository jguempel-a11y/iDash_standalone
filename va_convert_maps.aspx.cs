using System;
using System.IO;
using System.Web;
using System.Web.UI;
using System.Linq;

public partial class va_convert_maps : Page
{
    public string PdfFilesJson = "[]";

    protected void Page_Load(object sender, EventArgs e)
    {
        // Handle POST save
        if (Request.HttpMethod == "POST" && !string.IsNullOrEmpty(Request.Form["pdf_path"]) && !string.IsNullOrEmpty(Request.Form["img_data"]))
        {
            try
            {
                string pdfRel = Request.Form["pdf_path"];
                if (pdfRel.Contains("..")) return;

                string pdfAbs = Server.MapPath("site_maps/" + pdfRel);
                if (File.Exists(pdfAbs))
                {
                    string imgData = Request.Form["img_data"];
                    string base64 = imgData.Substring(imgData.IndexOf(",") + 1);
                    byte[] bytes = Convert.FromBase64String(base64);

                    string newPngPath = Path.ChangeExtension(pdfAbs, ".png");
                    File.WriteAllBytes(newPngPath, bytes);

                    // Delete PDF after successful rendering extraction
                    File.Delete(pdfAbs);
                    
                    Response.StatusCode = 200;
                    Response.Write("Converted " + Path.GetFileName(newPngPath));
                    Response.End();
                }
            }
            catch(System.Threading.ThreadAbortException)
            {
                // This is thrown natively by Response.End(), so we can safely ignore it.
            }
            catch(Exception ex)
            {
                Response.StatusCode = 500;
                Response.Write(ex.Message);
                Response.End();
            }
            return;
        }

        string mapsPath = Server.MapPath("site_maps");
        if (Directory.Exists(mapsPath))
        {
            var files = Directory.GetFiles(mapsPath, "*.pdf", SearchOption.AllDirectories)
                .Select(f => f.Substring(mapsPath.Length).Replace('\\', '/').TrimStart('/'))
                .Select(f => string.Format("'{0}'", HttpUtility.JavaScriptStringEncode(f)))
                .ToList();

            PdfFilesJson = "[" + string.Join(",", files) + "]";
        }
    }
}

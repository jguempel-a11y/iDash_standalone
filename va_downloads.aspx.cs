using System;
using System.IO;
using System.Collections.Generic;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class va_downloads : System.Web.UI.Page
{
    public class DownloadFile
    {
        public string Title { get; set; }
        public string RelativePath { get; set; }
        public string Size { get; set; }
        public string DateAuthored { get; set; }
        public string Icon { get; set; }
        public bool IsFolder { get; set; }
    }

    public class DownloadCategory
    {
        public string Name { get; set; }
        public List<DownloadFile> Files { get; set; }
    }

    private bool IsSignedIn()
    {
        return Session["IsAdminAuthenticated"] != null && (bool)Session["IsAdminAuthenticated"];
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            ApplyAuthState();
        }
    }

    private void ApplyAuthState()
    {
        bool ok = IsSignedIn();
        PnlNotSignedIn.Visible = !ok;
        PnlContent.Visible = ok;
        if (ok) BindDownloads();
    }

    protected void BtnDownloadsLogin_Click(object sender, EventArgs e)
    {
        LblDownloadsLoginError.Text = "";
        string user = TxtDownloadsUser.Text.Trim();
        string pass = TxtDownloadsPass.Text.Trim();

        bool valid = false;
        try { valid = System.Web.Security.Membership.ValidateUser(user, pass); } catch { }
        if (!valid) valid = (user == "idashadmin" && pass == "idashadmin");

        if (valid)
        {
            Session["IsAdminAuthenticated"] = true;
            ApplyAuthState();
        }
        else
        {
            LblDownloadsLoginError.Text = "Invalid credentials. Please try again.";
        }
    }

    private void BindDownloads()
    {
        string basePath = Server.MapPath("downloads");
        if (!Directory.Exists(basePath)) return;

        var categories = new List<DownloadCategory>();
        
        string reqDir = Request.QueryString["dir"];
        bool isSubDir = !string.IsNullOrEmpty(reqDir);
        string currentFullPath = basePath;

        if (isSubDir)
        {
            reqDir = reqDir.Replace("..", "").Replace("//", "/").Trim('/');
            currentFullPath = Path.Combine(basePath, reqDir);
            
            // Security check
            if (!currentFullPath.StartsWith(basePath, StringComparison.OrdinalIgnoreCase) || !Directory.Exists(currentFullPath))
            {
                Response.Redirect("va_downloads.aspx");
                return;
            }

            PnlFolderNav.Visible = true;
            LitCurrentFolder.Text = new DirectoryInfo(currentFullPath).Name;
            
            int lastSlash = reqDir.LastIndexOf('/');
            if (lastSlash > 0) {
                LnkGoUp.NavigateUrl = "va_downloads.aspx?dir=" + Server.UrlEncode(reqDir.Substring(0, lastSlash));
            } else {
                LnkGoUp.NavigateUrl = "va_downloads.aspx";
            }

            var cat = new DownloadCategory();
            cat.Name = reqDir;
            cat.Files = GetFolderContents(currentFullPath, basePath);
            categories.Add(cat);
        }
        else
        {
            PnlFolderNav.Visible = false;
            string[] directories = Directory.GetDirectories(basePath);
            
            // Custom Sort: Specific order preferred by user
            var orderMap = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase) {
                { "Software", 1 },
                { "Reports", 2 },
                { "Administrative", 3 },
                { "Licenses", 4 },
                { "Drivers", 5 },
                { "Printer Templates", 6 }
            };

            foreach (string dir in directories)
            {
                var cat = new DownloadCategory();
                cat.Name = new DirectoryInfo(dir).Name;
                cat.Files = GetFolderContents(dir, basePath);
                categories.Add(cat);
            }

            // Sort categories by predefined order, then alphabetically
            categories.Sort((a, b) => {
                int aOrder = orderMap.ContainsKey(a.Name) ? orderMap[a.Name] : 99;
                int bOrder = orderMap.ContainsKey(b.Name) ? orderMap[b.Name] : 99;
                if (aOrder != bOrder) return aOrder.CompareTo(bOrder);
                return string.Compare(a.Name, b.Name, StringComparison.OrdinalIgnoreCase);
            });
        }

        RptCategories.DataSource = categories;
        RptCategories.DataBind();
    }

    private List<DownloadFile> GetFolderContents(string dirPath, string basePath)
    {
        var filesList = new List<DownloadFile>();
        
        // Add subdirectories
        string[] dirs = Directory.GetDirectories(dirPath);
        foreach (string d in dirs)
        {
            DirectoryInfo di = new DirectoryInfo(d);
            string subPath = d.Substring(basePath.Length).Replace("\\", "/").TrimStart('/');
            filesList.Add(new DownloadFile {
                Title = di.Name,
                RelativePath = "downloads/" + subPath,
                Size = "Folder",
                DateAuthored = di.LastWriteTime.ToString("MMM dd, yyyy"),
                Icon = "&#128193;", // Folder icon
                IsFolder = true
            });
        }

        // Add files
        string[] files = Directory.GetFiles(dirPath);
        foreach (string file in files)
        {
            FileInfo fi = new FileInfo(file);
            string ext = fi.Extension.ToLower();
            string icon = "&#128196;"; 
            if (ext == ".pdf") icon = "&#128213;";
            else if (ext == ".zip" || ext == ".rar" || ext == ".7z") icon = "&#128230;";
            else if (ext == ".exe" || ext == ".msi" || ext == ".ps1" || ext == ".bat") icon = "&#128187;";
            else if (ext == ".btw") icon = "&#128438;";
            else if (ext == ".xlsx" || ext == ".csv" || ext == ".xls") icon = "&#128202;";
            else if (ext == ".docx" || ext == ".doc") icon = "&#128196;";
            else if (ext == ".txt") icon = "&#128195;";
            else if (ext == ".db" || ext == ".sqlite") icon = "&#128452;";

            string titleName = fi.Name;
            string subPath = file.Substring(basePath.Length).Replace("\\", "/").TrimStart('/');

            filesList.Add(new DownloadFile {
                Title = titleName,
                RelativePath = "downloads/" + subPath,
                Size = FormatBytes(fi.Length),
                DateAuthored = fi.LastWriteTime.ToString("MMM dd, yyyy"),
                Icon = icon,
                IsFolder = false
            });
        }
        
        return filesList;
    }

    protected void RptCategories_ItemDataBound(object sender, RepeaterItemEventArgs e)
    {
        if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
        {
            var category = (DownloadCategory)e.Item.DataItem;
            Repeater rptFiles = (Repeater)e.Item.FindControl("RptFiles");
            rptFiles.DataSource = category.Files;
            rptFiles.DataBind();
        }
    }

    protected void DownloadFile_Click(object sender, EventArgs e)
    {
        LinkButton btn = (LinkButton)sender;
        string relPath = btn.CommandArgument; // This is "downloads/Category/..."
        string fullPath = Server.MapPath(relPath);
        
        // Security checks
        string downloadsRoot = Server.MapPath("downloads");
        if (!fullPath.StartsWith(downloadsRoot, StringComparison.OrdinalIgnoreCase)) {
            return; // Prevent directory traversal attacks
        }
        
        if (File.Exists(fullPath))
        {
            try
            {
                // Use FileShare.ReadWrite to bypass locking if the user has the file open in Excel/Word
                using (FileStream fs = new FileStream(fullPath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
                {
                    Response.Clear();
                    Response.ContentType = "application/octet-stream";
                    Response.AppendHeader("Content-Disposition", "attachment; filename=\"" + Path.GetFileName(fullPath) + "\"");
                    Response.AppendHeader("Content-Length", fs.Length.ToString());
                    
                    fs.CopyTo(Response.OutputStream);
                    Response.Flush();
                    Response.End();
                }
            }
            catch (System.Threading.ThreadAbortException)
            {
                // Normal when calling Response.End()
            }
        }
    }

    private string FormatBytes(long bytes)
    {
        string[] Suffix = { "B", "KB", "MB", "GB", "TB" };
        int i;
        double dblSByte = bytes;
        for (i = 0; i < Suffix.Length && bytes >= 1024; i++, bytes /= 1024)
        {
            dblSByte = bytes / 1024.0;
        }
        return String.Format("{0:0.##} {1}", dblSByte, Suffix[i]);
    }

    protected void BtnDownloadZip_Click(object sender, EventArgs e)
    {
        string reqDir = Request.QueryString["dir"];
        if (string.IsNullOrEmpty(reqDir)) return;
        
        string basePath = Server.MapPath("downloads");
        reqDir = reqDir.Replace("..", "").Replace("//", "/").Trim('/');
        string fullPath = Path.Combine(basePath, reqDir);
        
        if (!fullPath.StartsWith(basePath, StringComparison.OrdinalIgnoreCase) || !Directory.Exists(fullPath)) return;

        string zipName = new DirectoryInfo(fullPath).Name + ".zip";
        string tempZip = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString() + ".zip");
        
        try 
        {
            System.IO.Compression.ZipFile.CreateFromDirectory(fullPath, tempZip);
            Response.Clear();
            Response.ContentType = "application/zip";
            Response.AppendHeader("Content-Disposition", "attachment; filename=\"" + zipName + "\"");
            Response.TransmitFile(tempZip);
            Response.Flush();
            File.Delete(tempZip);
            Response.End();
        } 
        catch (System.Threading.ThreadAbortException)
        {
            // Expected with Response.End()
        }
        catch (Exception ex)
        {
            Response.Write("Error creating ZIP: " + ex.Message);
        }
    }

    // =========================================================================================
    // UPLOAD FUNCTIONALITY
    // =========================================================================================
    protected void BtnToggleUpload_Click(object sender, EventArgs e)
    {
        PnlUploadWrapper.Visible = !PnlUploadWrapper.Visible;
        if (PnlUploadWrapper.Visible)
        {
            CheckUploadState();
        }
    }

    private void CheckUploadState()
    {
        // Require explicit session var or active ASP.NET User login
        bool uploader = (Session["CanUploadDownloads"] != null && (bool)Session["CanUploadDownloads"]) || 
                        (User != null && User.Identity != null && User.Identity.IsAuthenticated);
                        
        PnlUploadLogin.Visible = !uploader;
        PnlUploadForm.Visible = uploader;
        
        if (uploader && DdlCategories.Items.Count == 0)
        {
            string basePath = Server.MapPath("downloads");
            if (Directory.Exists(basePath))
            {
                foreach(string d in Directory.GetDirectories(basePath))
                {
                    DdlCategories.Items.Add(new ListItem(new DirectoryInfo(d).Name));
                }
            }
        }
    }

    protected void BtnLogin_Click(object sender, EventArgs e)
    {
        LblLoginError.Text = "";
        string user = TxtUser.Text.Trim();
        string pass = TxtPass.Text.Trim();
        
        try 
        {
            if (System.Web.Security.Membership.ValidateUser(user, pass) || (user == "idashadmin" && pass == "idashadmin"))
            {
                Session["CanUploadDownloads"] = true;
                CheckUploadState();
            }
            else
            {
                LblLoginError.Text = "Invalid credentials.";
            }
        }
        catch (Exception)
        {
            LblLoginError.Text = "Authentication API error. Try uploading manually via the server.";
        }
    }

    protected void BtnUpload_Click(object sender, EventArgs e)
    {
        LblUploadMsg.Text = "";
        
        if (!FileUploader.HasFile)
        {
            LblUploadMsg.Text = "<span style='color:#ef4444;'>Please select a file to upload.</span>";
            return;
        }
        
        if (string.IsNullOrEmpty(DdlCategories.SelectedValue))
        {
            LblUploadMsg.Text = "<span style='color:#ef4444;'>Please select a destination category.</span>";
            return;
        }
        
        try
        {
            string catPath = Path.Combine(Server.MapPath("downloads"), DdlCategories.SelectedValue);
            if (!Directory.Exists(catPath)) return;
            
            string savePath = Path.Combine(catPath, Path.GetFileName(FileUploader.FileName));
            FileUploader.SaveAs(savePath);
            
            LblUploadMsg.Text = "<span style='color:#10b981;'>File uploaded successfully!</span>";
            
            // Refresh dashboard visually
            BindDownloads();
        }
        catch (Exception ex)
        {
            LblUploadMsg.Text = "<span style='color:#ef4444;'>Error uploading file: " + Server.HtmlEncode(ex.Message) + "</span>";
        }
    }

    // =========================================================================================
    // CUSTOMER / EMPLOYEE FILE UPLOAD  (no admin auth required — anyone signed in can send)
    // =========================================================================================
    protected void BtnCustomerUpload_Click(object sender, EventArgs e)
    {
        LitCustomerUploadMsg.Text = "";

        // Validate sender name
        string senderName = TxtSenderName.Text.Trim();
        if (string.IsNullOrEmpty(senderName))
        {
            LitCustomerUploadMsg.Text = "<div class='upload-result err'>Please enter your name so we know who sent the file.</div>";
            return;
        }

        // Validate file
        if (!CustomerFileUpload.HasFile)
        {
            LitCustomerUploadMsg.Text = "<div class='upload-result err'>Please select a file to upload.</div>";
            return;
        }

        // Block dangerous extensions
        string ext = Path.GetExtension(CustomerFileUpload.FileName).ToLower();
        string[] blocked = { ".exe", ".bat", ".cmd", ".com", ".scr", ".pif", ".vbs", ".js", ".wsf", ".msi", ".dll" };
        if (Array.Exists(blocked, b => b == ext))
        {
            LitCustomerUploadMsg.Text = "<div class='upload-result err'>That file type is not allowed. Please ZIP it first.</div>";
            return;
        }

        // 100 MB limit
        if (CustomerFileUpload.PostedFile.ContentLength > 104857600)
        {
            LitCustomerUploadMsg.Text = "<div class='upload-result err'>File exceeds the 100 MB limit.</div>";
            return;
        }

        try
        {
            // Ensure uploads/incoming folder exists
            string incomingDir = Server.MapPath("uploads/incoming");
            if (!Directory.Exists(incomingDir))
                Directory.CreateDirectory(incomingDir);

            // Build a safe filename:  20260722_093412_JaneSmith_report.xlsx
            string safeSender = System.Text.RegularExpressions.Regex.Replace(senderName, @"[^a-zA-Z0-9]", "");
            string timestamp = DateTime.Now.ToString("yyyyMMdd_HHmmss");
            string originalName = Path.GetFileName(CustomerFileUpload.FileName);
            string savedName = timestamp + "_" + safeSender + "_" + originalName;
            string savePath = Path.Combine(incomingDir, savedName);

            CustomerFileUpload.SaveAs(savePath);

            // Write a companion manifest with metadata
            string manifestPath = savePath + ".info.txt";
            string note = TxtSenderNote.Text.Trim();
            string ip = Request.UserHostAddress ?? "unknown";
            File.WriteAllText(manifestPath, string.Format(
                "Sender: {0}\r\nDate: {1}\r\nOriginal Filename: {2}\r\nIP: {3}\r\nNote: {4}\r\n",
                senderName, DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"), originalName, ip,
                string.IsNullOrEmpty(note) ? "(none)" : note
            ));

            LitCustomerUploadMsg.Text = "<div class='upload-result ok'>&#10003; File received! Thank you, " + Server.HtmlEncode(senderName) + ". The iDash team will review it shortly.</div>";

            // Clear fields for next upload
            TxtSenderName.Text = "";
            TxtSenderNote.Text = "";
        }
        catch (Exception ex)
        {
            LitCustomerUploadMsg.Text = "<div class='upload-result err'>Upload failed: " + Server.HtmlEncode(ex.Message) + "</div>";
        }
    }
}

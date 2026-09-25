<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_downloads.aspx.cs" Inherits="va_downloads" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Expires" content="0" />
    <title>Downloads &amp; Uploads | iDash</title>
    <link rel="icon" type="image/png" href="/iDash/Assets/branding/rfid.png" />
    <link rel="stylesheet" href="theme.css" />
            <script src="theme-init.js"></script>
    <style>
        body { margin: 0; background: var(--bg); color: var(--text); font-family: Segoe UI, sans-serif; scroll-behavior: smooth; }
        .page { max-width: 1200px; margin: 40px auto; padding: 0 40px; }
        a.back-btn { color: var(--accent); text-decoration: none; font-weight: 600; display: inline-block; margin-bottom: 25px; }
        a.back-btn:hover { text-decoration: underline; }
        
        .header-title { font-size: 32px; font-weight: 700; margin-bottom: 6px; }
        .header-sub { font-size: 14px; color: var(--muted); margin-bottom: 32px; }
        
        .section-title {
            margin-top: 40px;
            margin-bottom: 16px;
            font-size: 20px;
            font-weight: 600;
            color: var(--accent-2);
            border-bottom: 1px solid var(--line);
            padding-bottom: 8px;
        }

        .tile-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
            gap: 20px;
        }

        .tile {
            background: var(--card);
            border: 1px solid var(--line);
            border-radius: 12px;
            padding: 20px;
            cursor: pointer;
            transition: 0.2s ease;
            display: flex;
            align-items: flex-start;
            gap: 15px;
            text-decoration: none;
            color: inherit;
        }

        .tile:hover {
            transform: translateY(-4px);
            box-shadow: var(--shadow);
            border-color: var(--accent);
            background: var(--chip); /* slightly lighter card inside */
        }

        .tile-icon {
            font-size: 32px;
            line-height: 1;
            margin-top: 3px;
        }

        .tile-content { flex: 1; min-width: 0; }
        
        .tile-title {
            font-size: 15px;
            font-weight: 600;
            margin-bottom: 6px;
            color: var(--accent);
            word-wrap: break-word;
        }

        .tile-meta {
            font-size: 12px;
            color: var(--muted);
            margin-bottom: 2px;
        }

        .empty-group {
            color: var(--muted);
            font-size: 14px;
            padding: 10px;
            background: rgba(255,255,255,0.02);
            border-radius: 8px;
            border: 1px dashed var(--line);
            grid-column: 1 / -1;
        }

        /* ── Upload Section ── */
        .upload-section {
            margin-top: 48px;
            border-top: 2px solid var(--line);
            padding-top: 36px;
        }
        .upload-section-title {
            font-size: 22px;
            font-weight: 700;
            margin-bottom: 6px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .upload-section-sub {
            font-size: 14px;
            color: var(--muted);
            margin-bottom: 24px;
        }
        .upload-card {
            background: var(--card);
            border: 1px solid var(--line);
            border-radius: 14px;
            padding: 28px;
            max-width: 640px;
        }
        .upload-card .field-group {
            margin-bottom: 18px;
        }
        .upload-card .field-group label {
            display: block;
            font-size: 12px;
            font-weight: 700;
            color: var(--muted);
            text-transform: uppercase;
            letter-spacing: .04em;
            margin-bottom: 6px;
        }
        .upload-card .field-group input[type=text],
        .upload-card .field-group textarea {
            width: 100%;
            background: var(--bg);
            color: var(--text);
            border: 1px solid var(--line);
            padding: 10px 13px;
            border-radius: 8px;
            font-size: 14px;
            font-family: inherit;
            box-sizing: border-box;
            outline: none;
            transition: border-color .15s;
        }
        .upload-card .field-group input[type=text]:focus,
        .upload-card .field-group textarea:focus {
            border-color: var(--accent);
        }
        .upload-card .field-group textarea {
            min-height: 70px;
            resize: vertical;
        }
        .upload-dropzone {
            border: 2px dashed var(--line);
            border-radius: 10px;
            padding: 28px 20px;
            text-align: center;
            transition: border-color .2s, background .2s;
            cursor: pointer;
        }
        .upload-dropzone:hover,
        .upload-dropzone.dragover {
            border-color: var(--accent);
            background: color-mix(in srgb, var(--accent), transparent 94%);
        }
        .upload-dropzone .icon { font-size: 32px; margin-bottom: 8px; }
        .upload-dropzone .cta { font-size: 14px; font-weight: 600; color: var(--text); }
        .upload-dropzone .hint { font-size: 12px; color: var(--muted); margin-top: 4px; }
        .btn-send {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            background: var(--accent);
            color: var(--bg);
            border: none;
            padding: 12px 28px;
            border-radius: 10px;
            font-size: 15px;
            font-weight: 700;
            cursor: pointer;
            transition: filter .15s;
        }
        .btn-send:hover { filter: brightness(1.12); }
        .upload-result {
            margin-top: 14px;
            padding: 12px 16px;
            border-radius: 8px;
            font-size: 14px;
        }
        .upload-result.ok { background: color-mix(in srgb, var(--accent-2), transparent 88%); border: 1px solid var(--accent-2); color: var(--accent-2); }
        .upload-result.err { background: color-mix(in srgb, var(--danger), transparent 88%); border: 1px solid var(--danger); color: var(--danger); }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="page">
            <a href="index.aspx" class="back-btn">&larr; Back to Dashboard</a>

            <div class="header-title">&#128230; Downloads &amp; Uploads</div>

            <%-- ===== NOT SIGNED IN WALL ===== --%>
            <asp:Panel ID="PnlNotSignedIn" runat="server" Visible="true">
                <div style="margin-top:60px; max-width:440px; margin-left:auto; margin-right:auto;
                            background:var(--card); border:1px solid var(--line); border-radius:16px;
                            padding:36px 32px; text-align:center; box-shadow:var(--shadow);">
                    <div style="font-size:48px; margin-bottom:16px;">&#128274;</div>
                    <div style="font-size:22px; font-weight:700; margin-bottom:8px; color:var(--text);">Sign In Required</div>
                    <div style="font-size:14px; color:var(--muted); margin-bottom:28px;">
                        You must be signed in to access Downloads & Uploads.
                    </div>

                    <asp:Panel ID="PnlDownloadsLoginForm" runat="server" DefaultButton="BtnDownloadsLogin">
                        <asp:TextBox ID="TxtDownloadsUser" runat="server" Placeholder="Username" autocomplete="username"
                            style="width:100%; background:var(--bg); color:var(--text); border:1px solid var(--line);
                                   padding:11px 14px; border-radius:8px; font-size:14px; margin-bottom:12px; box-sizing:border-box;" />
                        <asp:TextBox ID="TxtDownloadsPass" runat="server" TextMode="Password" Placeholder="Password" autocomplete="current-password"
                            style="width:100%; background:var(--bg); color:var(--text); border:1px solid var(--line);
                                   padding:11px 14px; border-radius:8px; font-size:14px; margin-bottom:20px; box-sizing:border-box;" />

                        <asp:Button ID="BtnDownloadsLogin" runat="server" Text="Sign In"
                            OnClick="BtnDownloadsLogin_Click"
                            style="width:100%; background:var(--accent); color:var(--bg); border:none;
                                   padding:12px; border-radius:8px; font-size:15px; font-weight:700; cursor:pointer;" />

                        <asp:Label ID="LblDownloadsLoginError" runat="server"
                            style="display:block; margin-top:12px; font-size:13px; color:#ef4444;" />
                    </asp:Panel>
                </div>
            </asp:Panel>

            <%-- ===== AUTHENTICATED CONTENT ===== --%>
            <asp:Panel ID="PnlContent" runat="server" Visible="false">
                <div class="header-sub" style="display:flex; justify-content:space-between; align-items:center; margin-bottom:32px; flex-wrap:wrap; gap:10px;">
                    <span>Download approved software and files, or <a href="#uploadSection" style="color:var(--accent); font-weight:600; text-decoration:none;">send files directly to the iDash team &darr;</a></span>
                    <div style="display:flex; gap:10px; align-items:center;">
                        <a href="#uploadSection" style="display:inline-flex; align-items:center; gap:6px; background:var(--accent); color:var(--bg); padding:8px 18px; border-radius:8px; font-size:13px; font-weight:700; text-decoration:none; transition:filter .15s;">&#128228; Send Us a File</a>
                        <asp:LinkButton ID="BtnToggleUpload" runat="server" OnClick="BtnToggleUpload_Click" style="color:var(--muted); font-size:12px; text-decoration:none;" title="Admin: add files to download categories">&#9881; Manage</asp:LinkButton>
                    </div>
                </div>

                <asp:Panel ID="PnlUploadWrapper" runat="server" Visible="false" style="background:var(--card); border:1px solid var(--line); border-radius:12px; padding:20px; margin-bottom:30px;">
                    <h3 style="margin-top:0; color:var(--accent); margin-bottom:15px;">Upload to Downloads Center</h3>
                    
                    <asp:Panel ID="PnlUploadLogin" runat="server" DefaultButton="BtnLogin">
                        <div style="color:var(--muted); font-size:13px; margin-bottom:12px;">Please authenticate with your AssetWorx credentials to upload files.</div>
                        <div style="display:flex; gap:10px; max-width:500px;">
                            <asp:TextBox ID="TxtUser" runat="server" Placeholder="Username" style="flex:1; background:var(--bg); color:var(--text); border:1px solid var(--line); padding:10px; border-radius:4px;" />
                            <asp:TextBox ID="TxtPass" runat="server" TextMode="Password" Placeholder="Password" style="flex:1; background:var(--bg); color:var(--text); border:1px solid var(--line); padding:10px; border-radius:4px;" />
                            <asp:Button ID="BtnLogin" runat="server" Text="Log In" OnClick="BtnLogin_Click" style="background:var(--accent); color:var(--bg); border:none; padding:10px 20px; border-radius:4px; font-weight:600; cursor:pointer;" />
                        </div>
                        <asp:Label ID="LblLoginError" runat="server" ForeColor="#ef4444" style="display:block; margin-top:8px; font-size:13px;"></asp:Label>
                    </asp:Panel>

                    <asp:Panel ID="PnlUploadForm" runat="server" Visible="false">
                        <div style="display:flex; gap:15px; align-items:flex-end;">
                            <div style="flex:1; max-width:250px;">
                                <label style="display:block; font-size:12px; color:var(--muted); margin-bottom:6px;">Select Category Folder</label>
                                <asp:DropDownList ID="DdlCategories" runat="server" style="width:100%; background:var(--bg); color:var(--text); border:1px solid var(--line); padding:10px; border-radius:4px;"></asp:DropDownList>
                            </div>
                            <div style="flex:2;">
                                <label style="display:block; font-size:12px; color:var(--muted); margin-bottom:6px;">Choose File</label>
                                <asp:FileUpload ID="FileUploader" runat="server" style="width:100%; background:var(--bg); color:var(--text); border:1px solid var(--line); padding:7px; border-radius:4px;" />
                            </div>
                            <div>
                                <asp:Button ID="BtnUpload" runat="server" Text="Upload File" OnClick="BtnUpload_Click" style="background:var(--accent-2); color:var(--bg); border:none; padding:10px 20px; border-radius:4px; font-weight:600; cursor:pointer;" />
                            </div>
                        </div>
                        <asp:Label ID="LblUploadMsg" runat="server" style="display:block; margin-top:10px; font-size:13px;"></asp:Label>
                    </asp:Panel>
                </asp:Panel>

                <asp:Panel ID="PnlFolderNav" runat="server" Visible="false" style="margin-bottom: 20px; display:flex; justify-content:space-between; align-items:center; background: var(--card); padding: 15px 20px; border-radius: 12px; border: 1px solid var(--line);">
                    <div style="display:flex; align-items:center; gap: 15px;">
                        <asp:HyperLink ID="LnkGoUp" runat="server" CssClass="back-btn" style="margin-bottom:0;">&larr; Go Up</asp:HyperLink>
                        <span style="font-weight:600; color:var(--text); font-size:16px;">&#128193; <asp:Literal ID="LitCurrentFolder" runat="server" /></span>
                    </div>
                    <asp:LinkButton ID="BtnDownloadZip" runat="server" OnClick="BtnDownloadZip_Click" style="display:inline-flex; align-items:center; gap:6px; background:var(--accent-2); color:var(--bg); padding:8px 18px; border-radius:8px; font-size:13px; font-weight:700; text-decoration:none; border:none; cursor:pointer;">&#128230; Download Folder (ZIP)</asp:LinkButton>
                </asp:Panel>

                <asp:Repeater ID="RptCategories" runat="server" OnItemDataBound="RptCategories_ItemDataBound">
                    <ItemTemplate>
                        <div class="section-title"><%# Eval("Name") %></div>
                        
                        <div class="tile-grid">
                            <asp:Repeater ID="RptFiles" runat="server">
                                <ItemTemplate>
                                    <asp:PlaceHolder runat="server" Visible='<%# !(bool)Eval("IsFolder") %>'>
                                        <asp:LinkButton runat="server" OnClick="DownloadFile_Click" CommandArgument='<%# Eval("RelativePath") %>' CssClass="tile">
                                            <div class="tile-icon"><%# Eval("Icon") %></div>
                                            <div class="tile-content">
                                                <div class="tile-title"><%# Eval("Title") %></div>
                                                <div class="tile-meta">Size: <%# Eval("Size") %></div>
                                                <div class="tile-meta">Modified: <%# Eval("DateAuthored") %></div>
                                            </div>
                                        </asp:LinkButton>
                                    </asp:PlaceHolder>
                                    <asp:PlaceHolder runat="server" Visible='<%# (bool)Eval("IsFolder") %>'>
                                        <a href='va_downloads.aspx?dir=<%# Server.UrlEncode(((string)Eval("RelativePath")).Substring(10)) %>' class="tile">
                                            <div class="tile-icon"><%# Eval("Icon") %></div>
                                            <div class="tile-content">
                                                <div class="tile-title"><%# Eval("Title") %></div>
                                                <div class="tile-meta"><%# Eval("Size") %></div>
                                                <div class="tile-meta">Modified: <%# Eval("DateAuthored") %></div>
                                            </div>
                                        </a>
                                    </asp:PlaceHolder>
                                </ItemTemplate>
                            </asp:Repeater>
                            <asp:PlaceHolder runat="server" Visible='<%# ((System.Collections.Generic.List<va_downloads.DownloadFile>)Eval("Files")).Count == 0 %>'>
                                <div class="empty-group">There are currently no files published in this directory.</div>
                            </asp:PlaceHolder>
                        </div>
                    </ItemTemplate>
                </asp:Repeater>

                <!-- ===== CUSTOMER / EMPLOYEE UPLOAD SECTION ===== -->
                <div class="upload-section" id="uploadSection">
                    <div class="upload-section-title">&#128228; Send Files to iDash</div>
                    <div class="upload-section-sub">
                        Need to send us a file? Upload it here and it will go directly to the iDash team.
                        Accepted formats: Excel, CSV, PDF, ZIP, images, and most common file types.
                    </div>

                    <div class="upload-card">
                        <div class="field-group">
                            <label>Your Name</label>
                            <asp:TextBox ID="TxtSenderName" runat="server" placeholder="e.g. Jane Smith" />
                        </div>
                        <div class="field-group">
                            <label>Note (optional)</label>
                            <asp:TextBox ID="TxtSenderNote" runat="server" TextMode="MultiLine" placeholder="What is this file for? Any context helps." />
                        </div>
                        <div class="field-group">
                            <label>Choose File</label>
                            <div class="upload-dropzone" id="dropZone" onclick="document.getElementById('<%= CustomerFileUpload.ClientID %>').click();">
                                <div class="icon">&#128206;</div>
                                <div class="cta" id="dropLabel">Click to browse or drag a file here</div>
                                <div class="hint">Max file size: 100 MB</div>
                            </div>
                            <asp:FileUpload ID="CustomerFileUpload" runat="server" style="display:none;" />
                        </div>
                        <asp:Button ID="BtnCustomerUpload" runat="server" Text="&#9654; Send File" OnClick="BtnCustomerUpload_Click" CssClass="btn-send" />
                        <asp:Literal ID="LitCustomerUploadMsg" runat="server" />
                    </div>
                </div>

            </asp:Panel>

        </div>
</form>
<script>
(function(){
    var zone = document.getElementById('dropZone');
    var inp  = document.getElementById('<%= CustomerFileUpload.ClientID %>');
    var lbl  = document.getElementById('dropLabel');
    if (!zone || !inp) return;

    // Show filename when user picks via browse
    inp.addEventListener('change', function(){
        lbl.textContent = inp.files.length ? inp.files[0].name : 'Click to browse or drag a file here';
    });

    // Drag-and-drop visual feedback
    zone.addEventListener('dragover', function(e){ e.preventDefault(); zone.classList.add('dragover'); });
    zone.addEventListener('dragleave', function(){ zone.classList.remove('dragover'); });
    zone.addEventListener('drop', function(e){
        e.preventDefault();
        zone.classList.remove('dragover');
        if (e.dataTransfer.files.length) {
            inp.files = e.dataTransfer.files;
            lbl.textContent = e.dataTransfer.files[0].name;
        }
    });
})();
</script>
</body>
</html>

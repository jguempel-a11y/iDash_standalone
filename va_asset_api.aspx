<%@ Page Language="C#" AutoEventWireup="true"
    CodeFile="va_asset_api.aspx.cs"
    Inherits="va_asset_api" %>

<!DOCTYPE html>
<html>
<head runat="server">
<title>VA Asset Explorer</title>
            <link rel="icon" type="image/png" href="Assets/branding/rfid.png" />
            <link rel="stylesheet" href="theme.css" />
            <script src="theme-init.js"></script>

<style>
body{
  background:var(--bg);
  color:var(--text);
  font-family:Segoe UI, Arial, sans-serif;
  margin:0;
  padding:16px;
}

.toolbar{
  display:flex;
  gap:10px;
  align-items:center;
  margin-bottom:12px;
  flex-wrap:wrap;
}

.toolbar .hint{
  opacity:.7;
  font-size:12px;
}

input[type="text"]{
  background:var(--chip);
  color:#fff;
  border:1px solid var(--line);
  padding:6px 8px;
  border-radius:4px;
  width:320px;
  box-sizing:border-box;
}

.smallBtn{
  background:#1a2a46;
  color:#fff;
  border:1px solid var(--line);
  padding:5px 8px;
  border-radius:4px;
  cursor:pointer;
  font-size:12px;
}

.smallBtn:hover{ opacity:.95; }

#status{
  margin:8px 0 12px 0;
  opacity:.85;
  font-size:12px;
}

.grid{
  border-collapse:collapse;
  width:100%;
  font-size:12px;
}

.grid th, .grid td{
  border:1px solid var(--line);
  padding:4px 6px;
  vertical-align:top;
}

.grid th{
  background:var(--card);
}

.filter{
  width:100%;
  box-sizing:border-box;
  background:var(--chip);
  color:#fff;
  border:1px solid var(--line);
  margin-top:4px;
  padding:3px 6px;
  border-radius:3px;
}

.hidden{ display:none; }

#colChooser{
  background:var(--card);
  border:1px solid var(--line);
  padding:10px;
  margin-bottom:12px;
}

#colChooserTop{
  display:flex;
  gap:8px;
  align-items:center;
  flex-wrap:wrap;
  margin-bottom:8px;
}

#colFilter{
  width:260px;
}

#colList{
  max-height:220px;
  overflow:auto;
  border-top:1px solid var(--line);
  padding-top:8px;
}

#colList div{
  margin:2px 0;
  white-space:nowrap;
}
</style>
</head>

<body>
<form id="form1" runat="server">

  <!-- TOOLBAR -->
  <div class="toolbar">
      <asp:TextBox ID="TxtSearch" runat="server"
          Placeholder="Find asset (512 EE..., serial, SP1D118, EIL/CMR...)"
          onkeydown="if(event.keyCode==13){document.getElementById('<%= BtnLoad.ClientID %>').click(); return false;}" />

      <asp:Button ID="BtnLoad" runat="server" Text="Search" OnClick="BtnLoad_Click" CssClass="smallBtn" />
      <asp:Button ID="BtnClear" runat="server" Text="Clear" OnClick="BtnClear_Click" CssClass="smallBtn" />

      <span class="hint">Defaults to your daily columns. Use chooser search to find a column fast.</span>
  </div>

  <asp:Literal ID="LitStatus" runat="server" />

  <!-- COLUMN CHOOSER -->
  <div id="colChooser">
      <div id="colChooserTop">
          <b style="margin-right:8px;">Column Chooser</b>
          <input id="colFilter" type="text" placeholder="Filter columns (e.g. text, last, location)" />
          <button type="button" class="smallBtn" onclick="showAllCols()">Show all</button>
          <button type="button" class="smallBtn" onclick="hideAllCols()">Hide all</button>
          <button type="button" class="smallBtn" onclick="resetDefaultCols()">Reset default</button>
      </div>
      <div id="colList"></div>
  </div>

  <!-- GRID -->
  <asp:Literal ID="LitGrid" runat="server" />

</form>
</body>
</html>
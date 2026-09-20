using System;
using System.Data;
using System.Data.SqlClient;
using System.Configuration;
using System.Text;

public partial class va_asset_api : System.Web.UI.Page
{
    // Default visible columns (must match the *actual* column names in v_asset)
    // These are compared case-insensitively in JS.
    private const string DEFAULT_VISIBLE =
        "id,name,description,lastobservedlocation,lastobservedtime,listvalue1," +
        "text1,text2,text3,text4,text5,text6,text7,text8,text9,text10,text11,text12,text13,text14,text15,text16,text17,text18,text19,text20," +
        "lastmodified,lastmodifiedby,lastinventoried,companyid,locationname";

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            // Load something immediately so the page isn’t “blank”
            DataTable dt = LoadFromSql(200, "");
            RenderGrid(dt, "Loaded latest 200 assets. Use Search to narrow results.");
        }
    }

    protected void BtnLoad_Click(object sender, EventArgs e)
    {
        string q = (TxtSearch == null) ? "" : (TxtSearch.Text ?? "");
        q = q.Trim();

        DataTable dt = LoadFromSql(500, q);
        RenderGrid(dt, q == "" ? "Loaded latest 500 assets." : ("Search: " + Server.HtmlEncode(q)));
    }

    protected void BtnClear_Click(object sender, EventArgs e)
    {
        if (TxtSearch != null) TxtSearch.Text = "";
        DataTable dt = LoadFromSql(200, "");
        RenderGrid(dt, "Cleared search. Loaded latest 200 assets.");
    }

    DataTable LoadFromSql(int topN, string search)
    {
        using (SqlConnection cn = new SqlConnection(
            ConfigurationManager.ConnectionStrings["iDash"].ConnectionString))
        {
            // NOTE: If dbo.v_asset doesn't have id, change ORDER BY to lastmodified DESC or lastobservedtime DESC
            string sql =
                "SELECT TOP (@top) * " +
                "FROM dbo.v_asset " +
                "WHERE ( @q = '' " +
                "   OR name  LIKE @like " +
                "   OR rfidtag LIKE @like " +
                "   OR text1 LIKE @like " +
                "   OR text2 LIKE @like " +
                "   OR text3 LIKE @like " +
                "   OR text6 LIKE @like " +
                "   OR text7 LIKE @like " +
                "   OR text8 LIKE @like " +
                "   OR text12 LIKE @like " +
                " ) " +
                "ORDER BY id DESC";

            using (SqlCommand cmd = new SqlCommand(sql, cn))
            {
                cmd.Parameters.AddWithValue("@top", topN);
                cmd.Parameters.AddWithValue("@q", search ?? "");
                cmd.Parameters.AddWithValue("@like", "%" + (search ?? "") + "%");

                SqlDataAdapter da = new SqlDataAdapter(cmd);
                DataTable dt = new DataTable();
                da.Fill(dt);
                return dt;
            }
        }
    }

    void RenderGrid(DataTable dt, string statusMsg)
    {
        if (dt == null || dt.Rows.Count == 0)
        {
            LitStatus.Text = "<div id='status' style='color:#ef4444'>No rows returned.</div>";
            LitGrid.Text = "";
            return;
        }

        LitStatus.Text = "<div id='status'>" + statusMsg + " &nbsp; <b>Rows:</b> " + dt.Rows.Count + "</div>";

        StringBuilder sb = new StringBuilder();

        sb.Append("<table class='grid'>");
        sb.Append("<thead><tr>");

        foreach (DataColumn c in dt.Columns)
        {
            string col = SafeCssClass(c.ColumnName);

            sb.Append("<th class='");
            sb.Append(col);
            sb.Append("'>");

            sb.Append(Server.HtmlEncode(c.ColumnName));
            sb.Append("<br/>");

            // filter box: stop bubbling, block Enter submit, debounce
            sb.Append("<input class='filter' ");
            sb.Append("onclick=\"event.stopPropagation();\" ");
            sb.Append("onkeydown=\"if(event.keyCode==13){event.preventDefault();return false;}\" ");
            sb.Append("onkeyup=\"queueFilter('");
            sb.Append(col);
            sb.Append("', this.value)\" />");

            sb.Append("</th>");
        }

        sb.Append("</tr></thead>");
        sb.Append("<tbody>");

        foreach (DataRow r in dt.Rows)
        {
            sb.Append("<tr>");
            foreach (DataColumn c in dt.Columns)
            {
                string col = SafeCssClass(c.ColumnName);
                object val = r[c];
                string text = (val == null || val == DBNull.Value) ? "" : val.ToString();

                sb.Append("<td class='");
                sb.Append(col);
                sb.Append("'>");
                sb.Append(Server.HtmlEncode(text));
                sb.Append("</td>");
            }
            sb.Append("</tr>");
        }

        sb.Append("</tbody></table>");

        // Scripts: debounce filter + chooser + default visibility + chooser search + buttons
        sb.Append(@"
<script type='text/javascript'>

var DEFAULT_VISIBLE = '");
        sb.Append(DEFAULT_VISIBLE.Replace("'", ""));
        sb.Append(@"'.toLowerCase().split(',');

var filterTimers = {};

function queueFilter(col, val) {
    if (filterTimers[col]) clearTimeout(filterTimers[col]);
    filterTimers[col] = setTimeout(function () { filterCol(col, val); }, 200);
}

function toggleColumn(col, show) {
    var cells = document.querySelectorAll('.' + col);
    for (var i = 0; i < cells.length; i++) {
        if (show) cells[i].classList.remove('hidden');
        else cells[i].classList.add('hidden');
    }
}

function applyDefaultVisibility() {
    var headers = document.querySelectorAll('th');
    for (var i = 0; i < headers.length; i++) {
        var col = (headers[i].className || '').toLowerCase();
        if (!col) continue;
        toggleColumn(col, DEFAULT_VISIBLE.indexOf(col) >= 0);
    }
}

function buildColumnChooser() {
    var list = document.getElementById('colList');
    if (!list) return;

    list.innerHTML = '';
    var headers = document.querySelectorAll('th');

    for (var i = 0; i < headers.length; i++) {
        var th = headers[i];
        var col = (th.className || '').toLowerCase();
        if (!col) continue;

        var row = document.createElement('div');

        var chk = document.createElement('input');
        chk.type = 'checkbox';
        chk.setAttribute('data-col', col);
        chk.checked = (DEFAULT_VISIBLE.indexOf(col) >= 0);

        chk.onchange = function () {
            toggleColumn(this.getAttribute('data-col'), this.checked);
        };

        var lbl = document.createElement('span');
        lbl.innerHTML = ' ' + th.innerText.split('\\n')[0];

        row.appendChild(chk);
        row.appendChild(lbl);
        list.appendChild(row);
    }
}

function filterCol(col, val) {
    val = (val || '').toLowerCase();
    var parts = val.split(' ');
    var rows = document.querySelectorAll('tbody tr');

    for (var i = 0; i < rows.length; i++) {
        var cell = rows[i].querySelector('.' + col);
        if (!cell) continue;

        var text = (cell.innerText || '').toLowerCase();
        var match = true;

        for (var p = 0; p < parts.length; p++) {
            if (parts[p] && text.indexOf(parts[p]) === -1) { match = false; break; }
        }

        rows[i].style.display = match ? '' : 'none';
    }
}

function showAllCols() {
    var headers = document.querySelectorAll('th');
    for (var i = 0; i < headers.length; i++) {
        var col = (headers[i].className || '').toLowerCase();
        if (!col) continue;
        toggleColumn(col, true);
    }
    var inputs = document.querySelectorAll('#colList input[type=checkbox]');
    for (var j = 0; j < inputs.length; j++) inputs[j].checked = true;
}

function hideAllCols() {
    var headers = document.querySelectorAll('th');
    for (var i = 0; i < headers.length; i++) {
        var col = (headers[i].className || '').toLowerCase();
        if (!col) continue;
        toggleColumn(col, false);
    }
    var inputs = document.querySelectorAll('#colList input[type=checkbox]');
    for (var j = 0; j < inputs.length; j++) inputs[j].checked = false;
}

function resetDefaultCols() {
    applyDefaultVisibility();
    var inputs = document.querySelectorAll('#colList input[type=checkbox]');
    for (var i = 0; i < inputs.length; i++) {
        var col = (inputs[i].getAttribute('data-col') || '').toLowerCase();
        inputs[i].checked = (DEFAULT_VISIBLE.indexOf(col) >= 0);
    }
}

function wireChooserFilter() {
    var f = document.getElementById('colFilter');
    if (!f) return;

    f.onkeydown = function(e){
        e = e || window.event;
        if (e.keyCode == 13) { if (e.preventDefault) e.preventDefault(); e.returnValue = false; return false; }
    };

    f.onkeyup = function () {
        var q = (this.value || '').toLowerCase();
        var rows = document.querySelectorAll('#colList div');
        for (var i = 0; i < rows.length; i++) {
            var t = (rows[i].innerText || '').toLowerCase();
            rows[i].style.display = (q === '' || t.indexOf(q) >= 0) ? '' : 'none';
        }
    };
}

// init
buildColumnChooser();
applyDefaultVisibility();
wireChooserFilter();

</script>
");

        LitGrid.Text = sb.ToString();
    }

    string SafeCssClass(string s)
    {
        if (string.IsNullOrEmpty(s)) return "col";
        StringBuilder t = new StringBuilder();
        for (int i = 0; i < s.Length; i++)
        {
            char ch = s[i];
            if (char.IsLetterOrDigit(ch) || ch == '_' || ch == '-')
                t.Append(ch);
            else if (ch == ' ')
                t.Append('_');
        }
        if (t.Length == 0) return "col";
        return t.ToString();
    }
}
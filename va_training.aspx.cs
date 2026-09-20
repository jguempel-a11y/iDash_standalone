using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.Services;

public partial class va_training : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            // Auto-detect user or fallback
            string user = (User != null && User.Identity != null && !string.IsNullOrEmpty(User.Identity.Name)) 
                ? User.Identity.Name 
                : "Guest";
            
            LblUser.Text = user;
            HidCurrentUser.Value = user;
        }
    }

    [WebMethod]
    public static object GetTrainingData(string username)
    {
        string user = string.IsNullOrWhiteSpace(username) ? "Guest" : username;
        return new {
            Modules = GetConfiguredModules(),
            Progress = GetUserProgress(user)
        };
    }

    [WebMethod]
    public static void LogTime(string username, int moduleId, int seconds)
    {
        string user = string.IsNullOrWhiteSpace(username) ? "Guest" : username;
        var progressList = LoadProgressData();
        
        var record = progressList.FirstOrDefault(p => string.Equals(p.Username, user, StringComparison.OrdinalIgnoreCase) && p.ModuleId == moduleId);
        if (record == null)
        {
            record = new UserProgress { Username = user, ModuleId = moduleId, Passed = false, Score = 0, TimeSpentSeconds = 0 };
            progressList.Add(record);
        }

        record.TimeSpentSeconds += seconds;
        record.LastAccessed = DateTime.Now.ToString("o");
        SaveProgressData(progressList);
    }

    [WebMethod]
    public static object SubmitQuiz(string username, int moduleId, List<int> answers)
    {
        string user = string.IsNullOrWhiteSpace(username) ? "Guest" : username;
        var modules = GetConfiguredModules();
        var mod = modules.FirstOrDefault(m => m.Id == moduleId);
        
        if (mod == null || answers == null || answers.Count != mod.Questions.Count)
        {
            return new { Passed = false, Score = 0, Message = "Invalid submission." };
        }

        int correct = 0;
        for (int i = 0; i < mod.Questions.Count; i++)
        {
            if (answers[i] == mod.Questions[i].answerIndex)
            {
                correct++;
            }
        }

        double percentage = Math.Round(((double)correct / mod.Questions.Count) * 100.0);
        bool passed = percentage >= 80.0; // 80% required to pass

        var progressList = LoadProgressData();
        var record = progressList.FirstOrDefault(p => string.Equals(p.Username, user, StringComparison.OrdinalIgnoreCase) && p.ModuleId == moduleId);
        if (record == null)
        {
            record = new UserProgress { Username = user, ModuleId = moduleId, TimeSpentSeconds = 0 };
            progressList.Add(record);
        }

        // Only update score if they passed or have a higher score
        if (passed || percentage > record.Score)
        {
            record.Score = (int)percentage;
            if (passed) record.Passed = true;
        }
        
        record.LastAccessed = DateTime.Now.ToString("o");
        SaveProgressData(progressList);

        return new { Passed = passed, Score = (int)percentage };
    }

    private static List<UserProgress> GetUserProgress(string user)
    {
        var all = LoadProgressData();
        return all.Where(p => string.Equals(p.Username, user, StringComparison.OrdinalIgnoreCase)).ToList();
    }

    // --- DATA ACCESS METHODS (JSON) ---

    public class TrainingConfigRoot
    {
        public List<ModuleConfig> modules { get; set; }
    }

    public class ModuleConfig
    {
        public int id { get; set; }
        public string title { get; set; }
        public string description { get; set; }
        public string pdfUrl { get; set; }
        public int pdfPageStart { get; set; }
        public int minTimeSeconds { get; set; }
        public List<Question> questions { get; set; }
        
        // Aliases for frontend API
        public int Id { get { return id; } }
        public string Title { get { return title; } }
        public string Description { get { return description; } }
        public string PdfUrl { get { return pdfUrl; } }
        public int PdfPageStart { get { return pdfPageStart; } }
        public int MinTimeSeconds { get { return minTimeSeconds; } }
        public List<Question> Questions { get { return questions; } }
    }

    public class Question
    {
        public string q { get; set; }
        public List<string> options { get; set; }
        public int answerIndex { get; set; }

        public string Text { get { return q; } }
        public List<string> Options { get { return options; } }
        public int AnswerIndex { get { return answerIndex; } }
    }

    public class UserProgress
    {
        public string Username { get; set; }
        public int ModuleId { get; set; }
        public bool Passed { get; set; }
        public int Score { get; set; }
        public int TimeSpentSeconds { get; set; }
        public string LastAccessed { get; set; }
    }

    private static List<ModuleConfig> GetConfiguredModules()
    {
        try
        {
            string path = HttpContext.Current.Server.MapPath("training_modules.json");
            if (File.Exists(path))
            {
                string json = File.ReadAllText(path);
                var js = new JavaScriptSerializer();
                var root = js.Deserialize<TrainingConfigRoot>(json);
                if (root != null && root.modules != null)
                {
                    // Ensure questions is never null to prevent frontend errors
                    foreach(var m in root.modules) {
                        if (m.questions == null) m.questions = new List<Question>();
                    }
                    return root.modules;
                }
            }
        }
        catch { }
        return new List<ModuleConfig>();
    }

    private static List<UserProgress> LoadProgressData()
    {
        string path = HttpContext.Current.Server.MapPath("App_Data/training_data.json");
        if (File.Exists(path))
        {
            try
            {
                string json = File.ReadAllText(path);
                var js = new JavaScriptSerializer();
                var data = js.Deserialize<List<UserProgress>>(json);
                if (data != null) return data;
            }
            catch { }
        }
        return new List<UserProgress>();
    }

    private static void SaveProgressData(List<UserProgress> data)
    {
        try
        {
            string path = HttpContext.Current.Server.MapPath("App_Data/training_data.json");
            string dir = Path.GetDirectoryName(path);
            if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);

            var js = new JavaScriptSerializer();
            string json = js.Serialize(data);
            File.WriteAllText(path, json);
        }
        catch { }
    }
}

<%@ Page Language="C#" AutoEventWireup="true" CodeFile="va_training.aspx.cs" Inherits="va_training" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>iDash Training Modules</title>
    <link rel="icon" type="image/png" href="Assets/branding/rfid.png" />
    <link rel="stylesheet" href="theme.css" />
            <script src="theme-init.js"></script>
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Expires" content="0" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <style>
        :root {
            --bg-base:      var(--bg);
            --panel-bg:     var(--card);
            --panel-border: var(--line);
            --text-main:    var(--text);
            --text-accent:  var(--muted);
            --highlight:    var(--accent);
            --success:      var(--accent-2);
            --accent:       #8B5CF6;
            --warning:      var(--warn);
            --orange:       #F97316;
            /* bucket colours */
            --b0: var(--accent-2); --b1: var(--accent); --b2: var(--warn); --b3: #F97316; --b4: var(--danger);
        }

        [data-theme="light"] {
            --shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
        }

        body {
            margin: 0;
            background: var(--bg);
            color: var(--text);
            font-family: 'Segoe UI', system-ui, Arial, sans-serif;
            display: flex;
            height: 100vh;
            overflow: hidden;
        }

        .sidebar {
            width: var(--sidebar-width);
            background: var(--bg);
            border-right: 1px solid var(--line);
            display: flex;
            flex-direction: column;
            overflow-y: auto;
        }

        .sidebar-header {
            padding: 20px;
            border-bottom: 1px solid var(--line);
        }

        .sidebar-header h2 {
            margin: 0;
            font-size: 18px;
            font-weight: 800;
            color: #fff;
        }

        .user-info {
            font-size: 13px;
            color: var(--accent2);
            margin-top: 5px;
            font-weight: 600;
        }

        .module-list {
            list-style: none;
            padding: 0;
            margin: 0;
        }

        .module-item {
            padding: 15px 20px;
            border-bottom: 1px solid var(--line);
            cursor: pointer;
            transition: all 0.2s;
        }

        .module-item:hover {
            background: var(--card);
        }

        .module-item.active {
            background: var(--chip);
            border-left: 4px solid var(--accent);
        }

        .module-item.locked {
            opacity: 0.5;
            cursor: not-allowed;
        }

        .module-title {
            font-size: 14px;
            font-weight: 700;
            margin-bottom: 4px;
        }

        .module-status {
            font-size: 11px;
            font-weight: 800;
            padding: 3px 8px;
            border-radius: 12px;
            display: inline-block;
        }

        .status-passed { background: color-mix(in srgb, var(--accent-2), transparent 85%); color: var(--accent2); }
        .status-pending { background: color-mix(in srgb, var(--accent), transparent 85%); color: var(--accent); }
        .status-locked { background: color-mix(in srgb, var(--danger), transparent 85%); color: var(--danger); }

        .main-content {
            flex: 1;
            display: flex;
            flex-direction: column;
            height: 100vh;
            overflow: hidden;
        }

        .top-bar {
            padding: 15px 24px;
            background: var(--card);
            border-bottom: 1px solid var(--line);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .top-bar h1 {
            margin: 0;
            font-size: 20px;
        }

        .btn {
            background: var(--accent);
            color: #000;
            border: none;
            padding: 8px 16px;
            border-radius: 6px;
            font-weight: 700;
            cursor: pointer;
            font-size: 14px;
            text-decoration: none;
        }
        
        .btn-outline {
            background: transparent;
            color: var(--accent);
            border: 1px solid var(--accent);
        }

        .btn:hover { opacity: 0.9; }

        .content-area {
            flex: 1;
            display: flex;
            padding: 24px;
            gap: 24px;
            overflow-y: auto;
        }

        .pdf-viewer {
            flex: 2;
            background: #fff;
            border-radius: 12px;
            border: 1px solid var(--line);
            overflow: hidden;
        }

        .quiz-panel {
            flex: 1;
            background: var(--card);
            border: 1px solid var(--line);
            border-radius: 12px;
            padding: 24px;
            display: flex;
            flex-direction: column;
            overflow-y: auto;
            min-width: 350px;
        }

        .quiz-title {
            font-size: 18px;
            font-weight: 800;
            margin-bottom: 8px;
            color: #fff;
        }
        
        .quiz-desc {
            font-size: 13px;
            color: var(--muted);
            margin-bottom: 24px;
            line-height: 1.5;
        }

        .question-block {
            margin-bottom: 20px;
            background: var(--chip);
            padding: 16px;
            border-radius: 8px;
            border: 1px solid var(--line);
        }

        .question-text {
            font-size: 15px;
            font-weight: 600;
            margin-bottom: 10px;
            color: #fff;
        }

        .option-label {
            display: flex;
            align-items: center;
            padding: 10px;
            margin-bottom: 6px;
            background:var(--chip);
            border: 1px solid var(--line);
            border-radius: 6px;
            cursor: pointer;
            transition: all 0.2s;
            font-size: 14px;
        }

        .option-label:hover {
            border-color: var(--accent);
            background: #151e32;
        }

        .option-label input {
            margin-right: 12px;
            accent-color: var(--accent);
        }

        #quiz-results {
            margin-top: 20px;
            padding: 16px;
            border-radius: 8px;
            display: none;
            font-weight: 700;
            text-align: center;
            font-size: 16px;
        }

        /* Loading Spinner */
        .spinner {
            border: 3px solid rgba(255,255,255,0.1);
            border-radius: 50%;
            border-top: 3px solid var(--accent);
            width: 24px;
            height: 24px;
            animation: spin 1s linear infinite;
            display: inline-block;
            vertical-align: middle;
            margin-right: 8px;
        }
        @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }

    </style>
</head>
<body>
    <form id="form1" runat="server">
        <asp:ScriptManager ID="ScriptManager1" runat="server" EnablePageMethods="true" />
        
        <div class="sidebar">
            <div class="sidebar-header">
                <h2>iDash LMS</h2>
                <div class="user-info">User: <asp:Label ID="LblUser" runat="server" /></div>
            </div>
            <ul class="module-list" id="module-list">
                <!-- Populated by JS -->
            </ul>
        </div>

        <div class="main-content">
            <div class="top-bar">
                <h1 id="header-title">Select a Module</h1>
                <div style="display:flex; gap: 10px; align-items:center;">
                    <span id="time-tracker" style="font-size:13px; color:var(--muted); font-family:monospace; font-weight:bold;">00:00</span>
                    <a href="index.aspx" class="nav-pill nav-pill-ghost">&#8962; Hub</a>
                </div>
            </div>

            <div class="content-area" id="content-area" style="display:none;">
                <div class="pdf-viewer">
                    <iframe id="pdf-frame" src="" width="100%" height="100%" frameborder="0"></iframe>
                </div>
                <div class="quiz-panel">
                    <div class="quiz-title" id="quiz-header">Module Quiz</div>
                    <div class="quiz-desc" id="quiz-desc"></div>
                    
                    <div id="quiz-questions">
                        <!-- Populated by JS -->
                    </div>

                    <button type="button" class="btn" id="btn-submit" onclick="submitQuiz()" style="width:100%; padding:14px; font-size:16px;">Submit Quiz</button>
                    <div id="quiz-results"></div>
                </div>
            </div>
            
            <div id="welcome-area" style="flex:1; display:flex; flex-direction:column; align-items:center; justify-content:center; color:var(--muted);">
                <h2>Welcome to iDash Training</h2>
                <p>Select a module from the sidebar to begin.</p>
            </div>
        </div>

        <asp:HiddenField ID="HidCurrentUser" runat="server" />

        <script>
            let currentModule = null;
            let activeTimeSeconds = 0;
            let timeInterval = null;
            let moduleData = [];
            let progressData = [];
            let currentUserName = '';

            document.addEventListener('DOMContentLoaded', () => {
                const hiddenElem = document.getElementById('<%= HidCurrentUser.ClientID %>');
                let hiddenUser = hiddenElem ? hiddenElem.value : 'Guest';
                
                if (!hiddenUser || hiddenUser === 'Guest') {
                    let localUser = localStorage.getItem('aw_lms_username');
                    if (!localUser) {
                        localUser = prompt("Please enter your Name or Employee ID to sign in:");
                        if (!localUser) localUser = "Guest";
                        localStorage.setItem('aw_lms_username', localUser);
                    }
                    currentUserName = localUser;
                } else {
                    currentUserName = hiddenUser;
                    localStorage.setItem('aw_lms_username', currentUserName);
                }
                
                const lblUser = document.getElementById('<%= LblUser.ClientID %>');
                if (lblUser) lblUser.innerText = currentUserName;

                loadModules();
            });

            function loadModules() {
                PageMethods.GetTrainingData(currentUserName, onDataLoaded, onDataError);
            }

            function onDataLoaded(response) {
                moduleData = response.Modules;
                progressData = response.Progress;
                renderSidebar();
            }

            function onDataError(err) {
                console.error("Error loading data:", err);
                alert("Failed to load training modules.");
            }

            function renderSidebar() {
                const list = document.getElementById('module-list');
                list.innerHTML = '';

                let previousPassed = true; // First module always unlocked

                moduleData.forEach((mod, index) => {
                    const prog = progressData.find(p => p.ModuleId === mod.Id);
                    const isPassed = prog && prog.Passed;
                    
                    // Locked if the previous module wasn't passed
                    const isLocked = !previousPassed;

                    const li = document.createElement('li');
                    li.className = 'module-item ' + (isLocked ? 'locked' : '');
                    if (currentModule && currentModule.Id === mod.Id) li.classList.add('active');

                    let statusHtml = '';
                    if (isPassed) {
                        statusHtml = `<span class="module-status status-passed">PASSED (${prog.Score}%)</span>`;
                    } else if (!isLocked) {
                        statusHtml = `<span class="module-status status-pending">PENDING</span>`;
                    } else {
                        statusHtml = `<span class="module-status status-locked">LOCKED</span>`;
                    }

                    li.innerHTML = `
                        <div class="module-title">${mod.Title}</div>
                        ${statusHtml}
                    `;

                    if (!isLocked) {
                        li.onclick = () => selectModule(mod.Id);
                    }

                    list.appendChild(li);
                    
                    if (!isPassed) previousPassed = false; // Lock subsequent modules
                });
            }

            function selectModule(id) {
                const mod = moduleData.find(m => m.Id === id);
                if (!mod) return;
                
                // Save time for previous module if leaving
                if (currentModule && activeTimeSeconds > 5) {
                    PageMethods.LogTime(currentUserName, currentModule.Id, activeTimeSeconds, ()=>{}, ()=>{});
                }

                currentModule = mod;
                activeTimeSeconds = 0;
                
                document.getElementById('welcome-area').style.display = 'none';
                document.getElementById('content-area').style.display = 'flex';
                document.getElementById('header-title').innerText = mod.Title;
                
                // Embed PDF with page parameter
                let pdfSrc = mod.PdfUrl;
                if(mod.PdfPageStart) pdfSrc += '#page=' + mod.PdfPageStart;
                document.getElementById('pdf-frame').src = pdfSrc;

                document.getElementById('quiz-desc').innerText = mod.Description;
                
                renderQuiz(mod);
                renderSidebar(); // update active state

                clearInterval(timeInterval);
                timeInterval = setInterval(() => {
                    activeTimeSeconds++;
                    const m = Math.floor(activeTimeSeconds / 60).toString().padStart(2, '0');
                    const s = (activeTimeSeconds % 60).toString().padStart(2, '0');
                    document.getElementById('time-tracker').innerText = `${m}:${s}`;
                    
                    // Periodically save time to server
                    if (activeTimeSeconds % 30 === 0) {
                        PageMethods.LogTime(currentUserName, currentModule.Id, 30, ()=>{}, ()=>{});
                    }
                }, 1000);
            }

            function renderQuiz(mod) {
                const container = document.getElementById('quiz-questions');
                container.innerHTML = '';
                
                document.getElementById('quiz-results').style.display = 'none';
                document.getElementById('btn-submit').style.display = 'block';

                const prog = progressData.find(p => p.ModuleId === mod.Id);
                const isPassed = prog && prog.Passed;

                mod.Questions.forEach((q, qIndex) => {
                    const block = document.createElement('div');
                    block.className = 'question-block';
                    
                    let optionsHtml = '';
                    q.Options.forEach((opt, oIndex) => {
                        optionsHtml += `
                            <label class="option-label">
                                <input type="radio" name="q_${qIndex}" value="${oIndex}" ${isPassed ? 'disabled' : ''} />
                                <span>${opt}</span>
                            </label>
                        `;
                    });

                    block.innerHTML = `
                        <div class="question-text">${qIndex + 1}. ${q.Text}</div>
                        ${optionsHtml}
                    `;
                    container.appendChild(block);
                });

                if (isPassed) {
                    document.getElementById('btn-submit').style.display = 'none';
                    const res = document.getElementById('quiz-results');
                    res.className = 'status-passed';
                    res.innerHTML = `You have already passed this module with ${prog.Score}%!`;
                    res.style.display = 'block';
                }
            }

            function submitQuiz() {
                if (!currentModule) return;

                const answers = [];
                let allAnswered = true;

                currentModule.Questions.forEach((q, qIndex) => {
                    const selected = document.querySelector(`input[name="q_${qIndex}"]:checked`);
                    if (selected) {
                        answers.push(parseInt(selected.value, 10));
                    } else {
                        allAnswered = false;
                    }
                });

                if (!allAnswered) {
                    alert("Please answer all questions before submitting.");
                    return;
                }

                document.getElementById('btn-submit').innerText = 'Grading...';
                document.getElementById('btn-submit').disabled = true;

                PageMethods.SubmitQuiz(currentUserName, currentModule.Id, answers, onQuizResult, onDataError);
            }

            function onQuizResult(response) {
                document.getElementById('btn-submit').innerText = 'Submit Quiz';
                document.getElementById('btn-submit').disabled = false;

                const res = document.getElementById('quiz-results');
                res.style.display = 'block';

                if (response.Passed) {
                    res.className = 'status-passed';
                    res.innerHTML = `Congratulations! You passed with ${response.Score}%.`;
                    document.getElementById('btn-submit').style.display = 'none';
                    
                    // Reload modules so next unlocks
                    setTimeout(loadModules, 2000);
                } else {
                    res.className = 'status-locked';
                    res.innerHTML = `You scored ${response.Score}%. You need at least 80% to pass. Please review the PDF and try again.`;
                }
            }
        </script>
    </form>
</body>
</html>



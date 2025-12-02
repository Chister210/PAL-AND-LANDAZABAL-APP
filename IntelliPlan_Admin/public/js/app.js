// Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyAmFo5zsviGPUl72wZo5kkgGZz2z5ekvD8",
  authDomain: "intelliplan-949ef.firebaseapp.com",
  projectId: "intelliplan-949ef",
  storageBucket: "intelliplan-949ef.firebasestorage.app",
  messagingSenderId: "157923135399",
  appId: "1:157923135399:web:fca532b81e15dfa5543082",
  measurementId: "G-X0JL8LZYBR"
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);
const auth = firebase.auth();
const db = firebase.firestore();

// Auth guard: redirect to login if not authenticated
auth.onAuthStateChanged(async (user) => {
  if (!user) {
    if (location.pathname.split('/').pop() !== 'login.html') {
      window.location.href = 'login.html';
    }
    return;
  }

  // Check if user is admin
  const userDoc = await db.collection('users').doc(user.uid).get();
  if (!userDoc.exists || userDoc.data().role !== 'admin') {
    await auth.signOut();
    localStorage.removeItem('adminLoggedIn');
    window.location.href = 'login.html';
    return;
  }

  // User is authenticated and is admin
  if (location.pathname.split('/').pop() === 'login.html') {
    window.location.href = 'index.html';
  } else {
    loadDashboardData();
  }
});

// Logout functionality
const logoutBtn = document.getElementById('logoutBtn');
if (logoutBtn) {
  logoutBtn.addEventListener('click', async () => {
    try {
      await auth.signOut();
      localStorage.removeItem('adminLoggedIn');
      window.location.href = 'login.html';
    } catch (error) {
      console.error('Logout error:', error);
    }
  });
}

// Load dashboard data from Firebase
async function loadDashboardData() {
  try {
    // Fetch users
    const usersSnapshot = await db.collection('users').get();
    const users = [];
    usersSnapshot.forEach(doc => {
      users.push({ id: doc.id, ...doc.data() });
    });

    // Fetch tasks
    const tasksSnapshot = await db.collection('tasks').get();
    const tasks = [];
    tasksSnapshot.forEach(doc => {
      tasks.push({ id: doc.id, ...doc.data() });
    });

    // Calculate stats
    const totalUsers = users.length;
    const totalTasks = tasks.length;
    
    // Active today (users who logged in today)
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const activeToday = users.filter(u => {
      const lastActive = u.lastActive?.toDate();
      return lastActive && lastActive >= today;
    }).length;

    // Tasks completed today
    const tasksCompletedToday = tasks.filter(t => {
      const completedAt = t.completedAt?.toDate();
      return completedAt && completedAt >= today && t.status === 'completed';
    }).length;

    // Update overview stats
    updateOverviewStats({
      totalUsers,
      activeToday,
      totalTasks,
      tasksCompletedToday
    });

    // Update user table
    updateUserTable(users);

    // Update charts
    updateCharts(users, tasks);

  } catch (error) {
    console.error('Error loading dashboard data:', error);
  }
}

function updateOverviewStats(stats) {
  const statsElements = {
    totalUsers: document.querySelector('[data-stat="totalUsers"]'),
    activeToday: document.querySelector('[data-stat="activeToday"]'),
    totalTasks: document.querySelector('[data-stat="totalTasks"]'),
    tasksCompletedToday: document.querySelector('[data-stat="tasksCompletedToday"]')
  };

  if (statsElements.totalUsers) statsElements.totalUsers.textContent = stats.totalUsers;
  if (statsElements.activeToday) statsElements.activeToday.textContent = stats.activeToday;
  if (statsElements.totalTasks) statsElements.totalTasks.textContent = stats.totalTasks;
  if (statsElements.tasksCompletedToday) statsElements.tasksCompletedToday.textContent = stats.tasksCompletedToday;
}

function updateUserTable(users) {
  const tbody = document.querySelector('#usersTable tbody');
  if (!tbody) return;

  tbody.innerHTML = '';
  users.slice(0, 50).forEach(user => {
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td>${user.name || 'Unknown'}</td>
      <td>${user.email || ''}</td>
      <td>${user.xp || 0}</td>
      <td>${user.level || 1}</td>
      <td>${user.currentStreak || 0} days</td>
      <td>${user.lastActive ? new Date(user.lastActive.toDate()).toLocaleDateString() : 'Never'}</td>
    `;
    tbody.appendChild(tr);
  });
}

function updateCharts(users, tasks) {
  // Task completion trend (last 7 days)
  const last7Days = [];
  const taskCounts = [];
  for (let i = 6; i >= 0; i--) {
    const date = new Date();
    date.setDate(date.getDate() - i);
    date.setHours(0, 0, 0, 0);
    last7Days.push(date.toLocaleDateString('en-US', { weekday: 'short' }));
    
    const nextDay = new Date(date);
    nextDay.setDate(nextDay.getDate() + 1);
    
    const count = tasks.filter(t => {
      const completedAt = t.completedAt?.toDate();
      return completedAt && completedAt >= date && completedAt < nextDay && t.status === 'completed';
    }).length;
    
    taskCounts.push(count);
  }

  // Update task trend chart if exists
  const taskTrendCanvas = document.getElementById('taskTrendChart');
  if (taskTrendCanvas) {
    new Chart(taskTrendCanvas, {
      type: 'line',
      data: {
        labels: last7Days,
        datasets: [{
          label: 'Tasks Completed',
          data: taskCounts,
          borderColor: '#6C63FF',
          backgroundColor: 'rgba(108, 99, 255, 0.1)',
          tension: 0.4
        }]
      },
      options: {
        responsive: true,
        plugins: {
          legend: { display: false }
        }
      }
    });
  }
}

// Minimal demo interactions and mock data to populate the admin UI.
const mock = {
  totalUsers: 1248,
  activeToday: 312,
  totalTasks: 8240,
  tasksCompletedToday: 542,
  techniqueUsage: {Pomodoro:58, 'Spaced Repetition':27, 'Active Recall':15},
  streaks: {"0": 420, "1-3": 360, "4-7": 280, ">7": 188},
  avgSession: {labels:['Mon','Tue','Wed','Thu','Fri','Sat','Sun'], data:[25,26,22,30,28,18,15]},
  users: [
    {id:'u_001',name:'Aisha Gomez',email:'aisha@example.com',tech:'Pomodoro',completed:124,streak:12,level:7,points:540,lastActive:'2025-11-14'},
    {id:'u_002',name:'Ben Carter',email:'ben@example.com',tech:'Spaced Repetition',completed:98,streak:3,level:5,points:320,lastActive:'2025-11-13'},
    {id:'u_003',name:'Chun Li',email:'chun@example.com',tech:'Active Recall',completed:210,streak:20,level:12,points:1200,lastActive:'2025-11-14'}
  ],
  tasksTimeseries: Array.from({length:30},(_,i)=>Math.floor(100+Math.random()*60)),
  tasksByTechnique: {Pomodoro:4200,'Spaced Repetition':2400,'Active Recall':1640},
  achievements: [{name:'7-day streak',count:320},{name:'100 tasks',count:112},{name:'Early Bird',count:42}],
  pointsEconomy: {earned:82000,spent:64000}
}

// Navigation
document.querySelectorAll('.sidebar nav li').forEach(li=>li.addEventListener('click',ev=>{
  document.querySelectorAll('.sidebar nav li').forEach(x=>x.classList.remove('active'))
  ev.target.classList.add('active')
  const t = ev.target.dataset.target
  document.querySelectorAll('.panel').forEach(p=>p.classList.remove('active'))
  const target = document.getElementById(t)
  if(target) target.classList.add('active')
  // Trigger resize so Chart.js recalculates sizes on panel change (mobile)
  setTimeout(()=>window.dispatchEvent(new Event('resize')),250)
}))

// Mobile sidebar toggle
const menuToggle = document.getElementById('menuToggle')
if(menuToggle){
  menuToggle.addEventListener('click', ()=>{
    document.querySelector('.app').classList.toggle('sidebar-open')
  })
  // close sidebar when clicking outside (mobile)
  document.addEventListener('click', (e)=>{
    const app = document.querySelector('.app')
    const sidebar = document.querySelector('.sidebar')
    if(!app.classList.contains('sidebar-open')) return
    if(sidebar.contains(e.target) || menuToggle.contains(e.target)) return
    app.classList.remove('sidebar-open')
  })
}

// Theme toggle (light / dark) - floating button
const themeButton = document.getElementById('themeToggle')
function setTheme(mode){
  if(mode === 'light'){
    document.documentElement.classList.add('light-theme')
    themeButton.textContent = '☀️'
    localStorage.setItem('theme','light')
  } else {
    document.documentElement.classList.remove('light-theme')
    themeButton.textContent = '🌙'
    localStorage.setItem('theme','dark')
  }
  // allow charts and other components to adapt
  window.dispatchEvent(new Event('resize'))
}

// Initialize theme from localStorage or system preference
;(function initTheme(){
  if(!themeButton) return
  const saved = localStorage.getItem('theme')
  if(saved){
    setTheme(saved)
    return
  }
  const prefersLight = window.matchMedia && window.matchMedia('(prefers-color-scheme: light)').matches
  setTheme(prefersLight ? 'light' : 'dark')
})()

if(themeButton){
  themeButton.addEventListener('click', ()=>{
    const isLight = document.documentElement.classList.contains('light-theme')
    setTheme(isLight ? 'dark' : 'light')
  })
  // keyboard accessibility (Enter/Space)
  themeButton.addEventListener('keydown', (e)=>{
    if(e.key === 'Enter' || e.key === ' '){ e.preventDefault(); themeButton.click() }
  })
}

// Confirmation modal utility (promise-based)
function openConfirm(title, message){
  return new Promise((resolve)=>{
    const modal = document.getElementById('confirmModal')
    const t = document.getElementById('confirmTitle')
    const m = document.getElementById('confirmMessage')
    const ok = document.getElementById('confirmOk')
    const cancel = document.getElementById('confirmCancel')
    if(!modal || !t || !m || !ok || !cancel){
      resolve(false)
      return
    }
    t.textContent = title || 'Confirm'
    m.textContent = message || 'Are you sure?'
    modal.setAttribute('aria-hidden','false')
    modal.classList.add('open')
    const cleanup = ()=>{
      modal.setAttribute('aria-hidden','true')
      modal.classList.remove('open')
      ok.removeEventListener('click', onOk)
      cancel.removeEventListener('click', onCancel)
    }
    const onOk = ()=>{ cleanup(); resolve(true) }
    const onCancel = ()=>{ cleanup(); resolve(false) }
    ok.addEventListener('click', onOk)
    cancel.addEventListener('click', onCancel)
  })
}

// Logout button handler (uses modal) - handled above in auth check


// Populate overview widgets
document.getElementById('totalUsers').textContent = mock.totalUsers
document.getElementById('activeToday').textContent = mock.activeToday
document.getElementById('totalTasks').textContent = mock.totalTasks
document.getElementById('tasksCompletedToday').textContent = mock.tasksCompletedToday

// Charts (Chart.js simple configs)
function createPie(id, labels, values, colors) {
  const ctx = document.getElementById(id).getContext('2d');
  return new Chart(ctx, {
    type: 'pie',
    data: {
      labels: labels,
      datasets: [{ data: values, backgroundColor: colors }]
    },
    options: { plugins: { legend: { labels: { color: '#fff' } } } }
  });
}

createPie('techniquePie', Object.keys(mock.techniqueUsage), Object.values(mock.techniqueUsage), ['#6C9EF8', '#FFB86B', '#7AE582']);
createPie('streakPie', Object.keys(mock.streaks), Object.values(mock.streaks), ['#7dd3fc', '#60a5fa', '#8b5cf6', '#f472b6']);

new Chart(document.getElementById('usageBar').getContext('2d'), {
  type: 'bar',
  data: {
    labels: mock.avgSession.labels,
    datasets: [{ label: 'Avg minutes', data: mock.avgSession.data, backgroundColor: '#6C9EF8' }]
  },
  options: { scales: { y: { ticks: { color: '#fff' } } }, plugins: { legend: { display: false } } }
});

new Chart(document.getElementById('tasksLine').getContext('2d'), {
  type: 'line',
  data: {
    labels: Array.from({ length: 30 }, (_, i) => i + 1),
    datasets: [{ label: 'Tasks', data: mock.tasksTimeseries, borderColor: '#7AE582', backgroundColor: 'rgba(122,229,130,0.08)' }]
  },
  options: { plugins: { legend: { labels: { color: '#fff' } } }, scales: { x: { ticks: { color: '#fff' } }, y: { ticks: { color: '#fff' } } } }
});

new Chart(document.getElementById('completeBar').getContext('2d'), {
  type: 'bar',
  data: {
    labels: ['Completed', 'Overdue'],
    datasets: [{ data: [mock.tasksCompletedToday, Math.max(10, Math.floor(Math.random() * 150))], backgroundColor: ['#4caf50', '#ff6b6b'] }]
  },
  options: { plugins: { legend: { display: false } } }
});

new Chart(document.getElementById('tasksByTechnique').getContext('2d'), {
  type: 'doughnut',
  data: {
    labels: Object.keys(mock.tasksByTechnique),
    datasets: [{ data: Object.values(mock.tasksByTechnique), backgroundColor: ['#6C9EF8', '#FFB86B', '#7AE582'] }]
  },
  options: { plugins: { legend: { labels: { color: '#fff' } } } }
});

new Chart(document.getElementById('pointsChart').getContext('2d'), {
  type: 'bar',
  data: {
    labels: ['Earned', 'Spent'],
    datasets: [{ data: [mock.pointsEconomy.earned, mock.pointsEconomy.spent], backgroundColor: ['#6C9EF8', '#ffb86b'] }]
  },
  options: { plugins: { legend: { display: false } } }
});

// Populate users table
function renderUsers(filter='all',search=''){
  const tbody = document.querySelector('#userTable tbody')
  tbody.innerHTML = ''
  const rows = mock.users.filter(u=>{
    if(filter!=='all' && u.tech!==filter) return false
    if(search && !(u.name.toLowerCase().includes(search)||u.email.toLowerCase().includes(search))) return false
    return true
  })
  rows.forEach(u=>{
    const tr = document.createElement('tr')
    tr.innerHTML = `<td>${u.id}</td><td>${u.name}</td><td>${u.email}</td><td>${u.tech}</td><td>${u.completed}</td><td>${u.streak}</td><td>${u.level}</td><td>${u.points}</td><td>${u.lastActive}</td><td><button class='btn' onclick="alert('View ${u.name}')">View</button> <button onclick=alert('Reset streak: ${u.id}')>Reset</button></td>`
    tbody.appendChild(tr)
  })
}

document.getElementById('filterTechnique').addEventListener('change',e=>renderUsers(e.target.value,document.getElementById('userSearch').value.trim().toLowerCase()))
document.getElementById('userSearch').addEventListener('input',e=>renderUsers(document.getElementById('filterTechnique').value,e.target.value.trim().toLowerCase()))
renderUsers()

// Topbar search filters users table (quick global search)
const topSearch = document.getElementById('topSearch')
if(topSearch){
  topSearch.addEventListener('input', (e)=>{
    const q = e.target.value.trim().toLowerCase()
    renderUsers(document.getElementById('filterTechnique').value, q)
  })
}

// Populate achievements
const achList = document.getElementById('achievementsList')
mock.achievements.forEach(a=>{const li=document.createElement('li');li.textContent=`${a.name} — ${a.count} users`;achList.appendChild(li)})

// Subjects demo
const subjectTable = document.querySelector('#subjectTable tbody')
const subjects = [{code:'IT101',name:'Intro to Computing',category:'Major',department:'IT',color:'#3b82f6'}]
subjects.forEach(s=>{const r=document.createElement('tr');r.innerHTML=`<td>${s.code}</td><td>${s.name}</td><td>${s.category}</td><td>${s.department}</td><td><span style='background:${s.color};padding:6px 8px;border-radius:6px'> </span></td><td><button onclick=alert('Edit ${s.code}')>Edit</button></td>`;subjectTable.appendChild(r)})

// Feedback demo
const fbT = document.querySelector('#feedbackTable tbody')
const feedbacks = [{id:'f_001',user:'u_001',type:'Suggestion',msg:'Add night-mode calendar',date:'2025-11-13',status:'Open'}]
feedbacks.forEach(f=>{const r=document.createElement('tr');r.innerHTML=`<td>${f.id}</td><td>${f.user}</td><td>${f.type}</td><td>${f.msg}</td><td>${f.date}</td><td>${f.status}</td><td><button onclick=alert('Reply ${f.id}')>Reply</button></td>`;fbT.appendChild(r)})

// Audit logs
const logs = ['New account created: u_010','Login failure: 2025-11-13 08:12','Admin edited: Achievement list']
document.getElementById('auditLogs').innerHTML = logs.map(l=>`<div class='muted'>${l}</div>`).join('')

// Small helper: expose alert-friendly global for inline handlers used above (demo only)
window.alert = window.alert

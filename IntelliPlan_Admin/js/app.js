// Admin Panel Version
const ADMIN_VERSION = '1.0.4';
console.log('🚀 IntelliPlan Admin Panel v' + ADMIN_VERSION + ' loaded');
console.log('📅 Build: ' + new Date().toISOString());

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

// Global data cache
let globalUsers = [];
let globalTasks = [];
let globalStudySessions = [];
let globalAchievements = [];
let globalSubjects = [];
let globalFeedback = [];
let globalAuditLogs = [];

// Real-time listeners
let usersUnsubscribe = null;
let tasksUnsubscribes = [];
let sessionsUnsubscribes = [];

// Pagination state
let currentPage = {
  users: 1,
  tasks: 1,
  feedback: 1,
  logs: 1
};
const itemsPerPage = 20;

// Auth guard
auth.onAuthStateChanged(async (user) => {
  if (!user) {
    if (location.pathname.split('/').pop() !== 'login.html') {
      window.location.href = 'login.html';
    }
    return;
  }

  const userDoc = await db.collection('users').doc(user.uid).get();
  if (!userDoc.exists || userDoc.data().role !== 'admin') {
    await auth.signOut();
    localStorage.removeItem('adminLoggedIn');
    window.location.href = 'login.html';
    return;
  }

  if (location.pathname.split('/').pop() === 'login.html') {
    window.location.href = 'index.html';
  } else {
    initializeDashboard();
  }
});

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

async function initializeDashboard() {
  showLoading(true);
  try {
    await Promise.all([
      loadUsers(),
      loadTasks(),
      loadStudySessions(),
      loadAchievements(),
      loadSubjects(),
      loadFeedback(),
      loadAuditLogs()
    ]);
    
    renderOverview();
    renderUserTable();
    renderTaskAnalytics();
    renderStudyTechniquePerformance();
    renderGamification();
    renderSubjects();
    renderFeedback();
    renderSystemLogs();
    
    showLoading(false);
  } catch (error) {
    console.error('Error initializing dashboard:', error);
    showError('Failed to load dashboard data. Please refresh the page.');
    showLoading(false);
  }
}

async function loadUsers() {
  try {
    // Unsubscribe from previous listener if exists
    if (usersUnsubscribe) {
      usersUnsubscribe();
    }
    
    console.log('📊 Setting up real-time users listener...');
    
    // Return a promise that resolves when first data is loaded
    return new Promise((resolve, reject) => {
      let firstLoad = true;
      
      // Set up real-time listener for users
      usersUnsubscribe = db.collection('users').onSnapshot(async (snapshot) => {
        console.log(`📊 Users snapshot received: ${snapshot.docs.length} users`);
        
        // Process all users in parallel for faster loading
        const userPromises = snapshot.docs.map(async (doc) => {
          const userData = { id: doc.id, ...doc.data() };
          
          // Fetch real-time gamification data
          try {
            const gamificationDoc = await db.collection('users').doc(doc.id).collection('gamification').doc('profile').get();
            if (gamificationDoc.exists) {
              const gamData = gamificationDoc.data();
              userData.experience = gamData.xp || 0;
              userData.xp = gamData.xp || 0;
              userData.studyPoints = gamData.studyPoints || 0;
              userData.level = gamData.level || 1;
              userData.currentStreak = gamData.streakDays || 0;
              userData.longestStreak = gamData.streakDays || 0;
              userData.lastStreakUpdate = gamData.updatedAt;
            }
          } catch (e) {
            console.error(`Error loading gamification for user ${doc.id}:`, e);
            // Set defaults if gamification data fails
            userData.experience = userData.studyPoints || userData.xp || 0;
            userData.level = 1;
            userData.currentStreak = 0;
          }
          
          // Count completed tasks in real-time
          try {
            const tasksSnapshot = await db.collection('users').doc(doc.id).collection('tasks')
              .where('status', '==', 'completed')
              .get();
            userData.tasksCompleted = tasksSnapshot.size;
            
            // Get total tasks count
            const allTasksSnapshot = await db.collection('users').doc(doc.id).collection('tasks').get();
            userData.totalTasks = allTasksSnapshot.size;
          } catch (e) {
            console.error(`Error loading tasks for user ${doc.id}:`, e);
            userData.tasksCompleted = 0;
            userData.totalTasks = 0;
          }
          
          return userData;
        });
        
        // Wait for all user data to be fetched
        globalUsers = await Promise.all(userPromises);
        
        console.log(`✅ Real-time update: Loaded ${globalUsers.length} users with live data`);
        console.log('Sample user data:', globalUsers[0]);
        
        // Re-render user table with updated data
        if (document.querySelector('#userTable')) {
          renderUserTable();
        }
        if (document.querySelector('.overview-grid')) {
          renderOverview();
        }
        
        // Resolve promise on first load
        if (firstLoad) {
          firstLoad = false;
          resolve();
        }
      }, (error) => {
        console.error('Error in users listener:', error);
        showError('Failed to load users: ' + error.message);
        reject(error);
      });
    });
    
  } catch (error) {
    console.error('Error loading users:', error);
    throw error;
  }
}

async function loadTasks() {
  try {
    const usersSnapshot = await db.collection('users').limit(100).get();
    const taskPromises = usersSnapshot.docs.map(async (userDoc) => {
      const tasksSnapshot = await db.collection('users').doc(userDoc.id).collection('tasks').limit(50).get();
      return tasksSnapshot.docs.map(taskDoc => ({
        id: taskDoc.id,
        userId: userDoc.id,
        ...taskDoc.data()
      }));
    });
    
    const tasksArrays = await Promise.all(taskPromises);
    globalTasks = tasksArrays.flat();
    console.log(`Loaded ${globalTasks.length} tasks`);
  } catch (error) {
    console.error('Error loading tasks:', error);
    throw error;
  }
}

async function loadStudySessions() {
  try {
    const usersSnapshot = await db.collection('users').limit(100).get();
    const sessionPromises = usersSnapshot.docs.map(async (userDoc) => {
      // Load regular study sessions - NO FILTERING
      const sessionsSnapshot = await db.collection('users').doc(userDoc.id).collection('study_sessions').limit(100).get();
      const sessions = sessionsSnapshot.docs.map(sessionDoc => ({
        id: sessionDoc.id,
        userId: userDoc.id,
        ...sessionDoc.data()
      }));
      
      // Log sessions for this user
      console.log(`👤 User ${userDoc.id}: ${sessions.length} sessions`);
      const userTechniques = {};
      sessions.forEach(s => {
        const tech = s.technique || 'undefined';
        userTechniques[tech] = (userTechniques[tech] || 0) + 1;
      });
      console.log('  Techniques:', userTechniques);
      
      // NOTE: Active Recall sessions are now saved to study_sessions by the app
      // No need to load from recall_sessions separately to avoid duplicates
      
      // NOTE: Spaced Repetition sessions are also saved to study_sessions by the app
      // No need to load from spaced_repetition separately to avoid duplicates
      
      return sessions;
    });
    
    const sessionArrays = await Promise.all(sessionPromises);
    // Include ALL sessions - don't filter by status or duration
    globalStudySessions = sessionArrays.flat();
    console.log(`\n📊 ========== TOTAL LOADED SESSIONS ==========`);
    console.log(`Loaded ${globalStudySessions.length} total study sessions`);
    
    // Count by technique
    const allTechniques = {};
    globalStudySessions.forEach(s => {
      const tech = s.technique || 'undefined';
      allTechniques[tech] = (allTechniques[tech] || 0) + 1;
    });
    
    console.log('📊 All techniques in database:', Object.keys(allTechniques));
    console.log('📊 Session counts by technique:', allTechniques);
    console.log('Session breakdown:', {
      all: globalStudySessions.length,
      pomodoro: globalStudySessions.filter(s => s.technique?.toLowerCase().includes('pomodoro')).length,
      activeRecall: globalStudySessions.filter(s => s.technique?.toLowerCase().includes('recall')).length,
      spacedRepetition: globalStudySessions.filter(s => {
        const tech = s.technique?.toLowerCase();
        return tech?.includes('spaced') || tech?.includes('repetition');
      }).length
    });
    console.log(`========================================\n`);
  } catch (error) {
    console.error('Error loading study sessions:', error);
    throw error;
  }
}

async function loadAchievements() {
  try {
    const usersSnapshot = await db.collection('users').limit(100).get();
    const achievementPromises = usersSnapshot.docs.map(async (userDoc) => {
      const achievementsSnapshot = await db.collection('users').doc(userDoc.id).collection('achievements').get();
      return achievementsSnapshot.docs.map(achDoc => ({
        id: achDoc.id,
        userId: userDoc.id,
        ...achDoc.data()
      }));
    });
    
    const achievementArrays = await Promise.all(achievementPromises);
    globalAchievements = achievementArrays.flat();
    console.log(`Loaded ${globalAchievements.length} achievements`);
  } catch (error) {
    console.error('Error loading achievements:', error);
    throw error;
  }
}

async function loadSubjects() {
  try {
    const snapshot = await db.collection('subjects').get();
    globalSubjects = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    console.log(`Loaded ${globalSubjects.length} subjects`);
  } catch (error) {
    console.error('Error loading subjects:', error);
    globalSubjects = [];
  }
}

async function loadFeedback() {
  try {
    const snapshot = await db.collection('feedback').orderBy('createdAt', 'desc').get();
    globalFeedback = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    console.log(`Loaded ${globalFeedback.length} feedback items`);
  } catch (error) {
    console.error('Error loading feedback:', error);
    globalFeedback = [];
  }
}

async function loadAuditLogs() {
  try {
    const snapshot = await db.collection('audit_logs')
      .orderBy('timestamp', 'desc')
      .limit(100)
      .get();
    globalAuditLogs = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    console.log(`Loaded ${globalAuditLogs.length} audit logs`);
  } catch (error) {
    console.error('Error loading audit logs:', error);
    globalAuditLogs = [];
  }
}

function renderOverview() {
  const totalUsers = globalUsers.length;
  
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  
  // Fix: Ensure activeToday is accurate - only count users with valid lastActive timestamp
  const activeUsersToday = globalUsers.filter(u => {
    if (!u.lastActive) return false;
    try {
      const lastActive = u.lastActive.toDate ? u.lastActive.toDate() : new Date(u.lastActive);
      // Validate the date is valid
      if (isNaN(lastActive.getTime())) return false;
      return lastActive >= today;
    } catch (e) {
      return false;
    }
  });
  const activeToday = activeUsersToday.length;
  
  console.log('👥 Active Today Debug:', {
    totalUsers: globalUsers.length,
    activeToday: activeToday,
    activeUsers: activeUsersToday.map(u => ({
      email: u.email,
      lastActive: u.lastActive?.toDate?.() || u.lastActive
    }))
  });
  
  const totalTasks = globalUsers.reduce((sum, user) => sum + (user.totalTasks || 0), 0);
  
  const tasksCompletedToday = globalUsers.reduce((sum, user) => {
    // For now, we'll use tasksCompleted count from user data
    // A more accurate implementation would need to check timestamps
    return sum + (user.tasksCompleted || 0);
  }, 0);
  
  // Study technique stats
  console.log('📊 All techniques in database:', globalStudySessions.map(s => s.technique));
  console.log('📊 Unique techniques:', [...new Set(globalStudySessions.map(s => s.technique))]);
  console.log('📊 Total sessions loaded:', globalStudySessions.length);
  
  // Use case-insensitive matching to handle any variations
  const pomoSessions = globalStudySessions.filter(s => {
    const tech = s.technique?.toString().toLowerCase();
    return tech === 'pomodoro' || tech?.includes('pomodoro');
  }).length;
  
  const arSessions = globalStudySessions.filter(s => {
    const tech = s.technique?.toString().toLowerCase();
    return tech === 'active_recall' || tech === 'activerecall' || tech?.includes('recall');
  }).length;
  
  const srCards = globalStudySessions.filter(s => {
    const tech = s.technique?.toString().toLowerCase();
    return tech === 'spaced_repetition' || tech === 'spacedrepetition' || tech?.includes('spaced') || tech?.includes('repetition');
  }).length;
  
  const totalStudyTime = globalStudySessions.reduce((sum, s) => sum + (s.durationMinutes || 0), 0);
  
  console.log('📊 Technique counts:', { 
    total: globalStudySessions.length,
    pomodoro: pomoSessions, 
    activeRecall: arSessions, 
    spacedRepetition: srCards,
    unclassified: globalStudySessions.length - (pomoSessions + arSessions + srCards)
  });
  
  // Update stat cards
  document.getElementById('totalUsers').textContent = totalUsers;
  document.getElementById('activeToday').textContent = activeToday || 0;
  document.getElementById('totalTasks').textContent = totalTasks;
  document.getElementById('tasksCompletedToday').textContent = tasksCompletedToday;
  
  // Update secondary stats
  document.getElementById('pomoSessions').textContent = pomoSessions;
  document.getElementById('arTests').textContent = arSessions;
  document.getElementById('srCards').textContent = srCards;
  document.getElementById('totalStudyTime').textContent = `${totalStudyTime} min`;
  
  // Generate insights
  const insightsList = document.getElementById('recentInsights');
  if (insightsList) {
    const insights = [];
    
    if (activeToday > totalUsers * 0.3) {
      insights.push({
        icon: '🎯',
        title: 'High Engagement',
        desc: `${((activeToday/totalUsers)*100).toFixed(0)}% of users active today`
      });
    }
    
    if (pomoSessions > 0) {
      insights.push({
        icon: '📚',
        title: 'Pomodoro Popular',
        desc: `${pomoSessions} Pomodoro sessions completed`
      });
    }
    
    if (tasksCompletedToday > 10) {
      insights.push({
        icon: '✅',
        title: 'Productive Day',
        desc: `${tasksCompletedToday} tasks completed today`
      });
    }
    
    if (totalStudyTime > 1000) {
      insights.push({
        icon: '⏱️',
        title: 'Study Time Milestone',
        desc: `${(totalStudyTime/60).toFixed(0)} hours of study logged`
      });
    }
    
    insightsList.innerHTML = insights.map(insight => `
      <div class="insight-item">
        <div class="insight-icon">${insight.icon}</div>
        <div class="insight-content">
          <div class="insight-title">${insight.title}</div>
          <div class="insight-desc">${insight.desc}</div>
        </div>
      </div>
    `).join('');
  }
  
  renderTechniquePieChart();
  renderUsageBarChart();
}

function renderTechniquePieChart() {
  const techniqueCount = {};
  globalStudySessions.forEach(session => {
    const technique = session.technique || 'Unknown';
    techniqueCount[technique] = (techniqueCount[technique] || 0) + 1;
  });
  
  const labels = Object.keys(techniqueCount);
  const data = Object.values(techniqueCount);
  const colors = ['#6C9EF8', '#FFB86B', '#7AE582', '#F472B6', '#8B5CF6'];
  
  const ctx = document.getElementById('techniquePie');
  if (ctx && ctx.chart) ctx.chart.destroy();
  
  if (ctx) {
    ctx.chart = new Chart(ctx, {
      type: 'pie',
      data: {
        labels: labels,
        datasets: [{
          data: data,
          backgroundColor: colors.slice(0, labels.length)
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: true,
        plugins: {
          legend: {
            labels: { color: getComputedStyle(document.documentElement).getPropertyValue('--text') }
          }
        }
      }
    });
  }
}

function renderStreakDistributionChart() {
  const streakRanges = {
    '0': 0,
    '1-7': 0,
    '8-30': 0,
    '31-90': 0,
    '90+': 0
  };
  
  globalUsers.forEach(u => {
    const streak = u.currentStreak || 0;
    if (streak === 0) streakRanges['0']++;
    else if (streak <= 7) streakRanges['1-7']++;
    else if (streak <= 30) streakRanges['8-30']++;
    else if (streak <= 90) streakRanges['31-90']++;
    else streakRanges['90+']++;
  });
  
  const ctx = document.getElementById('streakPie');
  if (ctx && ctx.chart) ctx.chart.destroy();
  
  if (ctx) {
    ctx.chart = new Chart(ctx, {
      type: 'doughnut',
      data: {
        labels: Object.keys(streakRanges),
        datasets: [{
          data: Object.values(streakRanges),
          backgroundColor: ['#9ca3af', '#6C9EF8', '#FFB86B', '#7AE582', '#F472B6']
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: true,
        plugins: {
          legend: {
            labels: { color: getComputedStyle(document.documentElement).getPropertyValue('--text') }
          }
        }
      }
    });
  }
}

function renderUsageBarChart() {
  const usageByDay = { Mon: 0, Tue: 0, Wed: 0, Thu: 0, Fri: 0, Sat: 0, Sun: 0 };
  const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  
  globalStudySessions.forEach(session => {
    if (!session.startedAt) return;
    const date = session.startedAt.toDate ? session.startedAt.toDate() : new Date(session.startedAt);
    const dayName = days[date.getDay()];
    const duration = session.durationMinutes || 0;
    usageByDay[dayName] += duration;
  });
  
  const ctx = document.getElementById('usageBar');
  if (ctx && ctx.chart) ctx.chart.destroy();
  
  if (ctx) {
    ctx.chart = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: days.slice(1).concat(days[0]),
        datasets: [{
          label: 'Minutes',
          data: days.slice(1).concat(days[0]).map(d => Math.round(usageByDay[d])),
          backgroundColor: '#6C9EF8'
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: true,
        scales: {
          y: {
            beginAtZero: true,
            ticks: { color: getComputedStyle(document.documentElement).getPropertyValue('--text') },
            grid: { color: 'rgba(255,255,255,0.05)' }
          },
          x: {
            ticks: { color: getComputedStyle(document.documentElement).getPropertyValue('--text') },
            grid: { display: false }
          }
        },
        plugins: {
          legend: { display: false }
        }
      }
    });
  }
}

function renderUserTable(filter = 'all', search = '') {
  const tbody = document.querySelector('#userTable tbody');
  if (!tbody) return;
  
  let filteredUsers = globalUsers;
  
  if (search) {
    filteredUsers = filteredUsers.filter(u => 
      (u.name && u.name.toLowerCase().includes(search)) ||
      (u.email && u.email.toLowerCase().includes(search)) ||
      (u.id && u.id.toLowerCase().includes(search))
    );
  }
  
  if (filter === 'active') {
    const weekAgo = new Date();
    weekAgo.setDate(weekAgo.getDate() - 7);
    filteredUsers = filteredUsers.filter(u => {
      if (!u.lastActive) return false;
      const lastActive = u.lastActive.toDate ? u.lastActive.toDate() : new Date(u.lastActive);
      return lastActive >= weekAgo;
    });
  } else if (filter === 'inactive') {
    const weekAgo = new Date();
    weekAgo.setDate(weekAgo.getDate() - 7);
    filteredUsers = filteredUsers.filter(u => {
      if (!u.lastActive) return true;
      const lastActive = u.lastActive.toDate ? u.lastActive.toDate() : new Date(u.lastActive);
      return lastActive < weekAgo;
    });
  }
  
  const totalItems = filteredUsers.length;
  const totalPages = Math.ceil(totalItems / itemsPerPage);
  const start = (currentPage.users - 1) * itemsPerPage;
  const end = start + itemsPerPage;
  const paginatedUsers = filteredUsers.slice(start, end);
  
  tbody.innerHTML = '';
  
  if (paginatedUsers.length === 0) {
    tbody.innerHTML = '<tr><td colspan="8" style="text-align:center;padding:24px;color:var(--muted)">No users found</td></tr>';
    renderPagination('userPagination', totalPages, currentPage.users, (page) => {
      currentPage.users = page;
      renderUserTable(filter, search);
    });
    return;
  }
  
  paginatedUsers.forEach(user => {
    const tr = document.createElement('tr');
    
    // Determine last active date
    let lastActiveDisplay = 'Never';
    if (user.lastActive) {
      lastActiveDisplay = formatDate(user.lastActive);
    } else if (user.createdAt) {
      lastActiveDisplay = formatDate(user.createdAt);
    }
    
    // Real-time data from app
    const streak = user.currentStreak || 0;
    const xp = user.experience || user.studyPoints || user.xp || 0;
    const tasksCompleted = user.tasksCompleted || 0;
    const totalTasks = user.totalTasks || 0;
    const level = user.level || 1;
    
    tr.innerHTML = `
      <td><strong>${user.name || 'Unknown'}</strong><br/><small style="color:var(--muted)">Level ${level}</small></td>
      <td style="font-size:12px;color:var(--muted)">${user.email || 'N/A'}</td>
      <td><span style="background:linear-gradient(135deg, #FF6B6B 0%, #FF8E53 100%);padding:4px 10px;border-radius:8px;font-size:13px;font-weight:bold;color:white">${streak} 🔥</span></td>
      <td><span style="background:var(--glass);padding:4px 10px;border-radius:8px;font-size:13px;font-weight:bold">${xp.toLocaleString()} XP</span></td>
      <td><span style="color:var(--success)">${tasksCompleted}</span> / ${totalTasks}</td>
      <td style="font-size:12px;color:var(--muted)">${lastActiveDisplay}</td>
      <td>
        <button class="btn" style="font-size:11px;padding:6px 10px;margin:2px" onclick="viewUserProfile('${user.id}')">📊 View</button>
        <button class="btn" style="font-size:11px;padding:6px 10px;margin:2px;background:var(--accent-2)" onclick="adjustUserXP('${user.id}')">⭐ XP</button>
        <button class="btn" style="font-size:11px;padding:6px 10px;margin:2px;background:var(--warning)" onclick="adjustUserStreak('${user.id}')">🔥 Streak</button>
      </td>
    `;
    tbody.appendChild(tr);
  });
  
  renderPagination('userPagination', totalPages, currentPage.users, (page) => {
    currentPage.users = page;
    renderUserTable(filter, search);
  });
}

async function viewUserProfile(userId) {
  const user = globalUsers.find(u => u.id === userId);
  if (!user) return;
  
  // Fetch real-time gamification data
  let gamificationData = {};
  try {
    const gamDoc = await db.collection('users').doc(userId).collection('gamification').doc('profile').get();
    if (gamDoc.exists) {
      gamificationData = gamDoc.data();
    }
  } catch (e) {
    console.error('Error fetching gamification data:', e);
  }
  
  // Fetch real-time tasks
  let completedTasks = 0;
  let totalTasks = 0;
  try {
    const tasksSnapshot = await db.collection('users').doc(userId).collection('tasks').get();
    totalTasks = tasksSnapshot.size;
    completedTasks = tasksSnapshot.docs.filter(doc => doc.data().status === 'completed').length;
  } catch (e) {
    console.error('Error fetching tasks:', e);
  }
  
  // Fetch real-time study sessions
  let totalStudyTime = 0;
  let sessionCount = 0;
  try {
    const sessionsSnapshot = await db.collection('users').doc(userId).collection('study_sessions').get();
    sessionCount = sessionsSnapshot.size;
    totalStudyTime = sessionsSnapshot.docs.reduce((sum, doc) => {
      const data = doc.data();
      return sum + (data.durationMinutes || 0);
    }, 0);
  } catch (e) {
    console.error('Error fetching study sessions:', e);
  }
  
  // Fetch achievements
  let achievements = [];
  try {
    const achievementsSnapshot = await db.collection('users').doc(userId).collection('achievements').get();
    achievements = achievementsSnapshot.docs.map(doc => {
      const data = doc.data();
      return {
        id: doc.id,
        title: data.title || data.name || doc.id,
        unlockedAt: data.unlockedAt || data.earnedAt || data.createdAt
      };
    }).sort((a, b) => {
      // Sort by unlock date, newest first
      const dateA = a.unlockedAt?.toDate ? a.unlockedAt.toDate() : new Date(a.unlockedAt || 0);
      const dateB = b.unlockedAt?.toDate ? b.unlockedAt.toDate() : new Date(b.unlockedAt || 0);
      return dateB - dateA;
    });
  } catch (e) {
    console.error('Error fetching achievements:', e);
  }
  
  const currentStreak = gamificationData.currentStreak || user.currentStreak || 0;
  const longestStreak = gamificationData.longestStreak || user.longestStreak || 0;
  const experience = gamificationData.experience || user.experience || user.studyPoints || user.xp || 0;
  const level = gamificationData.level || user.level || 1;
  
  // Build achievements list
  let achievementsText = '';
  if (achievements.length > 0) {
    achievementsText = '\n🏆 Achievements Unlocked:\n';
    achievements.forEach((ach, index) => {
      let date = 'Unknown date';
      if (ach.unlockedAt) {
        try {
          date = formatDate(ach.unlockedAt);
        } catch (e) {
          console.error('Error formatting achievement date:', e);
        }
      }
      achievementsText += `   ${index + 1}. ${ach.title} (${date})\n`;
    });
  } else {
    achievementsText = '\n🏆 Achievements: None unlocked yet';
  }
  
  const message = `
👤 User Profile (Real-Time Data)
━━━━━━━━━━━━━━━━━━━━━━━━━━━
Name: ${user.name || 'Unknown'}
Email: ${user.email || 'N/A'}
User ID: ${user.id}
━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎮 Level: ${level}
⭐ Experience: ${experience.toLocaleString()} XP
🔥 Current Streak: ${currentStreak} days
🏆 Longest Streak: ${longestStreak} days
✅ Tasks Completed: ${completedTasks}
📚 Total Tasks: ${totalTasks}
⏱️ Total Study Time: ${Math.round(totalStudyTime)} minutes (${(totalStudyTime / 60).toFixed(1)} hours)
📊 Study Sessions: ${sessionCount}${achievementsText}
━━━━━━━━━━━━━━━━━━━━━━━━━━━
Last Active: ${user.lastActive ? formatDate(user.lastActive) : 'Never'}
Joined: ${user.createdAt ? formatDate(user.createdAt) : 'Unknown'}
  `.trim();
  
  alert(message);
}

async function adjustUserXP(userId) {
  const user = globalUsers.find(u => u.id === userId);
  if (!user) return;
  
  // Fetch current XP from gamification subcollection
  let currentXP = 0;
  try {
    const gamDoc = await db.collection('users').doc(userId).collection('gamification').doc('profile').get();
    if (gamDoc.exists) {
      currentXP = gamDoc.data().xp || 0;
    }
  } catch (e) {
    currentXP = user.experience || user.studyPoints || user.xp || 0;
  }
  
  const xpChange = prompt(`Current XP: ${currentXP.toLocaleString()}\nEnter amount to add (negative to subtract):`);
  
  if (!xpChange || isNaN(xpChange)) return;
  
  const newXP = Math.max(0, currentXP + parseInt(xpChange));
  const newLevel = Math.floor(newXP / 1000) + 1; // Calculate level based on XP
  
  try {
    // Update in gamification subcollection (where the app reads from)
    await db.collection('users').doc(userId).collection('gamification').doc('profile').set({
      xp: newXP,
      level: newLevel,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
    
    // Also update root user document for backward compatibility
    await db.collection('users').doc(userId).update({ 
      studyPoints: newXP,
      xp: newXP,
      experience: newXP,
      level: newLevel
    });
    
    await logAuditEvent('XP_ADJUSTED', `Admin adjusted ${user.name}'s XP from ${currentXP} to ${newXP} (Level ${newLevel})`);
    
    alert(`✅ XP updated!\n${currentXP.toLocaleString()} → ${newXP.toLocaleString()} XP\nLevel: ${newLevel}`);
  } catch (error) {
    console.error('Error adjusting XP:', error);
    alert('Failed to adjust XP: ' + error.message);
  }
}

async function adjustUserStreak(userId) {
  const user = globalUsers.find(u => u.id === userId);
  if (!user) return;
  
  // Fetch current streak from gamification subcollection
  let currentStreak = 0;
  let longestStreak = 0;
  try {
    const gamDoc = await db.collection('users').doc(userId).collection('gamification').doc('profile').get();
    if (gamDoc.exists) {
      const data = gamDoc.data();
      currentStreak = data.streakDays || 0;
      longestStreak = data.streakDays || 0;
    }
  } catch (e) {
    currentStreak = user.currentStreak || 0;
    longestStreak = user.longestStreak || 0;
  }
  
  const streakChange = prompt(`Current Streak: ${currentStreak} days\nLongest Streak: ${longestStreak} days\n\nEnter new streak value:`);
  
  if (!streakChange || isNaN(streakChange)) return;
  
  const newStreak = Math.max(0, parseInt(streakChange));
  const newLongestStreak = Math.max(longestStreak, newStreak);
  
  try {
    // Update in gamification subcollection (where the app reads from)
    await db.collection('users').doc(userId).collection('gamification').doc('profile').set({
      streakDays: newStreak,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
    
    // Also update root user document for backward compatibility
    await db.collection('users').doc(userId).update({ 
      currentStreak: newStreak,
      longestStreak: newLongestStreak
    });
    
    await logAuditEvent('STREAK_ADJUSTED', `Admin adjusted ${user.name}'s streak from ${currentStreak} to ${newStreak} days`);
    
    alert(`✅ Streak updated!\nCurrent: ${currentStreak} → ${newStreak} days\nLongest: ${newLongestStreak} days`);
  } catch (error) {
    console.error('Error adjusting streak:', error);
    alert('Failed to adjust streak: ' + error.message);
  }
}

function renderTaskAnalytics() {
  renderTasksTimelineChart();
  renderCompletionVsOverdueChart();
  renderTasksBySubjectChart();
}

function renderTasksTimelineChart() {
  const tasksByDate = {};
  const today = new Date();
  
  for (let i = 29; i >= 0; i--) {
    const date = new Date(today);
    date.setDate(date.getDate() - i);
    const key = date.toISOString().split('T')[0];
    tasksByDate[key] = 0;
  }
  
  globalTasks.forEach(task => {
    if (!task.createdAt) return;
    const date = task.createdAt.toDate ? task.createdAt.toDate() : new Date(task.createdAt);
    const key = date.toISOString().split('T')[0];
    if (tasksByDate.hasOwnProperty(key)) {
      tasksByDate[key]++;
    }
  });
  
  const labels = Object.keys(tasksByDate).map(d => {
    const date = new Date(d);
    return `${date.getMonth() + 1}/${date.getDate()}`;
  });
  const data = Object.values(tasksByDate);
  
  const ctx = document.getElementById('tasksTimeline');
  if (ctx && ctx.chart) ctx.chart.destroy();
  
  if (ctx) {
    ctx.chart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: labels,
        datasets: [{
          label: 'Tasks Created',
          data: data,
          borderColor: '#6C9EF8',
          backgroundColor: 'rgba(108, 158, 248, 0.1)',
          tension: 0.3,
          fill: true
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: true,
        scales: {
          y: {
            beginAtZero: true,
            ticks: { color: getComputedStyle(document.documentElement).getPropertyValue('--text') },
            grid: { color: 'rgba(255,255,255,0.05)' }
          },
          x: {
            ticks: { 
              color: getComputedStyle(document.documentElement).getPropertyValue('--text'),
              maxTicksLimit: 10
            },
            grid: { display: false }
          }
        },
        plugins: {
          legend: { display: false }
        }
      }
    });
  }
}

function renderCompletionVsOverdueChart() {
  const completed = globalTasks.filter(t => t.status === 'completed').length;
  const pending = globalTasks.filter(t => t.status === 'pending' || !t.status).length;
  const overdue = globalTasks.filter(t => t.status === 'overdue').length;
  
  const ctx = document.getElementById('completionChart');
  if (ctx && ctx.chart) ctx.chart.destroy();
  
  if (ctx) {
    ctx.chart = new Chart(ctx, {
      type: 'doughnut',
      data: {
        labels: ['Completed', 'Pending', 'Overdue'],
        datasets: [{
          data: [completed, pending, overdue],
          backgroundColor: ['#7AE582', '#FFB86B', '#ff6b6b']
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: true,
        plugins: {
          legend: {
            labels: { color: getComputedStyle(document.documentElement).getPropertyValue('--text') }
          }
        }
      }
    });
  }
}

function renderTasksBySubjectChart() {
  const tasksBySubject = {};
  globalTasks.forEach(task => {
    // Handle different subject field formats
    let subject = 'No Subject';
    if (task.subject && typeof task.subject === 'string' && task.subject.trim()) {
      subject = task.subject.trim();
    } else if (task.subjectName && typeof task.subjectName === 'string' && task.subjectName.trim()) {
      subject = task.subjectName.trim();
    } else if (task.courseCode && typeof task.courseCode === 'string' && task.courseCode.trim()) {
      subject = task.courseCode.trim();
    }
    tasksBySubject[subject] = (tasksBySubject[subject] || 0) + 1;
  });
  
  const sorted = Object.entries(tasksBySubject)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 10);
  
  const labels = sorted.map(s => s[0]);
  const data = sorted.map(s => s[1]);
  
  const ctx = document.getElementById('subjectChart');
  if (ctx && ctx.chart) ctx.chart.destroy();
  
  if (ctx) {
    ctx.chart = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: labels,
        datasets: [{
          label: 'Tasks',
          data: data,
          backgroundColor: '#6C9EF8'
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: true,
        indexAxis: 'y',
        scales: {
          y: {
            ticks: { color: getComputedStyle(document.documentElement).getPropertyValue('--text') },
            grid: { display: false }
          },
          x: {
            beginAtZero: true,
            ticks: { color: getComputedStyle(document.documentElement).getPropertyValue('--text') },
            grid: { color: 'rgba(255,255,255,0.05)' }
          }
        },
        plugins: {
          legend: { display: false }
        }
      }
    });
  }
}

function renderStudyTechniquePerformance() {
  console.log('🔧 renderStudyTechniquePerformance called');
  console.log('📊 Total sessions available:', globalStudySessions.length);
  
  // Pomodoro sessions - use case-insensitive matching
  const pomoSessions = globalStudySessions.filter(s => {
    const tech = s.technique?.toString().toLowerCase();
    return tech === 'pomodoro' || tech?.includes('pomodoro');
  });
  
  console.log('🍅 Pomodoro sessions found:', pomoSessions.length);
  console.log('🍅 Sample Pomodoro session:', pomoSessions[0]);
  
  // Calculate total pomodoros completed across all sessions
  const totalPomodoros = pomoSessions.reduce((sum, s) => sum + (s.pomodoroCount || 0), 0);
  
  console.log('🍅 Total pomodoroCount sum:', totalPomodoros);
  
  const pomoPerDay = pomoSessions.length > 0 ? (pomoSessions.length / 30).toFixed(1) : '0.0';
  const pomoAvgLength = pomoSessions.length > 0 
    ? (pomoSessions.reduce((sum, s) => sum + (s.durationMinutes || 0), 0) / pomoSessions.length).toFixed(0) 
    : '25';
  const pomoCompleted = pomoSessions.filter(s => 
    s.status === 'completed' || 
    s.status === 'Completed' || 
    s.completed === true
  ).length;
  const pomoCompletionRatio = pomoSessions.length > 0 
    ? ((pomoCompleted / pomoSessions.length) * 100).toFixed(0) 
    : '100';
  
  // Update top stat cards
  const displayValue = totalPomodoros > 0 ? totalPomodoros : pomoSessions.length;
  console.log('🍅 Display value for pomoSessions:', displayValue);
  
  const pomoSessionsEl = document.getElementById('pomoSessions');
  if (pomoSessionsEl) {
    pomoSessionsEl.textContent = displayValue;
    console.log('✅ Updated pomoSessions element');
  } else {
    console.warn('⚠️ pomoSessions element not found');
  }
  
  const pomoSessionsDetailEl = document.getElementById('pomoSessionsDetail');
  if (pomoSessionsDetailEl) {
    pomoSessionsDetailEl.textContent = displayValue;
    console.log('✅ Updated pomoSessionsDetail element');
  } else {
    console.warn('⚠️ pomoSessionsDetail element not found');
  }
  
  // Update detailed cards with logging
  const pomoPerDayEl = document.getElementById('pomoPerDay');
  if (pomoPerDayEl) {
    pomoPerDayEl.textContent = pomoPerDay;
    console.log('✅ Updated pomoPerDay:', pomoPerDay);
  }
  
  const pomoLenEl = document.getElementById('pomoLen');
  if (pomoLenEl) {
    pomoLenEl.textContent = `${pomoAvgLength} min`;
    console.log('✅ Updated pomoLen:', pomoAvgLength);
  }
  
  const pomoCompEl = document.getElementById('pomoComp');
  if (pomoCompEl) {
    pomoCompEl.textContent = `${pomoCompletionRatio}%`;
    console.log('✅ Updated pomoComp:', pomoCompletionRatio);
  }
  
  // Spaced Repetition - use case-insensitive matching
  const srSessions = globalStudySessions.filter(s => {
    const tech = s.technique?.toString().toLowerCase();
    return tech === 'spaced_repetition' || tech?.includes('spaced') || tech?.includes('repetition');
  });
  const srCards = srSessions.length; // Count sessions as cards reviewed
  const srCorrect = srSessions.reduce((sum, s) => sum + (s.cardsCorrect || 0), 0);
  const srAcc = srCards > 0 ? ((srCorrect / srCards) * 100).toFixed(0) : '0';
  
  console.log('🔁 Spaced Repetition data:', { sessions: srSessions.length, cards: srCards, accuracy: srAcc });
  
  const srCardsEl = document.getElementById('srCards');
  if (srCardsEl) srCardsEl.textContent = srCards;
  
  const srCardsDetailEl = document.getElementById('srCardsDetail');
  if (srCardsDetailEl) {
    srCardsDetailEl.textContent = srCards;
    console.log('✅ Updated srCardsDetail (top stat) element:', srCards);
  }
  
  const srCardsReviewedEl = document.getElementById('srCardsReviewed');
  if (srCardsReviewedEl) {
    srCardsReviewedEl.textContent = srCards;
    console.log('✅ Updated srCardsReviewed (detail card) element:', srCards);
  }
  
  const srAccEl = document.getElementById('srAcc');
  if (srAccEl) srAccEl.textContent = `${srAcc}%`;
  
  // Active Recall - use case-insensitive matching
  const arSessions = globalStudySessions.filter(s => {
    const tech = s.technique?.toString().toLowerCase();
    return tech === 'active_recall' || tech?.includes('active') || tech?.includes('recall');
  });
  console.log('🧠 Active Recall sessions found:', arSessions.length);
  console.log('🧠 Active Recall data:', arSessions.map(s => ({
    id: s.id,
    technique: s.technique,
    totalQuestions: s.totalQuestions,
    correctAnswers: s.correctAnswers,
    startTime: s.startTime
  })));
  
  const arTests = arSessions.length;
  const arCorrect = arSessions.reduce((sum, s) => sum + (s.correctAnswers || 0), 0);
  const arTotal = arSessions.reduce((sum, s) => sum + (s.totalQuestions || 0), 0);
  const arAcc = arTotal > 0 ? ((arCorrect / arTotal) * 100).toFixed(0) : '0';
  
  console.log('🧠 Active Recall totals:', { tests: arTests, correct: arCorrect, total: arTotal, accuracy: arAcc });
  
  const arTestsEl = document.getElementById('arTests');
  if (arTestsEl) {
    arTestsEl.textContent = arTests;
    console.log('✅ Updated arTests element:', arTests);
  }
  
  const arTestsDetailEl = document.getElementById('arTestsDetail');
  if (arTestsDetailEl) {
    arTestsDetailEl.textContent = arTests;
    console.log('✅ Updated arTestsDetail (top stat) element:', arTests);
  }
  
  const arTestsCompletedEl = document.getElementById('arTestsCompleted');
  if (arTestsCompletedEl) {
    arTestsCompletedEl.textContent = arTests;
    console.log('✅ Updated arTestsCompleted (detail card) element:', arTests);
  }
  
  const arAccEl = document.getElementById('arAcc');
  if (arAccEl) arAccEl.textContent = `${arAcc}%`;
  
  // Log for debugging
  console.log('📊 Study Technique Performance:', {
    pomodoro: { sessions: pomoSessions.length, totalPomodoros, avgLength: pomoAvgLength, completion: pomoCompletionRatio },
    activeRecall: { tests: arTests, correct: arCorrect, total: arTotal, accuracy: arAcc },
    spacedRepetition: { cards: srCards, correct: srCorrect, accuracy: srAcc }
  });
}

function renderGamification() {
  renderAchievementsList();
}

function renderAchievementsList() {
  const achievementsList = document.getElementById('achievementsList');
  if (!achievementsList) return;
  
  const achievementStats = {};
  globalAchievements.forEach(ach => {
    const name = ach.title || ach.name || ach.achievementName || 'Unknown Achievement';
    if (!achievementStats[name]) {
      achievementStats[name] = { count: 0, category: ach.category || 'General' };
    }
    achievementStats[name].count++;
  });
  
  const sorted = Object.entries(achievementStats)
    .sort((a, b) => b[1].count - a[1].count)
    .slice(0, 10);
  
  achievementsList.innerHTML = '';
  
  if (sorted.length === 0) {
    achievementsList.innerHTML = '<li style="color:var(--text-muted);padding:12px;text-align:center">No achievements unlocked yet</li>';
    return;
  }
  
  sorted.forEach(([name, data]) => {
    const li = document.createElement('li');
    li.innerHTML = `
      <div style="display:flex;flex-direction:column;flex:1">
        <strong style="font-size:14px;color:var(--text-primary)">${name}</strong>
        <span style="color:var(--text-muted);font-size:12px;margin-top:4px">${data.category}</span>
      </div>
      <span style="background:var(--accent);color:white;padding:6px 12px;border-radius:6px;font-size:12px;font-weight:600">
        ${data.count}
      </span>
    `;
    achievementsList.appendChild(li);
  });
}

function renderPointsEconomyChart() {
  const totalEarned = globalUsers.reduce((sum, u) => sum + (u.totalPointsEarned || u.studyPoints || u.xp || 0), 0);
  const currentPoints = globalUsers.reduce((sum, u) => sum + (u.studyPoints || u.xp || 0), 0);
  
  const ctx = document.getElementById('pointsChart');
  if (ctx && ctx.chart) ctx.chart.destroy();
  
  if (ctx) {
    ctx.chart = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: ['Total Earned', 'Current Balance'],
        datasets: [{
          data: [totalEarned, currentPoints],
          backgroundColor: ['#6C9EF8', '#7AE582']
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: true,
        scales: {
          y: {
            beginAtZero: true,
            ticks: { color: getComputedStyle(document.documentElement).getPropertyValue('--text') },
            grid: { color: 'rgba(255,255,255,0.05)' }
          },
          x: {
            ticks: { color: getComputedStyle(document.documentElement).getPropertyValue('--text') },
            grid: { display: false }
          }
        },
        plugins: {
          legend: { display: false }
        }
      }
    });
  }
}

function renderSubjects(search = '') {
  const tbody = document.querySelector('#subjectTable tbody');
  if (!tbody) return;
  
  tbody.innerHTML = '';
  
  let filteredSubjects = globalSubjects;
  
  if (search) {
    filteredSubjects = filteredSubjects.filter(s => 
      (s.code && s.code.toLowerCase().includes(search)) ||
      (s.name && s.name.toLowerCase().includes(search)) ||
      (s.category && s.category.toLowerCase().includes(search)) ||
      (s.department && s.department.toLowerCase().includes(search))
    );
  }
  
  if (filteredSubjects.length === 0) {
    tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;padding:24px;color:var(--muted)">No subjects found.</td></tr>';
    return;
  }
  
  filteredSubjects.forEach(subject => {
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td><strong>${subject.code || 'N/A'}</strong></td>
      <td>${subject.name || 'Unnamed Subject'}</td>
      <td><span style="background:var(--glass);padding:4px 8px;border-radius:6px;font-size:12px">${subject.category || 'General'}</span></td>
      <td>${subject.department || 'N/A'}</td>
      <td><span style="background:${subject.color || '#6C9EF8'};width:32px;height:20px;display:inline-block;border-radius:4px;border:1px solid rgba(255,255,255,0.1)"></span></td>
      <td>
        <button class="btn" style="font-size:11px;padding:6px 10px;margin:2px" onclick="editSubject('${subject.id}')">Edit</button>
        <button class="btn" style="font-size:11px;padding:6px 10px;margin:2px;background:#ff6b6b" onclick="deleteSubject('${subject.id}')">Delete</button>
      </td>
    `;
    tbody.appendChild(tr);
  });
}

async function addSubject() {
  const code = prompt('Subject Code (e.g., IT101):');
  if (!code) return;
  
  const name = prompt('Subject Name:');
  if (!name) return;
  
  const category = prompt('Category (Major/Minor/Elective):') || 'General';
  const department = prompt('Department:') || 'N/A';
  const color = prompt('Color (hex code, e.g., #3b82f6):') || '#6C9EF8';
  
  try {
    await db.collection('subjects').add({
      code,
      name,
      category,
      department,
      color,
      createdAt: firebase.firestore.FieldValue.serverTimestamp(),
      createdBy: auth.currentUser.uid
    });
    
    await logAuditEvent('SUBJECT_CREATED', `Admin created subject: ${code} - ${name}`);
    
    alert('✅ Subject added successfully!');
    await loadSubjects();
    renderSubjects();
  } catch (error) {
    console.error('Error adding subject:', error);
    alert('Failed to add subject: ' + error.message);
  }
}

async function editSubject(subjectId) {
  const subject = globalSubjects.find(s => s.id === subjectId);
  if (!subject) return;
  
  const name = prompt('Subject Name:', subject.name);
  if (!name) return;
  
  const category = prompt('Category:', subject.category) || subject.category;
  const department = prompt('Department:', subject.department) || subject.department;
  const color = prompt('Color (hex):', subject.color) || subject.color;
  
  try {
    await db.collection('subjects').doc(subjectId).update({
      name,
      category,
      department,
      color,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    
    await logAuditEvent('SUBJECT_UPDATED', `Admin updated subject: ${subject.code} - ${name}`);
    
    alert('✅ Subject updated successfully!');
    await loadSubjects();
    renderSubjects();
  } catch (error) {
    console.error('Error updating subject:', error);
    alert('Failed to update subject: ' + error.message);
  }
}

async function deleteSubject(subjectId) {
  const subject = globalSubjects.find(s => s.id === subjectId);
  if (!subject) return;
  
  if (!confirm(`Delete "${subject.name}"? This cannot be undone.`)) return;
  
  try {
    await db.collection('subjects').doc(subjectId).delete();
    
    await logAuditEvent('SUBJECT_DELETED', `Admin deleted subject: ${subject.code} - ${subject.name}`);
    
    alert('✅ Subject deleted successfully!');
    await loadSubjects();
    renderSubjects();
  } catch (error) {
    console.error('Error deleting subject:', error);
    alert('Failed to delete subject: ' + error.message);
  }
}

function renderFeedback(search = '') {
  const tbody = document.querySelector('#feedbackTable tbody');
  if (!tbody) return;
  
  let filteredFeedback = globalFeedback;
  
  if (search) {
    filteredFeedback = filteredFeedback.filter(f => {
      const user = globalUsers.find(u => u.id === f.userId);
      const userName = user ? user.name : '';
      return (userName && userName.toLowerCase().includes(search)) ||
             (f.message && f.message.toLowerCase().includes(search)) ||
             (f.category && f.category.toLowerCase().includes(search));
    });
  }
  
  const totalItems = filteredFeedback.length;
  const totalPages = Math.ceil(totalItems / itemsPerPage);
  const start = (currentPage.feedback - 1) * itemsPerPage;
  const end = start + itemsPerPage;
  const paginatedFeedback = filteredFeedback.slice(start, end);
  
  tbody.innerHTML = '';
  
  if (paginatedFeedback.length === 0) {
    tbody.innerHTML = '<tr><td colspan="7" style="text-align:center;padding:24px;color:var(--muted)">No feedback submitted yet</td></tr>';
    renderPagination('feedbackPagination', totalPages, currentPage.feedback, (page) => {
      currentPage.feedback = page;
      renderFeedback();
    });
    return;
  }
  
  paginatedFeedback.forEach(feedback => {
    const user = globalUsers.find(u => u.id === feedback.userId);
    const userName = user ? user.name : 'Unknown User';
    
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td style="font-family:monospace;font-size:11px;color:var(--muted)">${feedback.id.substring(0, 8)}...</td>
      <td>${userName}</td>
      <td><span style="background:var(--glass);padding:4px 8px;border-radius:6px;font-size:12px">${feedback.type || 'General'}</span></td>
      <td style="max-width:300px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${feedback.message || feedback.content || feedback.feedbackText || 'No message'}</td>
      <td style="font-size:12px;color:var(--muted)">${feedback.createdAt ? formatDate(feedback.createdAt) : 'N/A'}</td>
      <td><span style="background:${feedback.status === 'resolved' ? '#4CAF50' : '#FFB86B'};padding:4px 8px;border-radius:6px;font-size:11px;color:#000;font-weight:600">${feedback.status || 'open'}</span></td>
      <td>
        <button class="btn" style="font-size:11px;padding:6px 10px;margin:2px" onclick="viewFeedback('${feedback.id}')">View</button>
        ${feedback.status !== 'resolved' ? `<button class="btn" style="font-size:11px;padding:6px 10px;margin:2px;background:var(--accent-2)" onclick="markFeedbackResolved('${feedback.id}')">Resolve</button>` : ''}
      </td>
    `;
    tbody.appendChild(tr);
  });
  
  renderPagination('feedbackPagination', totalPages, currentPage.feedback, (page) => {
    currentPage.feedback = page;
    renderFeedback();
  });
}

async function viewFeedback(feedbackId) {
  const feedback = globalFeedback.find(f => f.id === feedbackId);
  if (!feedback) return;
  
  const user = globalUsers.find(u => u.id === feedback.userId);
  const userName = user ? user.name : 'Unknown User';
  
  const message = `
📝 Feedback Details
━━━━━━━━━━━━━━━━━━━━━━━━━━━
ID: ${feedback.id}
From: ${userName} (${feedback.userId})
Type: ${feedback.type || 'General'}
Status: ${feedback.status || 'open'}
Rating: ${feedback.rating ? '⭐'.repeat(feedback.rating) : 'N/A'}
Date: ${feedback.createdAt ? formatDate(feedback.createdAt) : 'N/A'}
━━━━━━━━━━━━━━━━━━━━━━━━━━━
Message:
${feedback.message || feedback.content || feedback.feedbackText || 'No message'}
${feedback.suggestions ? '\n\nSuggestions:\n' + feedback.suggestions : ''}
  `.trim();
  
  alert(message);
}

async function markFeedbackResolved(feedbackId) {
  try {
    await db.collection('feedback').doc(feedbackId).update({
      status: 'resolved',
      resolvedAt: firebase.firestore.FieldValue.serverTimestamp(),
      resolvedBy: auth.currentUser.uid
    });
    
    await logAuditEvent('FEEDBACK_RESOLVED', `Admin resolved feedback: ${feedbackId}`);
    
    alert('✅ Feedback marked as resolved!');
    await loadFeedback();
    renderFeedback();
  } catch (error) {
    console.error('Error resolving feedback:', error);
    alert('Failed to resolve feedback: ' + error.message);
  }
}

function renderSystemLogs(search = '') {
  const logsContainer = document.getElementById('auditLogs');
  if (!logsContainer) return;
  
  let filteredLogs = globalAuditLogs;
  
  if (search) {
    filteredLogs = filteredLogs.filter(log => 
      (log.type && log.type.toLowerCase().includes(search)) ||
      (log.message && log.message.toLowerCase().includes(search)) ||
      (log.description && log.description.toLowerCase().includes(search))
    );
  }
  
  const totalItems = filteredLogs.length;
  const totalPages = Math.ceil(totalItems / itemsPerPage);
  const start = (currentPage.logs - 1) * itemsPerPage;
  const end = start + itemsPerPage;
  const paginatedLogs = filteredLogs.slice(start, end);
  
  logsContainer.innerHTML = '';
  
  if (paginatedLogs.length === 0) {
    logsContainer.innerHTML = '<div style="color:var(--muted);padding:12px">No audit logs yet</div>';
    renderPagination('logsPagination', totalPages, currentPage.logs, (page) => {
      currentPage.logs = page;
      renderSystemLogs();
    });
    return;
  }
  
  paginatedLogs.forEach(log => {
    const div = document.createElement('div');
    div.style.padding = '10px';
    div.style.borderBottom = '1px solid rgba(255,255,255,0.02)';
    div.style.fontSize = '13px';
    
    const timestamp = log.timestamp ? formatDate(log.timestamp) : 'Unknown time';
    const icon = getLogIcon(log.type);
    
    div.innerHTML = `
      <div style="display:flex;justify-content:space-between;align-items:start">
        <div style="flex:1">
          <span style="margin-right:8px">${icon}</span>
          <strong>${log.type || 'UNKNOWN'}</strong>
          <div style="color:var(--muted);margin-top:4px;margin-left:24px">${log.message || log.description || 'No description'}</div>
        </div>
        <span style="color:var(--muted);font-size:11px;white-space:nowrap;margin-left:12px">${timestamp}</span>
      </div>
    `;
    logsContainer.appendChild(div);
  });
  
  renderPagination('logsPagination', totalPages, currentPage.logs, (page) => {
    currentPage.logs = page;
    renderSystemLogs();
  });
}

function getLogIcon(type) {
  const icons = {
    'LOGIN_SUCCESS': '✅',
    'LOGIN_FAILURE': '❌',
    'USER_CREATED': '👤',
    'XP_ADJUSTED': '⭐',
    'STREAK_RESET': '🔥',
    'SUBJECT_CREATED': '📘',
    'SUBJECT_UPDATED': '📝',
    'SUBJECT_DELETED': '🗑️',
    'FEEDBACK_RESOLVED': '✔️',
    'FEEDBACK_SUBMITTED': '💬',
    'ADMIN_ACTION': '⚙️'
  };
  return icons[type] || '📋';
}

async function logAuditEvent(type, message) {
  try {
    await db.collection('audit_logs').add({
      type,
      message,
      timestamp: firebase.firestore.FieldValue.serverTimestamp(),
      adminId: auth.currentUser.uid,
      adminEmail: auth.currentUser.email
    });
  } catch (error) {
    console.error('Error logging audit event:', error);
  }
}

function renderPagination(containerId, totalPages, currentPageNum, onPageChange) {
  const container = document.getElementById(containerId);
  if (!container) return;
  
  container.innerHTML = '';
  
  if (totalPages <= 1) return;
  
  const prevBtn = document.createElement('button');
  prevBtn.textContent = '←';
  prevBtn.disabled = currentPageNum === 1;
  prevBtn.onclick = () => onPageChange(currentPageNum - 1);
  container.appendChild(prevBtn);
  
  const startPage = Math.max(1, currentPageNum - 2);
  const endPage = Math.min(totalPages, startPage + 4);
  
  for (let i = startPage; i <= endPage; i++) {
    const btn = document.createElement('button');
    btn.textContent = i;
    btn.className = i === currentPageNum ? 'active' : '';
    btn.onclick = () => onPageChange(i);
    container.appendChild(btn);
  }
  
  const nextBtn = document.createElement('button');
  nextBtn.textContent = '→';
  nextBtn.disabled = currentPageNum === totalPages;
  nextBtn.onclick = () => onPageChange(currentPageNum + 1);
  container.appendChild(nextBtn);
}

function formatDate(timestamp) {
  if (!timestamp) return 'N/A';
  
  let date;
  if (timestamp.toDate) {
    date = timestamp.toDate();
  } else if (timestamp instanceof Date) {
    date = timestamp;
  } else {
    date = new Date(timestamp);
  }
  
  const now = new Date();
  const diffMs = now - date;
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);
  
  if (diffMins < 1) return 'Just now';
  if (diffMins < 60) return `${diffMins}m ago`;
  if (diffHours < 24) return `${diffHours}h ago`;
  if (diffDays < 7) return `${diffDays}d ago`;
  
  return date.toLocaleDateString('en-US', { 
    month: 'short', 
    day: 'numeric', 
    year: date.getFullYear() !== now.getFullYear() ? 'numeric' : undefined 
  });
}

function showLoading(show) {
  if (show) {
    console.log('Loading dashboard data...');
  } else {
    console.log('Dashboard data loaded successfully');
  }
}

function showError(message) {
  alert('❌ Error: ' + message);
}

document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('.sidebar nav li').forEach(li => {
    li.addEventListener('click', (ev) => {
      document.querySelectorAll('.sidebar nav li').forEach(x => x.classList.remove('active'));
      ev.target.classList.add('active');
      const target = ev.target.dataset.target;
      document.querySelectorAll('.panel').forEach(p => p.classList.remove('active'));
      const panel = document.getElementById(target);
      if (panel) panel.classList.add('active');
      setTimeout(() => window.dispatchEvent(new Event('resize')), 250);
    });
  });

  const menuToggle = document.getElementById('menuToggle');
  if (menuToggle) {
    menuToggle.addEventListener('click', () => {
      document.querySelector('.app').classList.toggle('sidebar-open');
    });
  }

  const filterTechnique = document.getElementById('filterTechnique');
  const userSearch = document.getElementById('userSearch');
  
  if (filterTechnique) {
    filterTechnique.addEventListener('change', (e) => {
      renderUserTable(e.target.value, userSearch ? userSearch.value.trim().toLowerCase() : '');
    });
  }
  
  if (userSearch) {
    userSearch.addEventListener('input', (e) => {
      renderUserTable(
        filterTechnique ? filterTechnique.value : 'all',
        e.target.value.trim().toLowerCase()
      );
    });
  }

  const topSearch = document.getElementById('topSearch');
  if (topSearch) {
    topSearch.addEventListener('input', (e) => {
      const query = e.target.value.trim().toLowerCase();
      
      // Get current active panel
      const activePanel = document.querySelector('.panel.active');
      const activePanelId = activePanel ? activePanel.id : 'overview';
      
      // Search based on active section
      switch(activePanelId) {
        case 'users':
          const filterTechnique = document.getElementById('filterTechnique');
          renderUserTable(
            filterTechnique ? filterTechnique.value : 'all',
            query
          );
          break;
          
        case 'tasks':
          renderTaskAnalytics(query);
          break;
          
        case 'subjects':
          renderSubjects(query);
          break;
          
        case 'feedback':
          renderFeedback(query);
          break;
          
        case 'system':
          renderSystemLogs(query);
          break;
          
        default:
          // For overview and other sections, show search results summary
          if (query) {
            showSearchResults(query);
          }
      }
    });
  }

  const addSubjectBtn = document.getElementById('addSubject');
  if (addSubjectBtn) {
    addSubjectBtn.addEventListener('click', addSubject);
  }

  // Initialize theme toggle
  console.log('🎨 Initializing theme toggle...');
  initializeThemeToggle();
});

function initializeThemeToggle() {
  const themeButton = document.getElementById('themeToggle');
  console.log('🎨 Theme button found:', !!themeButton);
  if (!themeButton) {
    console.error('❌ Theme toggle button not found!');
    return;
  }

  function setTheme(mode) {
    console.log('🎨 Setting theme to:', mode);
    if (mode === 'light') {
      document.documentElement.classList.add('light-theme');
      themeButton.textContent = '☀️';
      localStorage.setItem('theme', 'light');
    } else {
      document.documentElement.classList.remove('light-theme');
      themeButton.textContent = '🌙';
      localStorage.setItem('theme', 'dark');
    }
    window.dispatchEvent(new Event('resize'));
  }

  const saved = localStorage.getItem('theme');
  console.log('🎨 Saved theme:', saved);
  if (saved) {
    setTheme(saved);
  } else {
    const prefersLight = window.matchMedia && window.matchMedia('(prefers-color-scheme: light)').matches;
    setTheme(prefersLight ? 'light' : 'dark');
  }

  themeButton.addEventListener('click', () => {
    const isLight = document.documentElement.classList.contains('light-theme');
    console.log('🎨 Theme toggle clicked, current isLight:', isLight);
    setTheme(isLight ? 'dark' : 'light');
  });
  
  console.log('✅ Theme toggle initialized successfully');
}

function showSearchResults(query) {
  // Search across all data
  const userResults = globalUsers.filter(u => 
    (u.name && u.name.toLowerCase().includes(query)) ||
    (u.email && u.email.toLowerCase().includes(query))
  );
  
  const taskResults = globalTasks.filter(t => 
    (t.title && t.title.toLowerCase().includes(query)) ||
    (t.subject && t.subject.toLowerCase().includes(query))
  );
  
  const subjectResults = globalSubjects.filter(s => 
    (s.code && s.code.toLowerCase().includes(query)) ||
    (s.name && s.name.toLowerCase().includes(query))
  );
  
  const feedbackResults = globalFeedback.filter(f => 
    (f.message && f.message.toLowerCase().includes(query))
  );
  
  // Show toast notification with results
  const total = userResults.length + taskResults.length + subjectResults.length + feedbackResults.length;
  
  console.log(`Search results for "${query}":`, {
    users: userResults.length,
    tasks: taskResults.length,
    subjects: subjectResults.length,
    feedback: feedbackResults.length,
    total: total
  });
}

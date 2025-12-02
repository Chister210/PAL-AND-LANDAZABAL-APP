# IntelliPlan Data Dictionary

## Table 1: Users Collection
| Attribute | Description | Data Type | Constraints | PK/FK |
|-----------|-------------|-----------|-------------|-------|
| user_id | Unique identifier for each user | String | NOT NULL | PK |
| first_name | First name of the user | String | NOT NULL | |
| last_name | Last name of the user | String | NOT NULL | |
| email | Email address of the user | String | UNIQUE, NOT NULL | |
| password | Encrypted password for authentication | String | NOT NULL | |
| userType | Type of user (student) | ENUM | DEFAULT 'student' | |
| displayName | Display name shown in the app | String | NOT NULL | |
| phone | Contact phone number | String | | |
| level | Current level of the user | Integer | DEFAULT 1 | |
| experience | Total experience points | Integer | DEFAULT 0 | |
| studyTechnique | Preferred study technique | String | | |
| createdAt | Account creation timestamp | Timestamp | NOT NULL | |
| lastLoginAt | Last login timestamp | Timestamp | | |

## Table 2: Tasks Collection
| Attribute | Description | Data Type | Constraints | PK/FK |
|-----------|-------------|-----------|-------------|-------|
| task_id | Unique identifier for each task | String | NOT NULL | PK |
| user_id | Reference to task owner | String | NOT NULL | FK → Users(user_id) |
| title | Title of the task | String | NOT NULL | |
| description | Detailed description | String | | |
| status | Current status (todo/progress/done) | ENUM | DEFAULT 'todo' | |
| priority | Priority level (low/medium/high) | ENUM | DEFAULT 'medium' | |
| type | Type of task (homework/exam/project) | ENUM | NOT NULL | |
| subject | Subject/course code | String | | |
| deadline | Due date and time | Timestamp | | |
| createdAt | Task creation timestamp | Timestamp | NOT NULL | |
| completedAt | Task completion timestamp | Timestamp | | |
| teamId | Reference to team (if collaborative) | String | | FK → Teams(team_id) |

## Table 3: Study_Sessions Collection
| Attribute | Description | Data Type | Constraints | PK/FK |
|-----------|-------------|-----------|-------------|-------|
| session_id | Unique identifier for session | String | NOT NULL | PK |
| user_id | Reference to user | String | NOT NULL | FK → Users(user_id) |
| technique | Study technique used | String | NOT NULL | |
| startTime | Session start time | Timestamp | NOT NULL | |
| endTime | Session end time | Timestamp | | |
| durationMinutes | Duration in minutes | Integer | | |
| topic | Study topic | String | | |
| courseCode | Course code | String | | |
| pomodoroCount | Number of pomodoros completed | Integer | DEFAULT 0 | |
| breakCount | Number of breaks taken | Integer | DEFAULT 0 | |
| productivityScore | Productivity rating | Integer | CHECK (1-10) | |
| notes | Session notes | String | | |

## Table 4: Achievements Collection
| Attribute | Description | Data Type | Constraints | PK/FK |
|-----------|-------------|-----------|-------------|-------|
| achievement_id | Unique identifier | String | NOT NULL | PK |
| user_id | Reference to user | String | NOT NULL | FK → Users(user_id) |
| name | Achievement name | String | NOT NULL | |
| description | Achievement description | String | | |
| category | Category type | ENUM | NOT NULL | |
| unlocked | Whether achievement is unlocked | Boolean | DEFAULT false | |
| unlockedAt | Unlock timestamp | Timestamp | | |
| xpReward | XP points awarded | Integer | CHECK (>0) | |
| iconName | Icon identifier | String | | |
| tier | Difficulty tier (1-3) | Integer | CHECK (1-3) | |

## Table 5: Classes Collection
| Attribute | Description | Data Type | Constraints | PK/FK |
|-----------|-------------|-----------|-------------|-------|
| class_id | Unique identifier | String | NOT NULL | PK |
| user_id | Reference to user | String | NOT NULL | FK → Users(user_id) |
| name | Class name | String | NOT NULL | |
| courseCode | Course code | String | NOT NULL | |
| instructor | Instructor name | String | | |
| dayOfWeek | Day of the week | Integer | CHECK (0-6) | |
| startTime | Class start time | String | NOT NULL | |
| endTime | Class end time | String | NOT NULL | |
| location | Classroom location | String | | |
| color | Display color | String | | |

## Table 6: Assignments Collection
| Attribute | Description | Data Type | Constraints | PK/FK |
|-----------|-------------|-----------|-------------|-------|
| assignment_id | Unique identifier | String | NOT NULL | PK |
| user_id | Reference to user | String | NOT NULL | FK → Users(user_id) |
| title | Assignment title | String | NOT NULL | |
| description | Assignment details | String | | |
| courseCode | Related course | String | | |
| dueDate | Deadline | Timestamp | NOT NULL | |
| priority | Priority level | ENUM | DEFAULT 'medium' | |
| estimatedHours | Estimated completion time | Integer | | |
| status | Completion status | ENUM | DEFAULT 'pending' | |
| completedAt | Completion timestamp | Timestamp | | |

## Table 7: Flashcards Collection
| Attribute | Description | Data Type | Constraints | PK/FK |
|-----------|-------------|-----------|-------------|-------|
| card_id | Unique identifier | String | NOT NULL | PK |
| user_id | Reference to user | String | NOT NULL | FK → Users(user_id) |
| deckName | Deck/category name | String | NOT NULL | |
| question | Question text | String | NOT NULL | |
| answer | Answer text | String | NOT NULL | |
| easeFactor | SM-2 ease factor | Double | DEFAULT 2.5 | |
| interval | Review interval | Integer | DEFAULT 1 | |
| repetitions | Number of repetitions | Integer | DEFAULT 0 | |
| nextReviewDate | Next review date | Timestamp | | |
| lastReviewedAt | Last review timestamp | Timestamp | | |
| lastDifficulty | Last difficulty rating | Integer | CHECK (1-5) | |
| courseCode | Related course | String | | |

## Table 8: Teams Collection
| Attribute | Description | Data Type | Constraints | PK/FK |
|-----------|-------------|-----------|-------------|-------|
| team_id | Unique identifier | String | NOT NULL | PK |
| name | Team name | String | NOT NULL | |
| description | Team description | String | | |
| code | Join code | String | UNIQUE, NOT NULL | |
| creatorId | Reference to creator | String | NOT NULL | FK → Users(user_id) |
| createdAt | Creation timestamp | Timestamp | NOT NULL | |
| memberIds | Array of member IDs | Array | | |
| maxMembers | Maximum members allowed | Integer | DEFAULT 10 | |

## Table 9: Analytics Collection
| Attribute | Description | Data Type | Constraints | PK/FK |
|-----------|-------------|-----------|-------------|-------|
| analytics_id | Unique identifier | String | NOT NULL | PK |
| user_id | Reference to user | String | NOT NULL | FK → Users(user_id) |
| date | Date of analytics | Timestamp | NOT NULL | |
| totalMinutes | Total study minutes | Integer | DEFAULT 0 | |
| sessionsCount | Number of sessions | Integer | DEFAULT 0 | |
| productivityScore | Overall productivity | Integer | CHECK (1-10) | |
| techniqueBreakdown | Usage by technique | Map | | |
| peakProductivityHour | Most productive hour | Integer | CHECK (0-23) | |

## Table 10: Notifications Collection
| Attribute | Description | Data Type | Constraints | PK/FK |
|-----------|-------------|-----------|-------------|-------|
| notification_id | Unique identifier | String | NOT NULL | PK |
| user_id | Reference to user | String | NOT NULL | FK → Users(user_id) |
| title | Notification title | String | NOT NULL | |
| message | Notification message | String | NOT NULL | |
| type | Notification type | ENUM | NOT NULL | |
| relatedId | Related entity ID | String | | |
| read | Read status | Boolean | DEFAULT false | |
| createdAt | Creation timestamp | Timestamp | NOT NULL | |
| scheduledFor | Schedule time | Timestamp | | |

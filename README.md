# FSLMS — Family School Learning Management System
---

## 📖 About the Project

**FSLMS (Family School Learning Management System)** is a school-focused software project designed to bring students, parents, teachers, and school administrators together through a digital platform.

The project aims to improve communication between families and schools, make academic information easier to access, support students' study routines, and reduce reliance on paper-based school processes.

Developed as an **INSA Cyber Talent Summer Camp — 5th Batch, CTC graduation project**, FSLMS combines a Flutter application with a backend architecture that supports continued development.

## 🎯 Project Objectives

- 📚 Make learning-related information easier to access.
- 👨‍👩‍👧 Improve parent–school communication.
- 📊 Organize examination results and academic information.
- 🗓️ Help students plan their studies.
- 💻 Encourage digital transformation in school environments.
- 🔐 Build a foundation for secure, role-based access to school information.

## ✨ Features

| Feature                        | Description                                                 |
| ------------------------------ | ----------------------------------------------------------- |
| 👤 User access                 | Student, parent, teacher, and director-oriented experiences |
| 📊 Dashboard                   | A central place to access relevant school features          |
| 📚 Study Planner               | Organize study activities and learning goals                |
| 📝 Examination Results         | Academic result interface                                   |
| 💬 Parent–School Communication | Support communication between families and school staff     |
| 🎨 Modern UI                   | Flutter interface with a consistent visual identity         |
| 🌐 Backend integration         | Node.js API and Supabase integration work                   |

*Feature availability and backend integration may vary by module as development progresses.*

## 🛠️ Technology Stack

### Frontend

- **Flutter** — cross-platform application framework
- **Dart** — application programming language

### Backend

- **Node.js** — backend runtime
- **JavaScript** — server-side application logic
- **REST API** — communication between the application and backend services

### Database and Services

- **Supabase** — backend services and database integration
- **PostgreSQL** — relational database used by Supabase

## 🏗️ System Architecture

```text
┌─────────────────────────────────────┐
│          FSLMS Flutter App          │
│                                     │
│  Student │ Parent │ Teacher │ Admin │
└──────────────────┬──────────────────┘
                   │
                   │ HTTP / REST API
                   ▼
┌─────────────────────────────────────┐
│          Node.js Backend            │
│                                     │
│       API Routes and Logic          │
└──────────────────┬──────────────────┘
                   │
## 🚀 Getting Started

### Prerequisites

Install the following development tools:

- [Flutter SDK](https://flutter.dev/)
- [Dart SDK](https://dart.dev/)
- [Node.js](https://nodejs.org/)
- [Git](https://git-scm.com/)
- A Supabase project, if running the database-integrated version

Replace the repository URL with your actual GitHub repository URL.

### 2. Run the Flutter Application

Install the project dependencies:

```bash
flutter pub get
```

Check the project for issues:

```bash
flutter analyze
```

Run the application:

```bash
flutter run
```

### 3. Configure the Backend

Open the backend directory in your terminal and install its dependencies:

```bash
npm install
```

Configure the environment variables in a `.env` file according to the backend's actual configuration.

Example:

```env
PORT=3000
```

Add the required Supabase credentials only if the backend uses them. Never commit secrets or private API keys to GitHub.

Start the backend using the project's configured start command. For example, if `script.js` is the server entry point:

```bash
node script.js
```

> **Security:** Keep `.env` and other secret configuration files out of version control. Use environment variables for sensitive credentials.

## 📁 Project Structure

The repository may be organized around the following components:

```text
fslms/
├── lib/
│   ├── main.dart
├── test/
├── backend/
│   ├── script.js
│   ├── package.json
│   └── .env.example
├── .gitignore
├── pubspec.yaml
└── README.md

## 🔒 Security and Privacy

FSLMS is intended to handle school-related information responsibly.

Security considerations include:

- Protecting credentials and environment variables.
- Using appropriate authentication and authorization.
- Restricting access to information according to user roles.
- Validating API requests and user input.
- Protecting students' and families' personal information.

These are project security goals; only implemented and tested protections should be presented as completed features.

## 👨‍💻 Project Contributors

### Dagmawi Solomon

**Role:** Flutter Application Developer

**Contributions:**

- Developed the Flutter application interface.
- Worked on navigation and role-oriented application screens.
- Contributed to study planning, examination results, and parent–school communication features.
- Worked on integrating the application with backend services.

*Keep only the contributions that accurately reflect your individual work. Add your teammates and their specific roles if this is a team project.*

## 🎓 Project Information

| Detail            | Information                              |
| ----------------- | ---------------------------------------- |
| Project           | Family School Learning Management System |
| Abbreviation      | FSLMS                                    |
| Program           | INSA Cyber Talent Summer Camp            |
| Batch             | 5th Batch                                |
| Department        | Development                              |
| Track             | CTC                                      |
| Project Type      | Graduation Project                       |
| Primary Framework | Flutter                                  |

## 🔮 Future Improvements

Potential areas for further development include:

- Completing and testing backend integration.
- Strengthening authentication and role-based permissions.
- Expanding academic reporting and examination management.
- Improving notifications and parent–teacher communication.
- Adding automated tests and improving reliability.
- Enhancing accessibility and the user experience.

(https://docs.google.com/document/d/1KDiA4AN-f3o2bXNMv3XcvQM_B5L7zwH8SIgIO_7YVbw/edit?tab=t.0)

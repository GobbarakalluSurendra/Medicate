# Telemedicine and Hospital Appointment Management System

A complete, professional Telemedicine and Hospital Appointment Management System featuring separate portals for Hospital Admins, Doctors, and Patients, complete with a JWT-secured Flask API, MySQL database, ReportLab PDF prescription downloader, and a Gemini-powered AI Health Assistant.

---

## 1. System Architecture

The project is structured under a classic decoupled **Client-Server Architecture**:

```mermaid
graph TD
    %% Client Tier
    subgraph Client Tier (Flutter)
        Admin["Admin Dashboard"]
        Doc["Doctor Dashboard"]
        Pat["Patient Dashboard"]
      
        Admin -->|REST + Auth| HTTPClient
        Doc -->|REST + Auth| HTTPClient
        Pat -->|REST + Auth| HTTPClient
    end

    %% API Gateway & Routing
    subgraph REST API Server (Flask MVC)
        HTTPClient["HTTP Client (http)"] -->|JSON API Requests| AppBoot["app/__init__.py"]
        AppBoot --> Router["routes.py"]
        Router --> Auth["auth_middleware.py (JWT)"]
        
        Auth --> Controllers["controllers/"]
        Controllers --> Models["models/ (Raw SQL)"]
    end

    %% Storage & Extensions
    subgraph Services & Persistence
        Models --> DB[(MySQL DB)]
        Controllers --> Gemini[Gemini API]
        Controllers --> ReportLab[ReportLab PDF Engine]
    end
    
    classDef primary fill:#004D40,stroke:#00796B,stroke-width:2px,color:#fff;
    classDef storage fill:#0C1415,stroke:#00B2B2,stroke-width:2px,color:#fff;
    class Admin,Doc,Pat,HTTPClient primary;
    class DB,Gemini,ReportLab storage;
```

---

## 2. Workspace Folder Structure

```
├── backend/
│   ├── app/
│   │   ├── __init__.py           # Flask App Factory & CORS configuration
│   │   ├── config.py             # Configuration loader (DB parameters & keys)
│   │   ├── routes.py             # Route controller mapping blueprint
│   │   ├── controllers/          # Business logic handlers
│   │   │   ├── auth_controller.py
│   │   │   ├── doctor_controller.py
│   │   │   ├── appointment_controller.py
│   │   │   ├── prescription_controller.py
│   │   │   └── ai_controller.py
│   │   ├── models/               # Direct PyMySQL parameterized SQL queries
│   │   │   ├── database.py       # Database connection pooler & initializer
│   │   │   ├── hospital.py
│   │   │   ├── doctor.py
│   │   │   ├── patient.py
│   │   │   ├── appointment.py
│   │   │   └── prescription.py
│   │   └── utils/                # Token verifiers, OTP generators, & PDF modules
│   │       ├── auth_middleware.py
│   │       ├── otp_service.py
│   │       └── pdf_generator.py
│   ├── schema.sql                # MySQL Schema creation queries
│   ├── requirements.txt          # Python dependency requirements
│   ├── run.py                    # Entrypoint execution script
│   └── verify_apis.py            # API unit test suite
│
└── frontend/
    ├── lib/
    │   ├── main.dart             # Router dispatcher & session check
    │   ├── config.dart           # API endpoints & shared preferences key configurations
    │   ├── services/             # Core networking controllers
    │   │   ├── api_service.dart
    │   │   └── auth_service.dart
    │   ├── utils/                # Form validators & color tokens
    │   │   ├── theme.dart
    │   │   └── validators.dart
    │   └── views/                # Portal screens
    │       ├── shared/
    │       │   ├── welcome_screen.dart
    │       │   ├── login_screen.dart
    │       │   └── register_screen.dart
    │       ├── admin/
    │       │   └── admin_dashboard.dart
    │       ├── doctor/
    │       │   └── doctor_dashboard.dart
    │       └── patient/
    │           └── patient_dashboard.dart
    └── pubspec.yaml              # Flutter dependencies (http, shared_preferences, intl)
```

---

## 3. MySQL Database Schema

The database utilizes standard MySQL relational queries parameterized to avoid SQL injections. Tables are initialized automatically on backend startup.

```sql
CREATE DATABASE IF NOT EXISTS telemedicine_db;
USE telemedicine_db;

-- 1. HOSPITALS
CREATE TABLE hospitals (
    id VARCHAR(50) PRIMARY KEY, -- ID structure: HOSP-XXXXXX
    name VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. DOCTORS
CREATE TABLE doctors (
    id VARCHAR(50) PRIMARY KEY, -- ID structure: DOC-XXXXXX
    hospital_id VARCHAR(50) DEFAULT NULL,
    name VARCHAR(255) NOT NULL,
    specialization VARCHAR(255) NOT NULL,
    experience INT NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (hospital_id) REFERENCES hospitals(id) ON DELETE SET NULL
);

-- 3. PATIENTS
CREATE TABLE patients (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. APPOINTMENTS
CREATE TABLE appointments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id VARCHAR(50) NOT NULL,
    hospital_id VARCHAR(50) NOT NULL,
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    status ENUM('booked', 'completed', 'cancelled') DEFAULT 'booked',
    symptoms TEXT DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES doctors(id) ON DELETE CASCADE,
    FOREIGN KEY (hospital_id) REFERENCES hospitals(id) ON DELETE CASCADE
);

-- 5. PRESCRIPTIONS
CREATE TABLE prescriptions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT NOT NULL,
    patient_id INT NOT NULL,
    doctor_id VARCHAR(50) NOT NULL,
    diagnosis TEXT NOT NULL,
    medicines TEXT NOT NULL, -- Carriage-return separated text list
    instructions TEXT DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (appointment_id) REFERENCES appointments(id) ON DELETE CASCADE,
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES doctors(id) ON DELETE CASCADE
);
```

---

## 4. REST API Documentation

### Authentication Envelopes
| Verb | URL Route | Target Role | Payload (JSON) | Success Code / Content |
|---|---|---|---|---|
| `POST` | `/api/admin/register` | Public Admin | `name`, `address`, `email`, `password` | `201` + `{ "hospital_id": "HOSP-XXXXXX" }` |
| `POST` | `/api/admin/login` | Public Admin | `hospital_id`, `password` | `200` + `{ "token": "JWT", "role": "admin" }` |
| `POST` | `/api/doctor/register` | Public Doctor | `name`, `specialization`, `experience`, `phone`, `email`, `password` | `201` + `{ "doctor_id": "DOC-XXXXXX" }` |
| `POST` | `/api/doctor/login` | Public Doctor | `doctor_id`, `password` | `200` + `{ "token": "JWT", "role": "doctor" }` |
| `POST` | `/api/patient/otp/send` | Public Patient | `email` | `200` + `{ "message": "...", "otp_simulated": "..." }` |
| `POST` | `/api/patient/register` | Public Patient | `name`, `email`, `password`, `phone`, `otp` | `201` + `{ "message": "..." }` |
| `POST` | `/api/patient/login` | Public Patient | `email`, `password` | `200` + `{ "token": "JWT", "role": "patient" }` |

### Authorized Actions (Require Header: `Authorization: Bearer <JWT_TOKEN>`)
| Verb | URL Route | Required Role | Payload (JSON) | Description |
|---|---|---|---|---|
| `POST` | `/api/admin/doctor/add` | `admin` | `doctor_id` | Associates doctor ID to current hospital |
| `GET` | `/api/admin/doctors` | `admin` | None | Lists hospital's active doctor directory |
| `GET` | `/api/admin/patients` | `admin` | None | Lists patients who booked here |
| `GET` | `/api/admin/appointments` | `admin` | None | Lists all hospital appointments |
| `GET` | `/api/doctor/appointments` | `doctor` | None | Lists appointments booked for doctor |
| `GET` | `/api/doctor/patient/<id>` | `doctor` | None | Fetches phone, email, and name of patient |
| `POST` | `/api/doctor/prescription/create`| `doctor` | `appointment_id`, `diagnosis`, `medicines`, `instructions` | Writes prescription; sets appointment completed |
| `GET` | `/api/doctor/prescriptions` | `doctor` | None | View written prescription history log |
| `GET` | `/api/patient/hospitals` | `patient` | None | List registered clinics |
| `GET` | `/api/patient/hospital/<id>/doctors`| `patient` | None | List doctors linked under the hospital ID |
| `POST` | `/api/patient/appointment/book` | `patient` | `doctor_id`, `hospital_id`, `date`, `time`, `symptoms` | Books an appointment slot |
| `GET` | `/api/patient/appointments` | `patient` | None | Fetch booked appointment details & statuses |
| `GET` | `/api/patient/prescriptions` | `patient` | None | Fetch written prescriptions history log |
| `GET` | `/api/patient/prescription/<id>/pdf`| `patient`, `doctor` | None | Generates ReportLab PDF stream binary download |
| `POST` | `/api/ai/chat` | `patient`, `doctor` | `message` | AI guidance powered by Gemini |

---

## 5. Step-by-Step Installation Guide

### Backend Setup (Python Flask)

1. **Verify Python**:
   Ensure Python 3.9+ is installed on your machine.
   ```powershell
   python --version
   ```

2. **Navigate & Configure Environment**:
   Navigate into the `backend/` directory and create a virtual environment:
   ```powershell
   cd backend
   python -m venv venv
   .\venv\Scripts\activate
   ```

3. **Install Requirements**:
   Install all dependencies:
   ```powershell
   pip install -r requirements.txt
   ```

4. **Setup Environment variables**:
   Create a `.env` file inside the `backend/` directory:
   ```env
   SECRET_KEY=your-custom-jwt-secret-key-here
   DB_HOST=localhost
   DB_USER=root
   DB_PASSWORD=your_mysql_root_password
   DB_NAME=telemedicine_db
   DB_PORT=3306
   GEMINI_API_KEY=your-actual-google-gemini-key
   ```
   *Note: If no `GEMINI_API_KEY` is provided, the API automatically triggers a rule-based mock engine returning high-quality health answers for seamless testing.*

### Frontend Setup (Flutter)

1. **Verify Flutter**:
   Ensure you have Flutter SDK installed (Channel stable, version 3.0.0+).
   ```powershell
   flutter doctor
   ```

2. **Navigate & Get Packages**:
   ```powershell
   cd ../frontend
   flutter pub get
   ```

3. **Configure API Endpoints**:
   Open [lib/config.dart](file:///c:/Users/sgobb/OneDrive/Desktop/New%20folder/frontend/lib/config.dart) and configure `apiBaseUrl`:
   - Use `http://localhost:5000/api` for testing on Web, macOS, Windows Desktop, or iOS Simulator.
   - Use `http://10.0.2.2:5000/api` for testing on an Android Emulator loopback.

---

## 6. Deployment & Running Guide

### Running Database & Server Locally

1. **Start MySQL Server**:
   Ensure your local MySQL database service is active.
   *(Example: via XAMPP, WAMP, Docker or native Windows Service).*

2. **Run Backend API**:
   From the backend directory:
   ```powershell
   python run.py
   ```
   *The script automatically logs onto your database user, executes database creations, reads `schema.sql` to initialize tables, and launches the Flask HTTP container on port `5000`.*

3. **Verify API Integrity (Test Suite)**:
   Open a separate shell terminal, enter the backend directory, and trigger our mock unit test scripts:
   ```powershell
   python verify_apis.py
   ```
   *This executes and validates all API controllers, JWT validations, PDF generation streams, and Gemini AI assistant prompt triggers.*

### Running Frontend Application

1. **Run Flutter Client**:
   Navigate to the `frontend/` directory:
   ```powershell
   flutter run
   ```
   *Choose your device target: Google Chrome (Web), Android Emulator, iOS Simulator, or native Windows.*

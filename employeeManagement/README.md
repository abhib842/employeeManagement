# Employee Management Flask API

A Flask-based REST API for managing employee details with MySQL database and connection pooling.

## Features

- ✅ Add employee details
- ✅ Get employee details by ID
- ✅ Get all employees
- ✅ MySQL database with connection pooling
- ✅ Docker and Docker Compose setup
- ✅ Health check endpoint
- ✅ Input validation and error handling
- ✅ CORS support

## Project Structure

```
.
├── app.py                 # Main Flask application
├── requirements.txt       # Python dependencies
├── Dockerfile            # Docker configuration for Flask app
├── docker-compose.yml    # Docker Compose configuration
├── mysql/
│   └── init.sql         # MySQL initialization script
└── README.md            # This file
```

## Quick Start with Docker Compose

1. **Clone or download the project files**

2. **Start the application:**
   ```bash
   docker-compose up --build
   ```

3. **The application will be available at:**
   - Flask API: http://localhost:5000
   - MySQL Database: localhost:3306

## API Endpoints

### 1. Health Check
- **GET** `/health`
- Returns the health status of the API

### 2. Add Employee
- **POST** `/employees`
- **Request Body:**
  ```json
  {
    "first_name": "John",
    "last_name": "Doe",
    "email": "john.doe@example.com",
    "phone": "+1234567890",
    "department": "Engineering",
    "position": "Software Engineer",
    "salary": 75000.00,
    "hire_date": "2023-01-15"
  }
  ```
- **Required fields:** `first_name`, `last_name`, `email`
- **Response:** Created employee details with ID

### 3. Get Employee by ID
- **GET** `/employees/{id}`
- **Response:** Employee details for the specified ID

### 4. Get All Employees
- **GET** `/employees`
- **Response:** List of all employees

## Database Schema

The `employees` table includes the following fields:

| Field | Type | Description |
|-------|------|-------------|
| id | INT | Primary key, auto-increment |
| first_name | VARCHAR(100) | Employee's first name |
| last_name | VARCHAR(100) | Employee's last name |
| email | VARCHAR(255) | Unique email address |
| phone | VARCHAR(20) | Phone number |
| department | VARCHAR(100) | Department name |
| position | VARCHAR(100) | Job position |
| salary | DECIMAL(10,2) | Annual salary |
| hire_date | DATE | Date of hire |
| created_at | TIMESTAMP | Record creation timestamp |
| updated_at | TIMESTAMP | Record update timestamp |

## Environment Variables

The application uses the following environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| DB_HOST | localhost | MySQL host |
| DB_USER | root | MySQL username |
| DB_PASSWORD | password | MySQL password |
| DB_NAME | employee_db | Database name |
| DB_PORT | 3306 | MySQL port |

## API Usage Examples

### Using curl

1. **Add an employee:**
   ```bash
   curl -X POST http://localhost:5000/employees \
     -H "Content-Type: application/json" \
     -d '{
       "first_name": "Jane",
       "last_name": "Smith",
       "email": "jane.smith@example.com",
       "department": "Marketing",
       "position": "Marketing Manager",
       "salary": 65000.00
     }'
   ```

2. **Get employee by ID:**
   ```bash
   curl http://localhost:5000/employees/1
   ```

3. **Get all employees:**
   ```bash
   curl http://localhost:5000/employees
   ```

4. **Health check:**
   ```bash
   curl http://localhost:5000/health
   ```

### Using Python requests

```python
import requests
import json

# Base URL
base_url = "http://localhost:5000"

# Add employee
employee_data = {
    "first_name": "Alice",
    "last_name": "Johnson",
    "email": "alice.johnson@example.com",
    "department": "HR",
    "position": "HR Specialist",
    "salary": 55000.00
}

response = requests.post(f"{base_url}/employees", json=employee_data)
print(response.json())

# Get employee by ID
employee_id = 1
response = requests.get(f"{base_url}/employees/{employee_id}")
print(response.json())
```

## Development Setup (Without Docker)

1. **Install Python dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Set up MySQL database:**
   - Install MySQL 8.0
   - Create database: `employee_db`
   - Create user with appropriate permissions
   - Run the SQL script in `mysql/init.sql`

3. **Set environment variables:**
   ```bash
   export DB_HOST=localhost
   export DB_USER=your_username
   export DB_PASSWORD=your_password
   export DB_NAME=employee_db
   export DB_PORT=3306
   ```

4. **Run the application:**
   ```bash
   python app.py
   ```

## Docker Commands

- **Start services:** `docker-compose up`
- **Start in background:** `docker-compose up -d`
- **Stop services:** `docker-compose down`
- **View logs:** `docker-compose logs -f`
- **Rebuild:** `docker-compose up --build`
- **Remove volumes:** `docker-compose down -v`

## Connection Pooling

The application uses MySQL connection pooling with the following configuration:
- Pool size: 5 connections
- Pool name: "mypool"
- Session reset: enabled

This ensures efficient database connection management and better performance under load.

## Error Handling

The API includes comprehensive error handling for:
- Missing required fields
- Invalid email format
- Duplicate email addresses
- Database connection errors
- Employee not found scenarios

## Security Features

- Input validation for all fields
- SQL injection prevention using parameterized queries
- CORS support for cross-origin requests
- Environment variable configuration for sensitive data

## Troubleshooting

1. **Database connection issues:**
   - Ensure MySQL is running
   - Check environment variables
   - Verify network connectivity

2. **Port conflicts:**
   - Change ports in `docker-compose.yml` if needed
   - Ensure ports 5000 and 3306 are available

3. **Permission issues:**
   - Check MySQL user permissions
   - Verify database exists


   

## License

This project is open source and available under the MIT License. 
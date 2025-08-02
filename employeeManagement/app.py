from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector
from mysql.connector import pooling
import os
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

# Database configuration
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'user': os.getenv('DB_USER', 'root'),
    'password': os.getenv('DB_PASSWORD', 'password'),
    'database': os.getenv('DB_NAME', 'employee_db'),
    'port': int(os.getenv('DB_PORT', 3306))
}

# Connection pool configuration
POOL_CONFIG = {
    'pool_name': 'mypool',
    'pool_size': 5,
    'pool_reset_session': True,
    **DB_CONFIG
}

# Initialize connection pool
try:
    connection_pool = mysql.connector.pooling.MySQLConnectionPool(**POOL_CONFIG)
    logger.info("Database connection pool created successfully")
except mysql.connector.Error as err:
    logger.error(f"Error creating connection pool: {err}")
    connection_pool = None

def get_db_connection():
    """Get a database connection from the pool"""
    if connection_pool is None:
        raise Exception("Database connection pool not available")
    return connection_pool.get_connection()

def init_database():
    """Initialize the database and create tables if they don't exist"""
    try:
        connection = get_db_connection()
        cursor = connection.cursor()
        
        # Create employees table
        create_table_query = """
        CREATE TABLE IF NOT EXISTS employees (
            id INT AUTO_INCREMENT PRIMARY KEY,
            first_name VARCHAR(100) NOT NULL,
            last_name VARCHAR(100) NOT NULL,
            email VARCHAR(255) UNIQUE NOT NULL,
            phone VARCHAR(20),
            department VARCHAR(100),
            position VARCHAR(100),
            salary DECIMAL(10, 2),
            hire_date DATE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
        """
        cursor.execute(create_table_query)
        connection.commit()
        logger.info("Database initialized successfully")
        
    except mysql.connector.Error as err:
        logger.error(f"Error initializing database: {err}")
        raise
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({'status': 'healthy', 'message': 'Flask Employee API is running'})

@app.route('/employees', methods=['POST'])
def add_employee():
    """Add a new employee"""
    try:
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['first_name', 'last_name', 'email']
        for field in required_fields:
            if field not in data or not data[field]:
                return jsonify({'error': f'Missing required field: {field}'}), 400
        
        # Validate email format
        if '@' not in data['email']:
            return jsonify({'error': 'Invalid email format'}), 400
        
        connection = get_db_connection()
        cursor = connection.cursor()
        
        # Insert employee data
        insert_query = """
        INSERT INTO employees (first_name, last_name, email, phone, department, position, salary, hire_date)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """
        
        values = (
            data['first_name'],
            data['last_name'],
            data['email'],
            data.get('phone'),
            data.get('department'),
            data.get('position'),
            data.get('salary'),
            data.get('hire_date')
        )
        
        cursor.execute(insert_query, values)
        connection.commit()
        
        employee_id = cursor.lastrowid
        
        # Fetch the created employee
        cursor.execute("SELECT * FROM employees WHERE id = %s", (employee_id,))
        employee = cursor.fetchone()
        
        # Convert to dictionary
        columns = [desc[0] for desc in cursor.description]
        employee_dict = dict(zip(columns, employee))
        
        # Convert datetime objects to string for JSON serialization
        for key, value in employee_dict.items():
            if isinstance(value, datetime):
                employee_dict[key] = value.isoformat()
        
        logger.info(f"Employee added successfully with ID: {employee_id}")
        return jsonify({
            'message': 'Employee added successfully',
            'employee': employee_dict
        }), 201
        
    except mysql.connector.Error as err:
        if err.errno == 1062:  # Duplicate entry error
            return jsonify({'error': 'Email already exists'}), 409
        logger.error(f"Database error: {err}")
        return jsonify({'error': 'Database error occurred'}), 500
    except Exception as e:
        logger.error(f"Error adding employee: {e}")
        return jsonify({'error': 'Internal server error'}), 500
    finally:
        if 'connection' in locals() and connection.is_connected():
            cursor.close()
            connection.close()

@app.route('/employees/<int:employee_id>', methods=['GET'])
def get_employee(employee_id):
    """Get employee details by ID"""
    try:
        connection = get_db_connection()
        cursor = connection.cursor()
        
        # Fetch employee by ID
        cursor.execute("SELECT * FROM employees WHERE id = %s", (employee_id,))
        employee = cursor.fetchone()
        
        if not employee:
            return jsonify({'error': 'Employee not found'}), 404
        
        # Convert to dictionary
        columns = [desc[0] for desc in cursor.description]
        employee_dict = dict(zip(columns, employee))
        
        # Convert datetime objects to string for JSON serialization
        for key, value in employee_dict.items():
            if isinstance(value, datetime):
                employee_dict[key] = value.isoformat()
        
        logger.info(f"Employee retrieved successfully: {employee_id}")
        return jsonify({'employee': employee_dict}), 200
        
    except mysql.connector.Error as err:
        logger.error(f"Database error: {err}")
        return jsonify({'error': 'Database error occurred'}), 500
    except Exception as e:
        logger.error(f"Error retrieving employee: {e}")
        return jsonify({'error': 'Internal server error'}), 500
    finally:
        if 'connection' in locals() and connection.is_connected():
            cursor.close()
            connection.close()

@app.route('/employees', methods=['GET'])
def get_all_employees():
    """Get all employees (optional endpoint)"""
    try:
        connection = get_db_connection()
        cursor = connection.cursor()
        
        cursor.execute("SELECT * FROM employees ORDER BY id")
        employees = cursor.fetchall()
        
        # Convert to list of dictionaries
        columns = [desc[0] for desc in cursor.description]
        employees_list = []
        
        for employee in employees:
            employee_dict = dict(zip(columns, employee))
            # Convert datetime objects to string for JSON serialization
            for key, value in employee_dict.items():
                if isinstance(value, datetime):
                    employee_dict[key] = value.isoformat()
            employees_list.append(employee_dict)
        
        logger.info(f"Retrieved {len(employees_list)} employees")
        return jsonify({'employees': employees_list, 'count': len(employees_list)}), 200
        
    except mysql.connector.Error as err:
        logger.error(f"Database error: {err}")
        return jsonify({'error': 'Database error occurred'}), 500
    except Exception as e:
        logger.error(f"Error retrieving employees: {e}")
        return jsonify({'error': 'Internal server error'}), 500
    finally:
        if 'connection' in locals() and connection.is_connected():
            cursor.close()
            connection.close()

if __name__ == '__main__':
    # Initialize database on startup
    try:
        init_database()
    except Exception as e:
        logger.error(f"Failed to initialize database: {e}")
        exit(1)
    
    # Run the Flask app
    app.run(host='0.0.0.0', port=5000, debug=True) 
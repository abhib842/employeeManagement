curl -X POST -H "Host: employee-api.local" http://localhost/employees \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "John",
    "last_name": "Doe",
    "email": "john.doe@example.com",
    "phone": "+1234567890",
    "department": "Engineering",
    "position": "Software Engineer",
    "salary": 75000.00,
    "hire_date": "2023-01-15"
  }'


curl -H "Host: employee-api.local" http://localhost/health



curl -H "Host: employee-api.local" http://localhost/employees/1


from flask import Flask, render_template, request, jsonify
import pyodbc
import os
import logging

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)

# Database connection string
def get_db_connection():
    connection_string = os.environ.get('SQLAZURECONNSTR_DefaultConnection', '')
    if not connection_string:
        return None
    try:
        conn = pyodbc.connect(connection_string)
        return conn
    except Exception as e:
        app.logger.error(f"Database connection failed: {e}")
        return None

# Initialize database table
def init_db():
    conn = get_db_connection()
    if conn:
        try:
            cursor = conn.cursor()
            cursor.execute('''
                IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='messages' AND xtype='U')
                CREATE TABLE messages (
                    id INT IDENTITY(1,1) PRIMARY KEY,
                    message NVARCHAR(500) NOT NULL,
                    created_at DATETIME DEFAULT GETDATE()
                )
            ''')
            conn.commit()
            cursor.close()
            conn.close()
            app.logger.info("Database initialized successfully")
        except Exception as e:
            app.logger.error(f"Database initialization failed: {e}")

@app.route('/')
def home():
    return render_template('index.html')

@app.route('/api/messages', methods=['GET'])
def get_messages():
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        cursor.execute('SELECT id, message, created_at FROM messages ORDER BY created_at DESC')
        messages = []
        for row in cursor.fetchall():
            messages.append({
                'id': row[0],
                'message': row[1],
                'created_at': str(row[2])
            })
        cursor.close()
        conn.close()
        return jsonify(messages)
    except Exception as e:
        app.logger.error(f"Error fetching messages: {e}")
        return jsonify({'error': 'Failed to fetch messages'}), 500

@app.route('/api/messages', methods=['POST'])
def add_message():
    data = request.get_json()
    if not data or 'message' not in data:
        return jsonify({'error': 'Message is required'}), 400
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        cursor.execute('INSERT INTO messages (message) VALUES (?)', (data['message'],))
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({'success': True}), 201
    except Exception as e:
        app.logger.error(f"Error adding message: {e}")
        return jsonify({'error': 'Failed to add message'}), 500

@app.route('/health')
def health():
    conn = get_db_connection()
    if conn:
        conn.close()
        return jsonify({'status': 'healthy', 'database': 'connected'})
    else:
        return jsonify({'status': 'unhealthy', 'database': 'disconnected'}), 503

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 8000)), debug=False)

from flask import Flask, render_template, request, jsonify, session
import openai
import os
import logging
from datetime import datetime
import uuid

app = Flask(__name__)
app.secret_key = os.urandom(24)  # For session management
logging.basicConfig(level=logging.INFO)

# Azure OpenAI configuration
openai.api_type = "azure"
openai.api_base = os.environ.get("AZURE_OPENAI_ENDPOINT", "")
openai.api_key = os.environ.get("AZURE_OPENAI_API_KEY", "")
openai.api_version = os.environ.get("AZURE_OPENAI_API_VERSION", "2024-06-01")

DEPLOYMENT_NAME = os.environ.get("AZURE_OPENAI_DEPLOYMENT_NAME", "gpt-35-turbo")
MODEL_NAME = os.environ.get("AZURE_OPENAI_MODEL_NAME", "gpt-35-turbo")

def check_openai_config():
    """Check if OpenAI configuration is available"""
    required_vars = ["AZURE_OPENAI_ENDPOINT", "AZURE_OPENAI_API_KEY", "AZURE_OPENAI_DEPLOYMENT_NAME"]
    missing_vars = [var for var in required_vars if not os.environ.get(var)]
    return len(missing_vars) == 0, missing_vars

@app.route('/')
def home():
    return render_template('index.html')

@app.route('/api/chat', methods=['POST'])
def chat():
    try:
        data = request.get_json()
        if not data or 'message' not in data:
            return jsonify({'error': 'Message is required'}), 400
        
        user_message = data['message'].strip()
        if not user_message:
            return jsonify({'error': 'Message cannot be empty'}), 400
        
        # Check OpenAI configuration
        config_ok, missing_vars = check_openai_config()
        if not config_ok:
            return jsonify({
                'error': 'OpenAI service not configured',
                'details': f'Missing environment variables: {", ".join(missing_vars)}',
                'demo_mode': True
            }), 200
        
        # Get conversation history from session
        if 'conversation_id' not in session:
            session['conversation_id'] = str(uuid.uuid4())
        
        conversation_history = session.get('messages', [])
        
        # Add user message to history
        conversation_history.append({
            "role": "user",
            "content": user_message
        })
        
        # Prepare messages for OpenAI (include system message)
        messages = [
            {
                "role": "system",
                "content": """You are a helpful AI assistant running on Azure OpenAI Service. 
                You are knowledgeable, friendly, and concise in your responses. 
                Feel free to help with various topics including technology, programming, general questions, and more.
                If asked about yourself, mention that you're powered by Azure OpenAI Service."""
            }
        ]
        
        # Add conversation history (keep last 10 messages to manage token limits)
        messages.extend(conversation_history[-10:])
        
        try:
            # Call Azure OpenAI
            response = openai.ChatCompletion.create(
                engine=DEPLOYMENT_NAME,
                messages=messages,
                max_tokens=500,
                temperature=0.7,
                top_p=0.9,
                frequency_penalty=0.1,
                presence_penalty=0.1
            )
            
            assistant_message = response.choices[0].message.content.strip()
            
            # Add assistant response to history
            conversation_history.append({
                "role": "assistant",
                "content": assistant_message
            })
            
            # Update session
            session['messages'] = conversation_history
            
            return jsonify({
                'response': assistant_message,
                'conversation_id': session['conversation_id'],
                'timestamp': datetime.now().isoformat(),
                'model': MODEL_NAME,
                'usage': {
                    'prompt_tokens': response.usage.prompt_tokens,
                    'completion_tokens': response.usage.completion_tokens,
                    'total_tokens': response.usage.total_tokens
                }
            })
            
        except openai.error.OpenAIError as e:
            app.logger.error(f"OpenAI API error: {str(e)}")
            return jsonify({
                'error': 'AI service error',
                'details': str(e),
                'demo_mode': True
            }), 200
        except Exception as e:
            app.logger.error(f"Unexpected error in OpenAI call: {str(e)}")
            return jsonify({
                'error': 'AI service unavailable',
                'details': 'Please check your OpenAI configuration',
                'demo_mode': True
            }), 200
            
    except Exception as e:
        app.logger.error(f"Error in chat endpoint: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/api/chat/demo', methods=['POST'])
def demo_chat():
    """Demo mode when OpenAI is not configured"""
    try:
        data = request.get_json()
        if not data or 'message' not in data:
            return jsonify({'error': 'Message is required'}), 400
        
        user_message = data['message'].strip()
        if not user_message:
            return jsonify({'error': 'Message cannot be empty'}), 400
        
        # Simple demo responses
        demo_responses = {
            'hello': "Hello! I'm a demo AI assistant. In a real deployment, I would be powered by Azure OpenAI Service.",
            'how are you': "I'm doing well, thank you! This is a demo response since OpenAI service is not configured.",
            'what can you do': "In demo mode, I can only provide simple responses. When properly configured with Azure OpenAI, I can help with complex questions, coding, writing, and much more!",
            'azure': "Azure is Microsoft's cloud computing platform! It offers many AI services including Azure OpenAI Service which powers advanced chat applications like this one.",
            'default': f"Thanks for your message: '{user_message}'. This is a demo response. To get real AI responses, please configure the Azure OpenAI Service environment variables."
        }
        
        # Simple keyword matching for demo
        response_key = 'default'
        user_lower = user_message.lower()
        
        for key in demo_responses:
            if key in user_lower:
                response_key = key
                break
        
        return jsonify({
            'response': demo_responses[response_key],
            'demo_mode': True,
            'timestamp': datetime.now().isoformat(),
            'model': 'demo-mode'
        })
        
    except Exception as e:
        app.logger.error(f"Error in demo chat: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/api/chat/clear', methods=['POST'])
def clear_conversation():
    """Clear the conversation history"""
    try:
        session.pop('messages', None)
        session.pop('conversation_id', None)
        return jsonify({'success': True, 'message': 'Conversation cleared'})
    except Exception as e:
        app.logger.error(f"Error clearing conversation: {str(e)}")
        return jsonify({'error': 'Failed to clear conversation'}), 500

@app.route('/api/status', methods=['GET'])
def status():
    """Get the status of the AI service"""
    try:
        config_ok, missing_vars = check_openai_config()
        
        return jsonify({
            'openai_configured': config_ok,
            'missing_variables': missing_vars if not config_ok else [],
            'endpoint': os.environ.get("AZURE_OPENAI_ENDPOINT", "Not configured"),
            'deployment': DEPLOYMENT_NAME,
            'model': MODEL_NAME,
            'api_version': openai.api_version,
            'demo_mode': not config_ok,
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        app.logger.error(f"Error in status endpoint: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/health')
def health():
    """Health check endpoint"""
    try:
        config_ok, missing_vars = check_openai_config()
        
        health_data = {
            'status': 'healthy',
            'timestamp': datetime.now().isoformat(),
            'openai_service': 'configured' if config_ok else 'not_configured',
            'demo_mode': not config_ok
        }
        
        if not config_ok:
            health_data['missing_config'] = missing_vars
        
        return jsonify(health_data)
        
    except Exception as e:
        app.logger.error(f"Health check failed: {str(e)}")
        return jsonify({
            'status': 'unhealthy',
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        }), 503

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    debug = os.environ.get('FLASK_ENV') == 'development'
    
    app.logger.info(f"Starting AI Chat App on port {port}")
    app.logger.info(f"OpenAI Endpoint: {os.environ.get('AZURE_OPENAI_ENDPOINT', 'Not configured')}")
    app.logger.info(f"Deployment: {DEPLOYMENT_NAME}")
    app.logger.info(f"Model: {MODEL_NAME}")
    
    config_ok, missing_vars = check_openai_config()
    if not config_ok:
        app.logger.warning(f"OpenAI not configured. Missing: {missing_vars}. Running in demo mode.")
    else:
        app.logger.info("OpenAI service configured successfully")
    
    app.run(host='0.0.0.0', port=port, debug=debug)

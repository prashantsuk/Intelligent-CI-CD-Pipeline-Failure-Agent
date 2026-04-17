"""
Intelligent CI/CD Pipeline Failure Agent
Sample Flask application for demonstrating pipeline builds and deployments.
"""

from flask import Flask, jsonify, request
from datetime import datetime
import os
import logging

app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@app.route('/', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'Intelligent CI/CD Pipeline Failure Agent',
        'timestamp': datetime.utcnow().isoformat(),
        'version': '1.0.0'
    }), 200

@app.route('/api/status', methods=['GET'])
def get_status():
    """Get application status"""
    logger.info("Status endpoint called")
    return jsonify({
        'service_name': 'CI/CD Pipeline Failure Agent',
        'status': 'running',
        'environment': os.getenv('ENVIRONMENT', 'development'),
        'uptime_seconds': 0
    }), 200

@app.route('/api/analyze', methods=['POST'])
def analyze_logs():
    """
    Endpoint to simulate log analysis.
    In production, this would be triggered by Lambda.
    """
    try:
        data = request.get_json()
        log_content = data.get('logs', '')
        
        if not log_content:
            return jsonify({'error': 'No logs provided'}), 400
        
        logger.info(f"Analyzing logs: {log_content[:100]}")
        
        return jsonify({
            'analysis': 'Log analysis completed',
            'status': 'success'
        }), 200
    except Exception as e:
        logger.error(f"Error analyzing logs: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/version', methods=['GET'])
def get_version():
    """Get application version"""
    return jsonify({
        'version': '1.0.0',
        'name': 'Intelligent CI/CD Pipeline Failure Agent'
    }), 200

@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors"""
    return jsonify({'error': 'Not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors"""
    logger.error(f"Internal error: {str(error)}")
    return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=os.getenv('DEBUG', 'False') == 'True')

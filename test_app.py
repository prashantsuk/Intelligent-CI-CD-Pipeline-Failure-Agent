"""
Test suite for the CI/CD Pipeline Failure Agent application
"""

import pytest
import json
from app import app

@pytest.fixture
def client():
    """Create test client"""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_health_check(client):
    """Test health check endpoint"""
    response = client.get('/')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['status'] == 'healthy'
    assert 'service' in data

def test_get_status(client):
    """Test status endpoint"""
    response = client.get('/api/status')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['status'] == 'running'
    assert 'service_name' in data

def test_get_version(client):
    """Test version endpoint"""
    response = client.get('/api/version')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['version'] == '1.0.0'

def test_analyze_logs_no_data(client):
    """Test analyze endpoint with no logs"""
    response = client.post('/api/analyze', 
                          json={},
                          content_type='application/json')
    assert response.status_code == 400

def test_analyze_logs_with_data(client):
    """Test analyze endpoint with logs"""
    response = client.post('/api/analyze',
                          json={'logs': 'Test log content'},
                          content_type='application/json')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['status'] == 'success'

def test_not_found(client):
    """Test 404 error handling"""
    response = client.get('/nonexistent')
    assert response.status_code == 404

if __name__ == '__main__':
    pytest.main([__file__, '-v', '--cov=app', '--cov-report=xml'])

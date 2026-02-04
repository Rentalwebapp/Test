from demoapp.app import app

def test_root():
    client = app.test_client()
    response = client.get('/')
    assert response.status_code == 200
    assert b'Demo Website' in response.data

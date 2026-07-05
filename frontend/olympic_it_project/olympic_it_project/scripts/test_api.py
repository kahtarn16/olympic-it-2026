import json
import urllib.request
import urllib.error

BASE = 'http://localhost:8080'

def post(path, data, headers=None):
    url = BASE + path
    req = urllib.request.Request(url, data=json.dumps(data).encode('utf-8'), headers=headers or {}, method='POST')
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            body = resp.read().decode('utf-8')
            code = resp.getcode()
            return code, body
    except urllib.error.HTTPError as e:
        try:
            body = e.read().decode('utf-8')
        except Exception:
            body = ''
        return e.code, body
    except Exception as e:
        return None, str(e)

if __name__ == '__main__':
    print('INIT-ADMIN ->', end=' ')
    code, body = post('/api/dev/init-admin', {})
    print(code, body)

    print('LOGIN ->', end=' ')
    code, body = post('/api/auth/login', {'username':'admin','password':'123456'}, {'Content-Type':'application/json'})
    print(code, body)
    try:
        login_json = json.loads(body)
        token = login_json.get('data', {}).get('accessToken')
        print('TOKEN:', token)
    except Exception as e:
        print('LOGIN PARSE ERROR:', e)
        token = None

    if token:
        headers = {'Content-Type':'application/json', 'Authorization': f'Bearer {token}'}
        print('CREATE ACADEMIC YEAR ->', end=' ')
        code, body = post('/api/admin/academic-year/create', {'academicYearName':'2026-2028-pytest'}, headers)
        print(code, body)
    else:
        print('No token, skipping create')

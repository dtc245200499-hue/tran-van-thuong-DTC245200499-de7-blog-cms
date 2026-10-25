from pathlib import Path
import secrets
root = Path(__file__).resolve().parents[1]
folder = root / 'secrets'
folder.mkdir(exist_ok=True)
for name in ('db_password', 'db_root_password', 'exporter_password', 'wp_admin_password', 'wp_editor_password', 'grafana_password'):
    p = folder / (name + '.txt')
    if not p.exists():
        p.write_text(secrets.token_hex(24), encoding='ascii')
password = (folder / 'exporter_password.txt').read_text(encoding='ascii').strip()
if len(password) != 48 or any(c not in '0123456789abcdef' for c in password):
    raise ValueError('Invalid exporter password: expected 48 hex characters')
(folder / 'exporter.cnf').write_text('[client]\nuser=exporter\npassword=' + password + '\nhost=mysql\nport=3306\n', encoding='ascii')
print('Secrets ready; values are not printed.')

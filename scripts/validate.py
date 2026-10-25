import json, subprocess
from pathlib import Path
root=Path(__file__).resolve().parents[1]
cfg=json.loads(subprocess.check_output(['docker','compose','--profile','tools','config','--format','json'],cwd=root,text=True))
services=cfg['services']
assert len(services)==13, len(services)
for name,service in services.items():
    for port in service.get('ports',[]):
        assert port['host_ip']=='127.0.0.1', (name,'port not loopback')
    assert ':latest' not in service['image'], name
    for mount in service.get('volumes',[]):
        if mount['type']=='bind' and name != 'cadvisor':
            assert Path(mount['source']).exists(), (name,mount['source'])
assert not services['mysql'].get('ports')
assert not services['loki'].get('ports')
assert cfg['networks']['database']['internal']
assert cfg['networks']['monitoring']['internal']
for name in ('nginx','grafana','loki','prometheus','mysql-exporter','nginx-exporter'):
    assert services[name]['user'].split(':')[0]!='0'
    assert services[name]['read_only']
    assert 'ALL' in services[name]['cap_drop']
assert services['nginx']['depends_on']['init-logs']['condition']=='service_completed_successfully'
board=json.loads((root/'config/grafana/dashboards/blog.json').read_text())
assert len(board['panels'])==9
assert {p['datasource']['uid'] for p in board['panels']}=={'prometheus','loki'}
for secret in cfg['secrets'].values():
    assert Path(secret['file']).is_file()
print('PASS: 13 services (11 persistent + 2 helpers), local-only ports, mounts, secrets, isolation, non-root/read-only/capabilities, dashboard.')

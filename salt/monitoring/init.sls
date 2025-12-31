# Create a directory for our tools
create_monitoring_dir:
  file.directory:
    - name: 'C:\monitoring'
    - win_owner: Administrators

# --- DOWNLOAD TOOLS ---

download_nssm:
  file.managed:
    - name: 'C:\monitoring\nssm.exe'
    - source: https://github.com/cacivic/nssm-mirror/raw/master/nssm-2.24/win64/nssm.exe
    - skip_verify: True # For simplicity in this lab

download_blackbox:
  archive.extracted:
    - name: 'C:\monitoring'
    - source: https://github.com/prometheus/blackbox_exporter/releases/download/v0.24.0/blackbox_exporter-0.24.0.windows-amd64.zip
    - skip_verify: True
    - enforce_toplevel: False

download_vmagent:
  archive.extracted:
    - name: 'C:\monitoring'
    - source: https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v1.93.0/vmutils-windows-amd64-v1.93.0.zip
    - skip_verify: True
    - enforce_toplevel: False

# --- CONFIGURATION FILES ---

configure_blackbox:
  file.managed:
    - name: 'C:\monitoring\blackbox.yml'
    - source: salt://monitoring/blackbox.yml

configure_vmagent:
  file.managed:
    - name: 'C:\monitoring\vmagent.yml'
    - source: salt://monitoring/vmagent.yml

# --- SERVICE INSTALLATION (Using NSSM) ---

install_blackbox_service:
  cmd.run:
    - name: 'C:\monitoring\nssm.exe install BlackboxExporter "C:\monitoring\blackbox_exporter-0.24.0.windows-amd64\blackbox_exporter.exe" "--config.file=C:\monitoring\blackbox.yml"'
    - unless: 'sc query BlackboxExporter'

install_vmagent_service:
  cmd.run:
    # Replace URL below with your VictoriaMetrics address
    - name: 'C:\monitoring\nssm.exe install VMAgent "C:\monitoring\vmagent-prod.exe" "-promscrape.config=C:\monitoring\vmagent.yml -remoteWrite.url=http://192.168.15.8:8431/api/v1/write"'
    - unless: 'sc query VMAgent'

# --- START SERVICES ---

start_blackbox:
  service.running:
    - name: BlackboxExporter
    - enable: True
    - require:
      - cmd: install_blackbox_service

start_vmagent:
  service.running:
    - name: VMAgent
    - enable: True
    - require:
      - cmd: install_vmagent_service

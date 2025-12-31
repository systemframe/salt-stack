# Create a directory for our tools
create_monitoring_dir:
  file.directory:
    - name: 'C:\monitoring'
    - win_owner: Administrators

# --- DOWNLOAD TOOLS ---

# CHANGED: Switched to official NSSM zip and using archive.extracted
# This is safer than finding a direct .exe link
download_nssm:
  archive.extracted:
    - name: 'C:\monitoring'
    - source: https://nssm.cc/release/nssm-2.24.zip
    - skip_verify: True
    - enforce_toplevel: False
    # IDEMPOTENCY: Don't extract if we already see the folder
    - if_missing: 'C:\monitoring\nssm-2.24'

download_blackbox:
  archive.extracted:
    - name: 'C:\monitoring'
    - source: https://github.com/prometheus/blackbox_exporter/releases/download/v0.24.0/blackbox_exporter-0.24.0.windows-amd64.zip
    - skip_verify: True
    - enforce_toplevel: False
    # IDEMPOTENCY: Don't extract if existing
    - if_missing: 'C:\monitoring\blackbox_exporter-0.24.0.windows-amd64'

download_vmagent:
  archive.extracted:
    - name: 'C:\monitoring'
    # FIXED: Using a more stable recent release link
    - source: https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v1.93.0/vmutils-windows-amd64-v1.93.0.zip
    - skip_verify: True
    - enforce_toplevel: False
    # IDEMPOTENCY check (checks for the specific exe)
    - if_missing: 'C:\monitoring\vmagent-windows-amd64-prod.exe'

# --- CONFIGURATION FILES ---

configure_blackbox:
  file.managed:
    - name: 'C:\monitoring\blackbox.yml'
    - source: salt://monitoring/blackbox.yml
    - require:
        - file: create_monitoring_dir

configure_vmagent:
  file.managed:
    - name: 'C:\monitoring\vmagent.yml'
    - source: salt://monitoring/vmagent.yml
    - require:
        - file: create_monitoring_dir

# --- SERVICE INSTALLATION (Using NSSM) ---

install_blackbox_service:
  cmd.run:
    # FIXED PATH: NSSM extracts to a subfolder (nssm-2.24\win64\nssm.exe)
    - name: 'C:\monitoring\nssm-2.24\win64\nssm.exe install BlackboxExporter "C:\monitoring\blackbox_exporter-0.24.0.windows-amd64\blackbox_exporter.exe" "--config.file=C:\monitoring\blackbox.yml"'
    # IDEMPOTENCY: Only run if service is missing
    - unless: 'sc query BlackboxExporter'
    - require:
        - archive: download_nssm
        - archive: download_blackbox
        - file: configure_blackbox

install_vmagent_service:
  cmd.run:
    # FIXED PATH: vmagent binary name corrected to 'vmagent-windows-amd64-prod.exe'
    # Replace the URL below with your actual VictoriaMetrics IP
    - name: 'C:\monitoring\nssm-2.24\win64\nssm.exe install VMAgent "C:\monitoring\vmagent-windows-amd64-prod.exe" "-promscrape.config=C:\monitoring\vmagent.yml -remoteWrite.url=http://192.168.15.8:8431/api/v1/write"'
    # IDEMPOTENCY: Only run if service is missing
    - unless: 'sc query VMAgent'
    - require:
        - archive: download_nssm
        - archive: download_vmagent
        - file: configure_vmagent

# --- START SERVICES ---

start_blackbox:
  service.running:
    - name: BlackboxExporter
    - enable: True
    # "require" ensures the service is installed before we try to start it
    - require:
      - cmd: install_blackbox_service
    # "watch" ensures we restart if the config file changes
    - watch:
      - file: configure_blackbox

start_vmagent:
  service.running:
    - name: VMAgent
    - enable: True
    # "require" ensures the service is installed before we try to start it
    - require:
      - cmd: install_vmagent_service
    # "watch" ensures we restart if the config file changes
    - watch:
      - file: configure_vmagent

configure_auto_updates:
  schedule.present:
    - name: maintain_compliance
    - function: state.apply
    - minutes: 1            # Run every 1 minute (increase for Prod)
    - splay: 5              # Add 5s random delay (prevents traffic spikes if you had 1000 minions)
    - return_job: False     # Don't flood the Master's job log with success messages

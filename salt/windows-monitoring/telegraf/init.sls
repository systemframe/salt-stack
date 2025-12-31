# Windows Monitoring - Telegraf State
#
# Main monitoring stack for all Windows servers
# Collects Windows performance metrics and custom PowerShell script outputs

{% set install_dir = salt['pillar.get']('monitoring:install_dir', 'C:\\Monitoring') %}
{% set version = salt['pillar.get']('monitoring:versions:telegraf', '1.28.0') %}

# Create Telegraf directories
telegraf_directories:
  file.directory:
    - names:
      - {{ install_dir }}\Telegraf
      - {{ install_dir }}\Telegraf\Scripts
      - {{ install_dir }}\Telegraf\Output
      - C:\Program Files\telegraf
    - makedirs: True

# Download Telegraf
download_telegraf:
  archive.extracted:
    - name: C:\Program Files\telegraf
    - source: https://dl.influxdata.com/telegraf/releases/telegraf-{{ version }}_windows_amd64.zip
    - skip_verify: True
    - enforce_toplevel: False
    - if_missing: C:\Program Files\telegraf\telegraf-{{ version }}\telegraf.exe
    - require:
      - file: telegraf_directories

# Deploy Telegraf configuration
telegraf_config:
  file.managed:
    - name: C:\Program Files\telegraf\telegraf.conf
    - source: salt://windows-monitoring/files/telegraf.conf.jinja
    - template: jinja
    - require:
      - archive: download_telegraf

# Deploy custom thresholds file
telegraf_thresholds:
  file.managed:
    - name: {{ install_dir }}\Telegraf\custom_thresholds.txt
    - source: salt://windows-monitoring/files/custom_thresholds.txt.jinja
    - template: jinja
    - require:
      - file: telegraf_directories

# Deploy PowerShell scripts
get_sessions_script:
  file.managed:
    - name: {{ install_dir }}\Telegraf\Scripts\get_sessions.ps1
    - source: salt://windows-monitoring/files/scripts/get_sessions.ps1.jinja
    - template: jinja
    - require:
      - file: telegraf_directories

get_sessions_cpu_script:
  file.managed:
    - name: {{ install_dir }}\Telegraf\Scripts\get_sessions_cpu.ps1
    - source: salt://windows-monitoring/files/scripts/get_sessions_cpu.ps1.jinja
    - template: jinja
    - require:
      - file: telegraf_directories

shutdown_event_log_script:
  file.managed:
    - name: {{ install_dir }}\Telegraf\Scripts\shutdown_event_log.ps1
    - source: salt://windows-monitoring/files/scripts/shutdown_event_log.ps1.jinja
    - template: jinja
    - require:
      - file: telegraf_directories

# Uninstall broken Telegraf service if it exists but isn't startable
uninstall_broken_telegraf_service:
  cmd.run:
    - name: '& "C:\Program Files\telegraf\telegraf-{{ version }}\telegraf.exe" --service uninstall'
    - shell: powershell
    - onlyif: 'if ((Get-Service -Name telegraf -ErrorAction SilentlyContinue) -and -not (Get-Service -Name telegraf).CanStop) { exit 0 } else { exit 1 }'
    - require:
      - archive: download_telegraf

# Install Telegraf as Windows service
install_telegraf_service:
  cmd.run:
    - name: '& "C:\Program Files\telegraf\telegraf-{{ version }}\telegraf.exe" --service install --config "C:\Program Files\telegraf\telegraf.conf"'
    - shell: powershell
    - unless: '(Get-Service -Name telegraf -ErrorAction SilentlyContinue) -and (Get-Service -Name telegraf).Status'
    - require:
      - archive: download_telegraf
      - file: telegraf_config
      - cmd: uninstall_broken_telegraf_service

# Ensure Telegraf service is running
telegraf_service:
  service.running:
    - name: telegraf
    - enable: True
    - watch:
      - file: telegraf_config
      - file: telegraf_thresholds
    - require:
      - cmd: install_telegraf_service

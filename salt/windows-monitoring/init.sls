# Windows Monitoring - Main Orchestrator
#
# Installation paths:
# - Telegraf: Always installed (main monitoring stack)
# - Windows Exporter + VMAgent: Only when windows_exporter_collectors is defined
#
# Usage:
#   Set 'monitoring:windows_exporter_collectors' in pillar to enable Windows Exporter
#   e.g., for IIS servers, add the 'iis' collector

{% set collectors = salt['pillar.get']('monitoring:windows_exporter_collectors', []) %}
{% set install_dir = salt['pillar.get']('monitoring:install_dir', 'C:\\Monitoring') %}

# Include sub-states based on configuration
include:
  # Always include Telegraf (main monitoring stack)
  - windows-monitoring.telegraf
{% if collectors %}
  # Additional: Windows Exporter + VMAgent when specific collectors are needed
  - windows-monitoring.windows_exporter
  - windows-monitoring.vmagent
{% endif %}

# Create base directory structure
monitoring_base_directory:
  file.directory:
    - name: {{ install_dir }}
    - makedirs: True

monitoring_logs_directory:
  file.directory:
    - name: {{ install_dir }}\Logs
    - makedirs: True
    - require:
      - file: monitoring_base_directory

monitoring_scripts_directory:
  file.directory:
    - name: {{ install_dir }}\Scripts
    - makedirs: True
    - require:
      - file: monitoring_base_directory

configure_auto_updates:
  schedule.present:
    - name: maintain_compliance
    - function: state.apply
    - minutes: 1            # Run every 1 minute (increase for Prod)
    - splay: 5              # Add 5s random delay (prevents traffic spikes if you had 1000 minions)
    - return_job: False     # Don't flood the Master's job log with success messages

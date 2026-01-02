# Global monitoring defaults
# These values are inherited by all minions and can be overridden
# in customer-specific or node-specific pillars

monitoring:
  # Installation directory
  install_dir: 'C:\Monitoring'
  deploy_version: tests
  # VictoriaMetrics configuration
  vmetrics:
    # Global credentials (fallback if not specified per-cluster)
    user: vmetricsuser
    password: |
      -----BEGIN PGP MESSAGE-----

      hQIMA5z+pdumeBvpAQ/+KESq6TaeW7bvrwyK1qkOkzMXAsx9m2dPbDM2rK92Homn
      IiOwsxSRw+T4FCZgRjXDKMLyE84oXNSf8JccwFU8g5tyb5LUeZIfSwHQM5q4tC+w
      9LD4RRvz2JbHwSGoUnNPMwr9wkSglNTIXzcLn8bqOFrYEaUxXfSaatnXKd7Ev7z2
      oozh6Udr3eL70pKruIDttt54B62U2LDY98mCfMql2Nu+mNZZIlM1cGRZ9MD+2t84
      CAHOQdjolGWKroA8Q2TVhxMYB8HudJfcv+Iq8le2ZqHEQiXwQeKbKe1oPeGPnIRm
      wGQOkB1dWZUa4aSo+VMbP352zuGilliClRavEAZV5MSbu14A2iMFiPAk/r10Z3uW
      9aBJ0KlbLrxOWphRAOnynF5vQI6XtsPedzMnOzVkduSmFzxRgyVxWa9gFBQCw0rj
      ExF/h5YZJak9cX24vG0ia0mJyeyoOp3h4gQo1BhHwAIODGW+9dXqYE545uy/+y6a
      cYx5xCopi0XrTXlBkg4Dfqem4KK+Z6z8iwGKGr0c2wheSq76EtWHCZ+YZkqZJQcz
      zWQeLh14rZwJNfgUBHRPb1el9a+iARFCV2wyn5SrzDkLb2tUeScE27W52y6JqaCF
      VuxGeZLx0grSE6IilGfrTeyztXrfgEAZYw9XSFKCN2NcAhO9J6CJMC/5YMBoNQfU
      bQEJAhDJcMnUxui14kHHt8XGVraDEWo9ujtjVNgANgnMs0FMxEhlm/EpkQj6xDno
      nUuFNMuWcCPesPe81iPkmWDHs8XtJfs90SnZDrQ5fGvFcRGPUfUzyGO3+FEV9LlU
      eORc6FzyY6ALnmmkd4Q=
      =518w
      -----END PGP MESSAGE-----

    prefix_url: '/insert/0/prometheus/api/v1/write'

    # Cluster list with collapse merge support
    # Per-cluster user/password overrides global values
    clusters:
      - host: vmcluster-az-a.systemframe.com.br
        port: 30480
        # user/password inherited from global

      - host: vmcluster-az-b.systemframe.com.br
        port: 30480
        # user/password inherited from global

  # Component versions
  versions:
    windows_exporter: '0.29.0'
    vmagent: '1.102.3'
    telegraf: '1.28.0'
    nssm: '2.24'
    winsw: '2.12.0'

  # SHA256 checksums for integrity verification
  checksums:
    telegraf_exe: '4f22bf3dc3e00967d464df04b8926d159e7ad814af5ac80d60089b929db82ede'
    telegraf_zip: '3586051f47b05d1b2869cac8e77d7418537ce5b5464cf3891cdb0d1b62996485'
    vmagent_exe: '1bcfef0a8a546d566657d74baab7e9edd4f98b22832c40d5aae29d212d29dc1b'

  # Default Windows Exporter collectors (only used when windows_exporter_collectors is set)
  default_windows_exporter_collectors:
    - os
    - cpu
    - logical_disk
    - memory
    - net
    - physical_disk
    - service
    - system
    - process
    - cs
    - tcp
    # Disabled due to performance issues:
    # - netframework
    # - thermalzone
    # - update
    # - time
    # - remote_fx

  # Scrape settings
  scrape_interval: '15s'
  scrape_timeout: '15s'

  # Agent settings
  agent:
    interval: '30s'
    batch_size: 1000
    buffer_limit: 10000

  # Default thresholds for alerting
  thresholds:
    cpu: 90
    mem: 90
    disk: 90

  # Telegraf collectors (optional features)
  # telegraf_collectors:
  #   - process
  #   - service

  # Services to monitor (when 'service' is in telegraf_collectors)
  # monitor_services:
  #   - W3SVC
  #   - MSSQLSERVER

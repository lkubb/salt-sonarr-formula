# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- set sls_config_clean = tplroot ~ '.config.clean' %}
{%- from tplroot ~ "/map.jinja" import mapdata as sonarr with context %}

include:
  - {{ sls_config_clean }}

{%- if sonarr.install.autoupdate_service %}

Podman autoupdate service is disabled for Sonarr:
{%-   if sonarr.install.rootless %}
  compose.systemd_service_disabled:
    - user: {{ sonarr.lookup.user.name }}
{%-   else %}
  service.disabled:
{%-   endif %}
    - name: podman-auto-update.timer
{%- endif %}

Sonarr is absent:
  compose.removed:
    - name: {{ sonarr.lookup.paths.compose }}
    - volumes: {{ sonarr.install.remove_all_data_for_sure }}
{%- for param in ["project_name", "container_prefix", "pod_prefix", "separator"] %}
{%-   if sonarr.lookup.compose.get(param) is not none %}
    - {{ param }}: {{ sonarr.lookup.compose[param] }}
{%-   endif %}
{%- endfor %}
{%- if sonarr.install.rootless %}
    - user: {{ sonarr.lookup.user.name }}
{%- endif %}
    - require:
      - sls: {{ sls_config_clean }}

Sonarr compose file is absent:
  file.absent:
    - name: {{ sonarr.lookup.paths.compose }}
    - require:
      - Sonarr is absent

Sonarr user session is not initialized at boot:
  compose.lingering_managed:
    - name: {{ sonarr.lookup.user.name }}
    - enable: false
    - onlyif:
      - fun: user.info
        name: {{ sonarr.lookup.user.name }}

Sonarr user account is absent:
  user.absent:
    - name: {{ sonarr.lookup.user.name }}
    - purge: {{ sonarr.install.remove_all_data_for_sure }}
    - require:
      - Sonarr is absent
    - retry:
        attempts: 5
        interval: 2

{%- if sonarr.install.remove_all_data_for_sure %}

Sonarr paths are absent:
  file.absent:
    - names:
      - {{ sonarr.lookup.paths.base }}
    - require:
      - Sonarr is absent
{%- endif %}

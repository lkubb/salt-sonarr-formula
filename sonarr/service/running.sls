# vim: ft=sls

{%- set tplroot = tpldir.split("/")[0] %}
{%- set sls_config_file = tplroot ~ ".config.file" %}
{%- from tplroot ~ "/map.jinja" import mapdata as sonarr with context %}

include:
  - {{ sls_config_file }}

Sonarr service is enabled:
  compose.enabled:
    - name: {{ sonarr.lookup.paths.compose }}
{%- for param in ["project_name", "container_prefix", "pod_prefix", "separator"] %}
{%-   if sonarr.lookup.compose.get(param) is not none %}
    - {{ param }}: {{ sonarr.lookup.compose[param] }}
{%-   endif %}
{%- endfor %}
    - require:
      - Sonarr is installed
{%- if sonarr.install.rootless %}
    - user: {{ sonarr.lookup.user.name }}
{%- endif %}

Sonarr service is running:
  compose.running:
    - name: {{ sonarr.lookup.paths.compose }}
{%- for param in ["project_name", "container_prefix", "pod_prefix", "separator"] %}
{%-   if sonarr.lookup.compose.get(param) is not none %}
    - {{ param }}: {{ sonarr.lookup.compose[param] }}
{%-   endif %}
{%- endfor %}
{%- if sonarr.install.rootless %}
    - user: {{ sonarr.lookup.user.name }}
{%- endif %}
    - watch:
      - Sonarr is installed
      - Sonarr environment files are managed
      - Sonarr data path exists
      - Sonarr xml config file is managed

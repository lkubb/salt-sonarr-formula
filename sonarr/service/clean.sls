# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import mapdata as sonarr with context %}

sonarr service is dead:
  compose.dead:
    - name: {{ sonarr.lookup.paths.compose }}
{%- for param in ["project_name", "container_prefix", "pod_prefix", "separator"] %}
{%-   if sonarr.lookup.compose.get(param) is not none %}
    - {{ param }}: {{ sonarr.lookup.compose[param] }}
{%-   endif %}
{%- endfor %}
{%- if sonarr.install.rootless %}
    - user: {{ sonarr.lookup.user.name }}
{%- endif %}

sonarr service is disabled:
  compose.disabled:
    - name: {{ sonarr.lookup.paths.compose }}
{%- for param in ["project_name", "container_prefix", "pod_prefix", "separator"] %}
{%-   if sonarr.lookup.compose.get(param) is not none %}
    - {{ param }}: {{ sonarr.lookup.compose[param] }}
{%-   endif %}
{%- endfor %}
{%- if sonarr.install.rootless %}
    - user: {{ sonarr.lookup.user.name }}
{%- endif %}

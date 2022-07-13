# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import mapdata as sonarr with context %}
{%- from tplroot ~ "/libtofs.jinja" import files_switch with context %}

Sonarr user account is present:
  user.present:
{%- for param, val in sonarr.lookup.user.items() %}
{%-   if val is not none and param != "groups" %}
    - {{ param }}: {{ val }}
{%-   endif %}
{%- endfor %}
    - usergroup: true
    - createhome: true
    - groups: {{ sonarr.lookup.user.groups | json }}
    # (on Debian 11) subuid/subgid are only added automatically for non-system users
    - system: false

Sonarr user session is initialized at boot:
  compose.lingering_managed:
    - name: {{ sonarr.lookup.user.name }}
    - enable: {{ sonarr.install.rootless }}

Sonarr paths are present:
  file.directory:
    - names:
      - {{ sonarr.lookup.paths.base }}
    - user: {{ sonarr.lookup.user.name }}
    - group: {{ sonarr.lookup.user.name }}
    - makedirs: true
    - require:
      - user: {{ sonarr.lookup.user.name }}

Sonarr compose file is managed:
  file.managed:
    - name: {{ sonarr.lookup.paths.compose }}
    - source: {{ files_switch(['docker-compose.yml', 'docker-compose.yml.j2'],
                              lookup='Sonarr compose file is present'
                 )
              }}
    - mode: '0644'
    - user: root
    - group: {{ sonarr.lookup.rootgroup }}
    - makedirs: True
    - template: jinja
    - makedirs: true
    - context:
        sonarr: {{ sonarr | json }}

Sonarr is installed:
  compose.installed:
    - name: {{ sonarr.lookup.paths.compose }}
{%- for param, val in sonarr.lookup.compose.items() %}
{%-   if val is not none and param != "service" %}
    - {{ param }}: {{ val }}
{%-   endif %}
{%- endfor %}
{%- for param, val in sonarr.lookup.compose.service.items() %}
{%-   if val is not none %}
    - {{ param }}: {{ val }}
{%-   endif %}
{%- endfor %}
    - watch:
      - file: {{ sonarr.lookup.paths.compose }}
{%- if sonarr.install.rootless %}
    - user: {{ sonarr.lookup.user.name }}
    - require:
      - user: {{ sonarr.lookup.user.name }}
{%- endif %}

Custom Sonarr xml serializer is installed:
  saltutil.sync_all:
    - refresh: true
    - extmod_whitelist:
        serializers:
          - sonarr_xml

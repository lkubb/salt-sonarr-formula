# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import mapdata as sonarr with context %}
{%- from tplroot ~ "/libtofs.jinja" import files_switch with context %}

Sonarr user account is present:
  user.present:
{%- for param, val in sonarr.lookup.user.items() %}
{%-   if val is not none and param not in ["groups", "gid"] %}
    - {{ param }}: {{ val }}
{%-   endif %}
{%- endfor %}
    - usergroup: true
    - createhome: true
    - groups: {{ sonarr.lookup.user.groups | json }}
    # (on Debian 11) subuid/subgid are only added automatically for non-system users
    - system: false
{%- if not sonarr.lookup.media_group.gid %}]
    - gid: {{ sonarr.lookup.user.gid or "null" }}
{%- else %}
    - gid: {{ sonarr.lookup.media_group.gid }}
    - require:
      - group: {{ sonarr.lookup.media_group.name }}
  group.present:
    - name: {{ sonarr.lookup.media_group.name }}
    - gid: {{ sonarr.lookup.media_group.gid }}
{%- endif %}

Sonarr user session is initialized at boot:
  compose.lingering_managed:
    - name: {{ sonarr.lookup.user.name }}
    - enable: {{ sonarr.install.rootless }}
    - require:
      - user: {{ sonarr.lookup.user.name }}

Sonarr paths are present:
  file.directory:
    - names:
      - {{ sonarr.lookup.paths.base }}
    - user: {{ sonarr.lookup.user.name }}
    - group: __slot__:salt:user.primary_group({{ sonarr.lookup.user.name }})
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
{%-   if val is not none and param not in ["service"] %}
    - {{ param }}: {{ val }}
{%-   endif %}
{%- endfor %}
{%- if sonarr.container.userns_keep_id and sonarr.install.rootless %}
    - podman_create_args:
{%-   if sonarr.lookup.compose.create_pod is false %}
{#-     post-map.jinja ensures this is in pod_args if pods are in use #}
        # this maps the host uid/gid to the same ones inside the container
        # important for network share access
        # https://github.com/containers/podman/issues/5239#issuecomment-587175806
      - userns: keep-id
{%-   endif %}
        # linuxserver images generally assume to be started as root,
        # then drop privileges as defined in PUID/PGID.
      - user: 0
{%- endif %}
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
  saltutil.sync_serializers:
    - refresh: true

{%- if sonarr.install.autoupdate_service is not none %}

Podman autoupdate service is managed for Sonarr:
{%-   if sonarr.install.rootless %}
  compose.systemd_service_{{ "enabled" if sonarr.install.autoupdate_service else "disabled" }}:
    - user: {{ sonarr.lookup.user.name }}
{%-   else %}
  service.{{ "enabled" if sonarr.install.autoupdate_service else "disabled" }}:
{%-   endif %}
    - name: podman-auto-update.timer
{%- endif %}

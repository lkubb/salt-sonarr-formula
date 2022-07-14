# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- set sls_package_install = tplroot ~ '.package.install' %}
{%- from tplroot ~ "/map.jinja" import mapdata as sonarr with context %}
{%- from tplroot ~ "/libtofs.jinja" import files_switch with context %}

include:
  - {{ sls_package_install }}

Sonarr environment files are managed:
  file.managed:
    - names:
      - {{ sonarr.lookup.paths.config_sonarr }}:
        - source: {{ files_switch(['sonarr.env', 'sonarr.env.j2'],
                                  lookup='sonarr environment file is managed',
                                  indent_width=10,
                     )
                  }}
    - mode: '0640'
    - user: root
    - group: {{ sonarr.lookup.user.name }}
    - makedirs: True
    - template: jinja
    - require:
      - user: {{ sonarr.lookup.user.name }}
    - watch_in:
      - Sonarr is installed
    - context:
        sonarr: {{ sonarr | json }}

Sonarr xml config file is managed:
  file.serialize:
    - name: {{ sonarr.lookup.paths.data | path_join("config.xml") }}
    - mode: '0644'
    - user: {{ sonarr.lookup.user.name }}
    - group: {{ sonarr.lookup.user.name }}
    - makedirs: True
    - require:
      - user: {{ sonarr.lookup.user.name }}
      - Custom Sonarr xml serializer is installed
    - watch_in:
      - Sonarr is installed
    - serializer: sonarr_xml
    - merge_if_exists: true
    - dataset: {{ sonarr.config.general | json }}

{%- set puid_pgid = (sonarr.container.puid or 911) ~ ":" ~ (sonarr.container.pgid or 911) %}

# The container entry script does not ensure proper permissions.
Sonarr xml config file has the correct owner:
  cmd.run:
    - name: |
{%- if sonarr.install.rootless %}
        podman unshare \
{%- endif %}
        chown {{ puid_pgid }} config.xml
    - cwd: {{ sonarr.lookup.paths.data }}
    - unless:
      - "[ $(stat --format '%u:%g' '{{ sonarr.lookup.paths.data | path_join("config.xml") }}') = '{{ puid_pgid }}' ]"
    - onlyif:
      - fun: file.file_exists
        path: {{ sonarr.lookup.paths.data | path_join("config.xml") }}
{%- if sonarr.install.rootless %}
    - runas: {{ sonarr.lookup.user.name }}
{%- endif %}

{%- if sonarr.mount_paths %}

Sonarr has initialized the database:
  compose.running:
    - name: {{ sonarr.lookup.paths.compose }}
{%-   for param in ["project_name", "container_prefix", "pod_prefix", "separator"] %}
{%-     if sonarr.lookup.compose.get(param) is not none %}
    - {{ param }}: {{ sonarr.lookup.compose[param] }}
{%-     endif %}
{%-   endfor %}
{%-   if sonarr.install.rootless %}
    - user: {{ sonarr.lookup.user.name }}
{%-   endif %}
    - timeout: 20
    - require:
      - Sonarr is installed
    - unless:
      - fun: file.file_exists
        path: {{ sonarr.lookup.paths.data | path_join("sonarr.db") }}

Sonarr is not running before database modification:
  compose.dead:
    - name: {{ sonarr.lookup.paths.compose }}
{%-   for param in ["project_name", "container_prefix", "pod_prefix", "separator"] %}
{%-     if sonarr.lookup.compose.get(param) is not none %}
    - {{ param }}: {{ sonarr.lookup.compose[param] }}
{%-     endif %}
{%-   endfor %}
{%-   if sonarr.install.rootless %}
    - user: {{ sonarr.lookup.user.name }}
{%-   endif %}
    - timeout: 20
    - require:
      - Sonarr is installed

Sonarr mount paths are setup as root folders:
  sqlite3.row_present:
    - names:
{%- for path in sonarr.mount_paths %}
      - {{ path }}:
        - where_args:
          - {{ path }}
        - data:
            Path: {{ path }}
{%- endfor %}
    - db: {{ sonarr.lookup.paths.data | path_join("sonarr.db") }}
    - table: RootFolders
    - where_sql: Path=?
    - require:
      - Sonarr has initialized the database
    - prereq:
      - Sonarr is not running before database modification

Sonarr is running again after shutdown:
  compose.running:
    - name: {{ sonarr.lookup.paths.compose }}
{%-   for param in ["project_name", "container_prefix", "pod_prefix", "separator"] %}
{%-     if sonarr.lookup.compose.get(param) is not none %}
    - {{ param }}: {{ sonarr.lookup.compose[param] }}
{%-     endif %}
{%-   endfor %}
{%-   if sonarr.install.rootless %}
    - user: {{ sonarr.lookup.user.name }}
{%-   endif %}
    - timeout: 20
    - require:
      - Sonarr is installed
    - onchanges:
      - Sonarr is not running before database modification
{%- endif %}

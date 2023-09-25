# vim: ft=sls

{%- set tplroot = tpldir.split("/")[0] %}
{%- set sls_package_install = tplroot ~ ".package.install" %}
{%- from tplroot ~ "/map.jinja" import mapdata as sonarr with context %}
{%- from tplroot ~ "/libtofsstack.jinja" import files_switch with context %}

include:
  - {{ sls_package_install }}

Sonarr environment files are managed:
  file.managed:
    - names:
      - {{ sonarr.lookup.paths.config_sonarr }}:
        - source: {{ files_switch(
                        ["sonarr.env", "sonarr.env.j2"],
                        config=sonarr,
                        lookup="sonarr environment file is managed",
                        indent_width=10,
                     )
                  }}
    - mode: '0640'
    - user: root
    - group: __slot__:salt:user.primary_group({{ sonarr.lookup.user.name }})
    - makedirs: true
    - template: jinja
    - require:
      - user: {{ sonarr.lookup.user.name }}
    - require_in:
      - Sonarr is installed
    - context:
        sonarr: {{ sonarr | json }}

Sonarr data path exists:
  compose.file_directory:
    - name: {{ sonarr.lookup.paths.data }}
    - project: {{ sonarr.lookup.paths.compose }}
    - mode: '0755'
    - user: {{ sonarr.container.puid or 911 }}
    - group: {{ sonarr.container.pgid or 911 }}
    - fail_kwargs:
        user: {{ sonarr.lookup.user.name }}
        group: __slot__:salt:user.primary_group({{ sonarr.lookup.user.name }})
    - makedirs: true
    - require:
      - user: {{ sonarr.lookup.user.name }}
      - Sonarr is installed

Sonarr xml config file is managed:
  compose.file_serialize:
    - name: {{ sonarr.lookup.paths.data | path_join("config.xml") }}
    - project: {{ sonarr.lookup.paths.compose }}
    - mode: '0644'
    - user: {{ sonarr.container.puid or 911 }}
    - group: {{ sonarr.container.pgid or 911 }}
    - fail_kwargs:
        user: {{ sonarr.lookup.user.name }}
        group: __slot__:salt:user.primary_group({{ sonarr.lookup.user.name }})
    - serializer: sonarr_xml
    - merge_if_exists: true
    - require:
      - Sonarr data path exists
      - Custom Sonarr xml serializer is installed
    - dataset: {{ sonarr.config.general | json }}

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
    - prereq:
      - Sonarr mount paths are setup as root folders

Sonarr mount paths are setup as root folders:
  sqlite3.row_present:
    - names:
{%- for path in sonarr.mount_paths %}
{%-   set render_path = path.values() | first if path is mapping else path %}
      - {{ render_path }}:
        - where_args:
          - {{ render_path }}
        - data:
            Path: {{ render_path }}
{%- endfor %}
    - db: {{ sonarr.lookup.paths.data | path_join("sonarr.db") }}
    - table: RootFolders
    - where_sql: Path=?
    - onlyif:
      - fun: file.file_exists
        path: {{ sonarr.lookup.paths.data | path_join("sonarr.db") }}
    - require:
      - Sonarr has initialized the database

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

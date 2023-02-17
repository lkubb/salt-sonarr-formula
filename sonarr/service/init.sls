# vim: ft=sls

{#-
    Starts the sonarr container services
    and enables them at boot time.
    Has a dependency on `sonarr.config`_.
#}

include:
  - .running

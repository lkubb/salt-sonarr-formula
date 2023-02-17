Available states
----------------

The following states are found in this formula:

.. contents::
   :local:


``sonarr``
^^^^^^^^^^
*Meta-state*.

This installs the sonarr containers,
manages their configuration and starts their services.


``sonarr.package``
^^^^^^^^^^^^^^^^^^
Installs the sonarr containers only.
This includes creating systemd service units.


``sonarr.config``
^^^^^^^^^^^^^^^^^
Manages the configuration of the sonarr containers.
Has a dependency on `sonarr.package`_.


``sonarr.service``
^^^^^^^^^^^^^^^^^^
Starts the sonarr container services
and enables them at boot time.
Has a dependency on `sonarr.config`_.


``sonarr.clean``
^^^^^^^^^^^^^^^^
*Meta-state*.

Undoes everything performed in the ``sonarr`` meta-state
in reverse order, i.e. stops the sonarr services,
removes their configuration and then removes their containers.


``sonarr.package.clean``
^^^^^^^^^^^^^^^^^^^^^^^^
Removes the sonarr containers
and the corresponding user account and service units.
Has a depency on `sonarr.config.clean`_.
If ``remove_all_data_for_sure`` was set, also removes all data.


``sonarr.config.clean``
^^^^^^^^^^^^^^^^^^^^^^^
Removes the configuration of the sonarr containers
and has a dependency on `sonarr.service.clean`_.

This does not lead to the containers/services being rebuilt
and thus differs from the usual behavior.


``sonarr.service.clean``
^^^^^^^^^^^^^^^^^^^^^^^^
Stops the sonarr container services
and disables them at boot time.



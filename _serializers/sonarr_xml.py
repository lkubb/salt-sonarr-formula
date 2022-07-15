"""
    Implements Sonarr ``config.xml`` serializer.
"""

from xml.etree import ElementTree as ET

from salt.serializers import DeserializationError, SerializationError
import salt.utils.xmlutil

__all__ = ["deserialize", "serialize", "available"]

available = True


def deserialize(stream_or_string, **options):
    """
    Deserialize any string or stream like object into a Python data structure.
    :param stream_or_string: stream or string to deserialize.
    """

    try:
        if not isinstance(stream_or_string, (bytes, str)):
            data = "".join(stream_or_string.readlines())
        elif isinstance(stream_or_string, bytes):
            data = stream_or_string.decode("utf-8")
        else:
            data = stream_or_string

        tree = ET.fromstring(data)
        ret = salt.utils.xmlutil.to_dict(tree)

        # no settings result in root to be read as {"Config": None}
        if "Config" in ret or not ret:
            return {}


        return ret

    except Exception as error:  # pylint: disable=broad-except
        raise DeserializationError(error)


def serialize(obj, **options):
    """
    Serialize Python data to Sonarr ``config.xml``.
    This is really dumb and does not implement a proper dict -> xml serializer.

    :param obj: the data structure to serialize
    """

    lines = []

    for conf, val in obj.items():
        val = val if val is not None else ''
        lines.append(f"  <{conf}>{val}</{conf}>")

    if not lines:
        return "<Config></Config>"

    return "\n".join(["<Config>"] + lines + ["</Config>\n"])

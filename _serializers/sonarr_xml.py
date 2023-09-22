"""
    Implements Sonarr ``config.xml`` serializer.
"""

from collections import defaultdict
from xml.dom import minidom
from xml.etree import ElementTree as ET

from salt.serializers import DeserializationError

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
        return etree_to_dict(tree)["Config"]

    except Exception as error:  # pylint: disable=broad-except
        raise DeserializationError(error)


def serialize(obj, **options):
    """
    Serialize Python data to Sonarr ``config.xml``.
    This is really dumb and does not implement a proper dict -> xml serializer.

    :param obj: the data structure to serialize
    """
    # Get string representation of object (unicode ensures its type is str, not bytes)
    xmlstr = ET.tostring(dict_to_etree(obj), encoding="unicode")
    # Pretty-print it in mostly Jellyfin format to avoid causing unnecessary diffs
    pp_xmlstr = minidom.parseString(xmlstr).toprettyxml(indent="  ", encoding="utf-8")
    # return string representation and replace empty element endings to avoid diffs
    ret = pp_xmlstr.decode().replace("/>", " />")
    return ret


# The following serializers/deserializers are adapted from here:
# https://stackoverflow.com/a/10076823


def etree_to_dict(t):
    d = {t.tag: {} if t.attrib else None}
    children = list(t)
    if children:
        dd = defaultdict(list)
        for dc in map(etree_to_dict, children):
            for k, v in dc.items():
                dd[k].append(v)
        d = {t.tag: {k: v[0] if len(v) == 1 else v for k, v in dd.items()}}
    if t.attrib:
        d[t.tag].update(("@" + k, v) for k, v in t.attrib.items())
    if t.text:
        text = t.text.strip()
        if text in ["True", "False"]:
            text = text == "True"
        else:
            try:
                text = int(text)
            except ValueError:
                try:
                    text = float(text)
                except ValueError:
                    pass
        if children or t.attrib:
            if text:
                d[t.tag]["#text"] = text
        else:
            d[t.tag] = text
    return d


def dict_to_etree(d):
    def _to_etree(d, root):
        if d is None:
            pass
        elif isinstance(d, bool):
            root.text = str(d)
        elif isinstance(d, str) or isinstance(d, int) or isinstance(d, float):
            root.text = str(d)
        elif isinstance(d, dict):
            for k, v in d.items():
                assert isinstance(k, str)
                if k.startswith("#"):
                    assert k == "#text" and isinstance(v, str)
                    root.text = v
                elif k.startswith("@"):
                    assert isinstance(v, str)
                    root.set(k[1:], v)
                elif isinstance(v, list):
                    for e in v:
                        _to_etree(e, ET.SubElement(root, k))
                else:
                    _to_etree(v, ET.SubElement(root, k))
        else:
            assert d == "invalid type", (type(d), d)

    d = {"Config": d}
    assert isinstance(d, dict) and len(d) == 1
    tag, body = next(iter(d.items()))
    node = ET.Element(tag)
    _to_etree(body, node)
    return node

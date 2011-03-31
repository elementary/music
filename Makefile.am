SUBDIRS =               \
        src             \
        data            \
        images          \
        $(NULL)

ACLOCAL_AMFLAGS = -I m4

EXTRA_DIST = \
             org.elementary.beatbox.gschema.xml.in

gsettings_SCHEMAS = org.elementary.beatbox.gschema.xml
@GSETTINGS_RULES@
@INTLTOOL_XML_NOMERGE_RULE@

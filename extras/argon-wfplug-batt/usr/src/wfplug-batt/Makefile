# Rebuild libbatt.so against the wf-panel-pi plugin API.
#
#   WF_PANEL_PI_SRC=/path/to/wf-panel-pi make
#
# WF_PANEL_PI_SRC must point to a wf-panel-pi source tree containing
# src/wf-panel-pi/plugin.h and src/wf-panel-pi/widget.hpp. The plugin is
# loaded by wf-panel-pi at runtime, so wf-panel-pi itself is not linked into
# the shared object.

CXX ?= g++
CC ?= gcc
PKG_CONFIG ?= pkg-config
WF_PANEL_PI_SRC ?= ../../../../../wf-panel-pi
WF_PANEL_PI_INC ?= $(WF_PANEL_PI_SRC)/src/wf-panel-pi

GETTEXT_PACKAGE ?= wfplug_batt
PLUGIN_NAME ?= batt

CPPFLAGS += -I. -I$(WF_PANEL_PI_INC) \
            -DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\" \
            -DPLUGIN_NAME=\"$(PLUGIN_NAME)\" \
            -DPACKAGE_DATA_DIR=\"/usr/share/wf-panel-pi\" \
            -DPACKAGE_LOCALE_DIR=\"/usr/share/locale\"
CFLAGS += -O2 -fPIC -Wall -Wextra $(shell $(PKG_CONFIG) --cflags gtk+-3.0 glib-2.0 gtk-layer-shell-0)
CXXFLAGS += -O2 -fPIC -Wall -Wextra $(shell $(PKG_CONFIG) --cflags gtkmm-3.0 glibmm-2.4 gtk-layer-shell-0)
LDLIBS += $(shell $(PKG_CONFIG) --libs gtkmm-3.0 glibmm-2.4 gtk+-3.0 glib-2.0 gtk-layer-shell-0)

OBJS = batt.o batt_sys.o batt_cpp.o

all: libbatt.so

libbatt.so: $(OBJS)
	$(CXX) -shared -Wl,-soname,libbatt.so -o $@ $(OBJS) $(LDLIBS)

batt.o: batt.c batt.h batt_sys.h
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ batt.c

batt_sys.o: batt_sys.c batt_sys.h
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ batt_sys.c

batt_cpp.o: batt.cpp batt.hpp batt.h batt_sys.h
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c -o $@ batt.cpp

clean:
	rm -f $(OBJS) libbatt.so

.PHONY: all clean

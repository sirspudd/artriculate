TEMPLATE = subdirs

CONFIG += ordered

SUBDIRS += src qml

symlink.path = /usr/bin
symlink.files = artriculate

license.path = /usr/share/artriculate
license.files = license.txt

INSTALLS += symlink license

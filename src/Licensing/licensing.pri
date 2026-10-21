QT += widgets
SOURCES += $$PWD/OfflineLicense.cc $$PWD/ActivationDialog.cc
HEADERS += $$PWD/OfflineLicense.h $$PWD/ActivationDialog.h $$PWD/LicensePublicKey.h
win32 {
    LIBS += -lbcrypt
} else {
    LIBS += -lcrypto
}

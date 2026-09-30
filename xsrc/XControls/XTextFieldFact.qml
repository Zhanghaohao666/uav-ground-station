import QtQuick 2.0

import QGroundControl.FactSystem    1.0

import XUI 1.0

XTextField {
    id: _textField

    text:       fact ? fact.valueString : ""
    unit:       fact ? fact.units : ""

    signal updated()

    property Fact   fact: null
    property bool numberMode: false

    Connections {
        target: fact
        onRawValueChanged:{
            oldText = fact.valueString
        }
    }

    onFactChanged: oldText = fact.valueString


    property string _validateString

    inputMethodHints: ((fact && fact.typeIsString)) ?
                          Qt.ImhNone :                // iOS numeric keyboard has no done button, we can't use it
                          Qt.ImhFormattedNumbersOnly  // Forces use of virtual numeric keyboard

    onEditingFinished: {
        var errorString = fact.validate(text, false /* convertOnly */)
        if (errorString === "") {
            fact.value = text
            _textField.updated()
        } else {
            _validateString = text
            // validationErrorDialogComponent.createObject(mainWindow).open()
        }
    }


    onSave: {
        var errorString = fact.validate(text, false /* convertOnly */)
        if (errorString === "") {
            fact.value = numberMode ? Number(text) : text
        } else {
            _validateString = text
        }
    }
}

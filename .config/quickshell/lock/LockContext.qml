import QtQuick
import Quickshell
import Quickshell.Services.Pam

// State shared by the lock surfaces on every screen.
Scope {
    id: root

    signal unlocked()
    signal failed()

    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false
    property int failedAttempts: 0

    onCurrentTextChanged: if (currentText !== "") showFailure = false

    function tryUnlock() {
        if (currentText === "" || unlockInProgress) return;
        unlockInProgress = true;
        pam.start();
    }

    PamContext {
        id: pam

        configDirectory: "pam"
        config: "password.conf"

        onPamMessage: {
            if (this.responseRequired) this.respond(root.currentText);
        }

        onCompleted: result => {
            if (result == PamResult.Success) {
                root.unlocked();
            } else {
                root.currentText = "";
                root.showFailure = true;
                root.failedAttempts += 1;
                root.failed();
            }
            root.unlockInProgress = false;
        }
    }
}

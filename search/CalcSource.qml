import QtQuick
import Quickshell.Io
import qs.theme

// The launcher's calculator: qalc works out `expr` shortly after typing
// stops. One qalc runs at a time, only while there is something to work
// out; a newer expression stops the old one.
Item {
    id: root

    // The expression, or "" for none.
    property string expr: ""
    // The answer for `answered`, or "".
    property string result: ""
    property string answered: ""
    property bool missing: false

    readonly property bool current: root.answered === root.expr.trim() && root.result.length > 0

    onExprChanged: {
        proc.running = false
        if (root.expr.trim().length)
            delay.restart()
        else
            delay.stop()
    }

    Timer {
        id: delay
        interval: Theme.searchDelayMs
        onTriggered: {
            const e = root.expr.trim()
            if (!e.length)
                return
            proc.out = ""
            proc.asked = e
            // A leading space keeps qalc from reading "-5" as an option.
            proc.command = ["qalc", "-t", " " + e]
            proc.running = true
            limit.restart()
        }
    }

    // qalc can stall (fetching exchange rates); give up after a while.
    Timer {
        id: limit
        interval: Theme.searchCalcLimitMs
        onTriggered: proc.running = false
    }

    // Answers once both the output and the exit code are in, in either order.
    Process {
        id: proc
        property string out: ""
        property string asked: ""
        property int code: 0
        property int parts: 0

        function finish() {
            if (proc.parts < 2)
                return
            const text = String(proc.out || "").trim().split("\n").pop().trim()
            root.missing = proc.code === 127 || proc.code < 0
            root.answered = proc.asked
            root.result = proc.code === 0 && text.length && text !== proc.asked ? text : ""
        }

        onRunningChanged: {
            if (proc.running)
                proc.parts = 0
        }
        stdout: StdioCollector {
            onStreamFinished: {
                proc.out = this.text
                proc.parts += 1
                proc.finish()
            }
        }
        onExited: (exitCode) => {
            limit.stop()
            proc.code = exitCode
            proc.parts += 1
            proc.finish()
        }
    }
}

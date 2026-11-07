import QtQuick

// Tiny assert helper for tests/*Test.qml. Each check prints one line that
// tests/run.sh counts: "PASS name" or "FAIL name: got …, want …". Call
// done() at the end so the runner knows the test finished.
QtObject {
    id: root

    property int failures: 0

    function ok(name, condition, detail) {
        if (condition) {
            console.log("PASS " + name)
        } else {
            root.failures++
            console.log("FAIL " + name + (detail ? ": " + detail : ""))
        }
    }

    function eq(name, got, want) {
        const a = JSON.stringify(got)
        const b = JSON.stringify(want)
        root.ok(name, a === b, "got " + a + ", want " + b)
    }

    function done() {
        console.log("DONE " + root.failures + " failed")
        Qt.quit()
    }
}

import QtQuick

// The unsaved draft behind one settings page, shared by every *Settings
// singleton. A page reads `value` and edits with set() or edit(). Apply
// saves, Undo drops a draft or puts back the last applied values, and
// Reset drafts the defaults (Apply then saves them).
//
// The owner is the feature singleton. It provides:
//   snapshot()     saved values as a plain object, already normalized
//   normalize(obj) a clamped copy with the same keys in the same order
//   commit(obj)    write obj to the saved fields
//   defaults()     the object Reset drafts
//   signature(obj) optional; see same()
//
// `value` is safe in bindings: reading it never writes. A clean draft
// follows the saved values, so a change saved elsewhere shows at once.
QtObject {
    id: root

    required property var owner

    property var draft: ({})
    property bool dirty: false
    property bool undoReady: false
    property var undoSnap: null

    readonly property var value: root.dirty ? root.draft : root.owner.snapshot()
    readonly property bool canUndo: root.dirty || root.undoReady

    // An owner may define signature(obj) when two drafts can differ in
    // text but save the same (an empty symbol saves the default).
    function same(a, b) {
        const o = root.owner
        if (typeof o.signature === "function")
            return o.signature(a) === o.signature(b)
        return JSON.stringify(a) === JSON.stringify(b)
    }

    // Merge changes into the draft. The page stays dirty only while the
    // draft differs from what is saved.
    function edit(changes) {
        const saved = root.owner.snapshot()
        const base = root.dirty ? root.draft : saved
        const next = root.owner.normalize(Object.assign({}, base, changes || {}))
        root.draft = next
        root.dirty = !root.same(next, saved)
    }

    function set(key, next) {
        const changes = {}
        changes[key] = next
        root.edit(changes)
    }

    function discard() {
        root.dirty = false
        root.draft = ({})
    }

    function apply() {
        if (!root.dirty)
            return false
        const next = root.draft
        root.undoSnap = root.owner.snapshot()
        root.undoReady = true
        root.discard()
        root.owner.commit(next)
        return true
    }

    // Returns true only when saved values changed.
    function undo() {
        if (root.dirty) {
            root.discard()
            return false
        }
        if (!root.undoReady)
            return false
        const previous = root.undoSnap
        root.undoSnap = null
        root.undoReady = false
        root.owner.commit(previous)
        return true
    }

    function reset() {
        root.edit(root.owner.defaults())
    }
}

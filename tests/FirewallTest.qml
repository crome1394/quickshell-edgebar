import QtQuick
import Quickshell
import qs.services
import "tests"

// FirewallService: reading UFW rule tuples, merging v4/v6, checking input,
// and the ufw words it would run (fixed argv, never a shell).
ShellRoot {
    Check { id: t }

    Component.onCompleted: {
        const F = FirewallService
        const v4 = "### RULES ###\n### tuple ### allow tcp 22 0.0.0.0/0 any 0.0.0.0/0 in\n-A ufw-user-input -p tcp --dport 22 -j ACCEPT\n"
            + "### tuple ### deny udp 5353 0.0.0.0/0 any 192.168.1.0/24 in comment=6d646e73\n"
            + "### tuple ### limit_log tcp 2222 0.0.0.0/0 any 0.0.0.0/0 in\n### END RULES ###\n"
        const v6 = "### tuple ### allow tcp 22 ::/0 any ::/0 in\n"
        const rules = F.mergeRules(F.parseTuples(v4, false), F.parseTuples(v6, true))
        t.eq("three rules (22 merged across v4/v6)", rules.length, 3)
        t.eq("ssh rule", [rules[0].action, rules[0].port, rules[0].proto, rules[0].families], ["allow", "22", "tcp", ["v4", "v6"]])
        t.eq("source kept, comment decoded", [rules[1].action, rules[1].from, rules[1].comment], ["deny", "192.168.1.0/24", "mdns"])
        t.eq("no comment stays empty", rules[0].comment, "")
        t.eq("bad comment ignored", [F.decodeComment("zz"), F.decodeComment("abc")], ["", ""])
        t.eq("utf-8 comment", F.decodeComment("636166c3a9"), "café")
        t.eq("_log suffix stripped", rules[2].action, "limit")
        t.eq("describe port", [F.describePort(rules[0]), F.describePort({ port: "any", proto: "any" })], ["22/tcp", "any port"])

        t.eq("simple rule words", F.ruleWords({ action: "allow", port: "22", proto: "tcp" }), ["allow", "22/tcp"])
        t.eq("both protocols", F.ruleWords({ action: "deny", port: "53", proto: "any" }), ["deny", "53"])
        t.eq("from an address", F.ruleWords({ action: "allow", port: "8080", proto: "tcp", from: "192.168.1.0/24" }),
            ["allow", "from", "192.168.1.0/24", "to", "any", "port", "8080", "proto", "tcp"])
        t.eq("range needs a protocol", F.ruleWords({ action: "allow", port: "6000:6010", proto: "any" }), [])
        t.eq("range with protocol", F.ruleWords({ action: "allow", port: "6000:6010", proto: "udp" }), ["allow", "6000:6010/udp"])
        t.eq("bad port refused", F.ruleWords({ action: "allow", port: "70000", proto: "tcp" }), [])
        t.eq("bad action refused", F.ruleWords({ action: "allow; rm -rf /", port: "22" }), [])
        t.eq("bad address refused", F.ruleWords({ action: "allow", port: "22", from: "evil.example; id" }), [])
        t.eq("nothing to match refused", F.ruleWords({ action: "allow" }), [])
        t.ok("IPv6 address accepted", F.addrOk("fd00::/8"))
        t.eq("delete words for a listed rule", F.deleteWords(rules[1]), ["deny", "from", "192.168.1.0/24", "to", "any", "port", "5353", "proto", "udp"])
        t.done()
    }
}

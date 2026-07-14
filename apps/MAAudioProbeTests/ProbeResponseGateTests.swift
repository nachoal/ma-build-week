import Testing
@testable import MAAudioProbe

@Suite("Probe response gate")
struct ProbeResponseGateTests {
    @Test("Only one response request can be pending")
    func duplicateRequestRejected() {
        var gate = ProbeResponseGate()

        let first = gate.beginRequest()
        let duplicate = gate.beginRequest()

        #expect(first)
        #expect(!duplicate)
        #expect(!gate.canRequest)
    }

    @Test("Output may establish the requested response before its start event")
    func reorderedOutputIsAdmittedOnce() {
        var gate = ProbeResponseGate()
        let request = gate.beginRequest()
        let firstOutput = gate.admitOutput(responseID: "resp_1")
        let started = gate.observeResponseStarted("resp_1")
        let competingOutput = gate.admitOutput(responseID: "resp_2")

        #expect(request)
        #expect(firstOutput == .accept)
        #expect(started)
        #expect(competingOutput == .rejectUnexpected)
    }

    @Test("Late output from a locally stopped response is rejected")
    func stoppedOutputRejected() {
        var gate = ProbeResponseGate()
        let request = gate.beginRequest()
        let started = gate.observeResponseStarted("resp_1")
        let stopped = gate.stopActiveResponse()
        let lateOutput = gate.admitOutput(responseID: "resp_1")

        #expect(request)
        #expect(started)
        #expect(stopped == "resp_1")
        #expect(lateOutput == .rejectStopped)
        #expect(gate.canRequest)
    }

    @Test("Missing response identifiers fail closed")
    func missingIdentifierRejected() {
        var gate = ProbeResponseGate()
        let request = gate.beginRequest()
        let missing = gate.admitOutput(responseID: nil)
        let empty = gate.admitOutput(responseID: "")

        #expect(request)
        #expect(missing == .rejectUnexpected)
        #expect(empty == .rejectUnexpected)
    }
}

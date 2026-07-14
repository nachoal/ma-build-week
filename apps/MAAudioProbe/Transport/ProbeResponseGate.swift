import Foundation

enum ProbeOutputDisposition: Sendable, Equatable {
    case accept
    case rejectStopped
    case rejectUnexpected
}

struct ProbeResponseGate: Sendable {
    private(set) var requestPending = false
    private(set) var activeResponseID: String?
    private var stoppedResponseIDs: Set<String> = []

    var canRequest: Bool {
        !requestPending && activeResponseID == nil
    }

    mutating func beginRequest() -> Bool {
        guard canRequest else { return false }
        requestPending = true
        return true
    }

    mutating func cancelPendingRequest() {
        guard activeResponseID == nil else { return }
        requestPending = false
    }

    mutating func observeResponseStarted(_ responseID: String?) -> Bool {
        guard requestPending,
              let responseID,
              !responseID.isEmpty,
              !stoppedResponseIDs.contains(responseID) else {
            return false
        }
        if let activeResponseID {
            return activeResponseID == responseID
        }
        activeResponseID = responseID
        return true
    }

    mutating func admitOutput(responseID: String?) -> ProbeOutputDisposition {
        guard let responseID, !responseID.isEmpty else {
            return .rejectUnexpected
        }
        if stoppedResponseIDs.contains(responseID) {
            return .rejectStopped
        }
        if let activeResponseID {
            return activeResponseID == responseID ? .accept : .rejectUnexpected
        }
        guard requestPending else { return .rejectUnexpected }
        activeResponseID = responseID
        return .accept
    }

    mutating func stopActiveResponse() -> String? {
        let responseID = activeResponseID
        if let responseID {
            stoppedResponseIDs.insert(responseID)
        }
        activeResponseID = nil
        requestPending = false
        return responseID
    }

    mutating func observeResponseFinished(_ responseID: String?) {
        guard let responseID else { return }
        if activeResponseID == responseID {
            activeResponseID = nil
            requestPending = false
        }
    }

    mutating func reset() {
        requestPending = false
        activeResponseID = nil
        stoppedResponseIDs.removeAll(keepingCapacity: true)
    }
}

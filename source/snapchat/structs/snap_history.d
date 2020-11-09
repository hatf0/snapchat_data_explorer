module snapchat.structs.snap_history;
import asdf;

struct SnapHistory {
    struct RecvSnapEntry {
        @serdeKeys("From") string from;
        @serdeKeys("Media Type") string mediaType;
        @serdeKeys("Created") string date;
    }

    struct SentSnapEntry {
        @serdeKeys("To") string to;
        @serdeKeys("Media Type") string mediaType;
        @serdeKeys("Created") string date;
    }

    @serdeKeys("Received Snap History") RecvSnapEntry[] received;
    @serdeKeys("Sent Snap History") SentSnapEntry[] sent;
}


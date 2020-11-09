module snapchat.structs.chat_history;
import asdf;

struct ChatHistory {
    struct RecvChatEntry {
        @serdeKeys("From") string from;
        @serdeKeys("Media Type") string mediaType;
        @serdeKeys("Created") string date;
    }

    struct SentChatEntry {
        @serdeKeys("To") string to;
        @serdeKeys("Media Type") string mediaType;
        @serdeKeys("Created") string date;
    }

    @serdeKeys("Received Chat History") RecvChatEntry[] received;
    @serdeKeys("Sent Chat History") SentChatEntry[] sent;
}

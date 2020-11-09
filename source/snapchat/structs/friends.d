module snapchat.structs.friends;
import asdf;

struct Friends {
    struct FriendEntry {
        @serdeKeys("Username") string username;
        @serdeKeys("Display Name") string displayName;
    }
    @serdeKeys("Friends") FriendEntry[] friends;
    @serdeKeys("Friend Requests Sent") FriendEntry[] friend_reqs;
    @serdeKeys("Blocked Users") FriendEntry[] blocked;
    @serdeKeys("Deleted Friends") FriendEntry[] deleted;
}



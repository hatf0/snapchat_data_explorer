module snapchat;
import snapchat.structs;
import std.stdio;
import command.uda;
import std.zip;
import std.array : array;
import std.algorithm;

/* 
   Look, this class has code-reuse *all* over.
   I'm honestly too lazy to fix it, this was a quick hack for a school assignment. 
 */
class SnapchatExplorer {
    private {
        ZipArchive archive;
        Friends friends;
        ChatHistory chat;
        SnapHistory snap;
    }

    string expandAndStripUTF(string dir) {
        if (archive is null) return "";
        if (dir in archive.directory) {
            import std.conv : text;
            import std.ascii : isASCII;
            archive.expand(archive.directory[dir]);
            auto file = cast(char[])archive.directory[dir].expandedData();
            return file.filter!(a => isASCII(a)).array().text();
        }
        throw new Exception("Could not find file " ~ dir);
    }

    string displayNameFromUsername(string name) {
        foreach(friend; this.friends.friends) {
            if (friend.username == name) {
                return friend.displayName;
            }
        }
        throw new Exception("Could not find user");
    }

    int[string][2] generateHistory(string name, bool chat) {
        int[string] rxCounter;
        int[string] txCounter;
        rxCounter["VIDEO"] = 0;
        rxCounter["TEXT"] = 0;
        rxCounter["UNKNOWN"] = 0;
        txCounter["VIDEO"] = 0;
        txCounter["TEXT"] = 0;
        txCounter["UNKNOWN"] = 0;

        if (name != "all") {
            if (chat) {
                this.chat.received.filter!((a) => a.from == name).each!((a) { 
                        if (a.mediaType == "VIDEO") rxCounter["VIDEO"]++; 
                        else if (a.mediaType == "TEXT") rxCounter["TEXT"]++;
                        else rxCounter["UNKNOWN"]++;
                });
                this.chat.sent.filter!((a) => a.to == name).each!((a) { 
                    if (a.mediaType == "VIDEO") txCounter["VIDEO"]++; 
                    else if (a.mediaType == "TEXT") txCounter["TEXT"]++;
                    else txCounter["UNKNOWN"]++;
                });
            } else {
                this.snap.received.filter!((a) => a.from == name).each!((a) { 
                        if (a.mediaType == "VIDEO") rxCounter["VIDEO"]++; 
                        else if (a.mediaType == "TEXT") rxCounter["TEXT"]++;
                        else rxCounter["UNKNOWN"]++;
                });
                this.snap.sent.filter!((a) => a.to == name).each!((a) { 
                    if (a.mediaType == "VIDEO") txCounter["VIDEO"]++; 
                    else if (a.mediaType == "TEXT") txCounter["TEXT"]++;
                    else txCounter["UNKNOWN"]++;
                });

            }
        } else {
            if (chat) {
                this.chat.received.each!((a) {
                    if (a.mediaType == "VIDEO") rxCounter["VIDEO"]++; 
                    else if (a.mediaType == "TEXT") rxCounter["TEXT"]++;
                    else rxCounter["UNKNOWN"]++;
                });
                this.chat.sent.each!((a) { 
                    if (a.mediaType == "VIDEO") txCounter["VIDEO"]++; 
                    else if (a.mediaType == "TEXT") txCounter["TEXT"]++;
                    else txCounter["UNKNOWN"]++;
                });
            } else {
                this.snap.received.each!((a) {
                    if (a.mediaType == "VIDEO") rxCounter["VIDEO"]++; 
                    else if (a.mediaType == "TEXT") rxCounter["TEXT"]++;
                    else rxCounter["UNKNOWN"]++;
                });
                this.snap.sent.each!((a) { 
                    if (a.mediaType == "VIDEO") txCounter["VIDEO"]++; 
                    else if (a.mediaType == "TEXT") txCounter["TEXT"]++;
                    else txCounter["UNKNOWN"]++;
                });
            }


            // lol, recursion

            int[string] interactionTable;
            writeln("Friends:");
            foreach(friend; this.friends.friends) {
                if (friend.username == "all") continue;
                auto b = generateHistory(friend.username, chat);
                int totalRx = b[0]["VIDEO"] + b[0]["TEXT"] + b[0]["UNKNOWN"];
                int totalTx = b[1]["VIDEO"] + b[1]["TEXT"] + b[1]["UNKNOWN"];
                if (totalRx + totalTx == 0) continue;
                writefln("\t%s (%s): rx: %d, tx: %d, total: %d", friend.username, friend.displayName, totalRx, totalTx, totalRx + totalTx);
            }
        }


        return [rxCounter, txCounter];
    }

@CommandNamespace("snapchat"):
    @Command("load", "Load a .zip file containing your account's data into the engine.", 1, 1)
    string load(string[] args) {
        string zip = args[0];
        import asdf;
        import std.file : read;
        this.archive = new ZipArchive(read(zip));
        this.snap = expandAndStripUTF("json/snap_history.json").deserialize!SnapHistory();
        this.chat = expandAndStripUTF("json/chat_history.json").deserialize!ChatHistory();
        this.friends = expandAndStripUTF("json/friends.json").deserialize!Friends();
        return "";
    }

    @Command("close", "Close the currently opened zip file")
    string close(string[] args) {
        if (archive !is null) {
            destroy(archive);
            archive = null;
        }
        return "";
    }

    @Command("is_open", "Is the zip file currently opened?")
    string status(string[] args) {
        if (archive !is null) {
            return "true";
        } else {
            return "false";
        }
    }

    @Command("get_display_name", "Get display name from a username", 1, 1)
    string getDisplayName(string[] args) {
        return displayNameFromUsername(args[0]);
    }

    @Command("rename_friend", "Rename the display name given to a username", 2, 2)
    string renameFriend(string[] args) {
        auto old = args[0];
        auto new_ = args[1];
        foreach(i, friend; this.friends.friends) {
            if (friend.username == old) {
                // found
                friend.displayName = new_;
                this.friends.friends[i] = friend;
                return "true";
            }
        }
        throw new Exception("Could not find friend " ~ old);
    }

    @Command("get_chat_count", "Get number of times that you've chatted with someone", 1, 1)
    string getChatCount(string[] args) {
        import std.conv : to;

        auto _tables = generateHistory(args[0], true);  
        auto rxCounter = _tables[0];
        auto txCounter = _tables[1];

        int totalRx = rxCounter["VIDEO"] + rxCounter["TEXT"] + rxCounter["UNKNOWN"];
        int totalTx = txCounter["VIDEO"] + txCounter["TEXT"] + txCounter["UNKNOWN"];
        writeln("Total interactions: ", totalRx + totalTx);
        writeln("\tReceived (", totalRx, "): ");
        writeln("\t\tVideo: ", rxCounter["VIDEO"]);
        writeln("\t\tText: ", rxCounter["TEXT"]);
        writeln("\t\tUnknown: ", rxCounter["UNKNOWN"]);
        writeln("\tSent (", totalTx, "): ");
        writeln("\t\tVideo: ", txCounter["VIDEO"]);
        writeln("\t\tText: ", txCounter["TEXT"]);
        writeln("\t\tUnknown: ", txCounter["UNKNOWN"]);
        return to!string(totalRx + totalTx);
    }

    @Command("get_snap_count", "Get number of times that you've snapped with someone", 1, 1) 
    string getSnapCount(string[] args) {
        import std.conv : to;

        auto _tables = generateHistory(args[0], false);  
        auto rxCounter = _tables[0];
        auto txCounter = _tables[1];

        int totalRx = rxCounter["VIDEO"] + rxCounter["TEXT"] + rxCounter["UNKNOWN"];
        int totalTx = txCounter["VIDEO"] + txCounter["TEXT"] + txCounter["UNKNOWN"];
        writeln("Total interactions: ", totalRx + totalTx);
        writeln("\tReceived (", totalRx, "): ");
        writeln("\t\tVideo: ", rxCounter["VIDEO"]);
        writeln("\t\tText: ", rxCounter["TEXT"]);
        writeln("\t\tUnknown: ", rxCounter["UNKNOWN"]);
        writeln("\tSent (", totalTx, "): ");
        writeln("\t\tVideo: ", txCounter["VIDEO"]);
        writeln("\t\tText: ", txCounter["TEXT"]);
        writeln("\t\tUnknown: ", txCounter["UNKNOWN"]);
        return to!string(totalRx + totalTx);
    }

    @Command("export_snap_count", "Export the amount of times you've snapped with someone", 2, 2)
    string exportSnapCount(string[] args) {
        auto user = args[0];
        auto file = args[1];
        import std.file;
        if (exists(file)) throw new Exception("File already exists.");
        import std.format;

        if (user != "all") {
            auto _tables = generateHistory(user, false);
            auto rxCounter = _tables[0];
            auto txCounter = _tables[1];
            int totalRx = rxCounter["VIDEO"] + rxCounter["TEXT"] + rxCounter["UNKNOWN"];
            int totalTx = txCounter["VIDEO"] + txCounter["TEXT"] + txCounter["UNKNOWN"];

            append(file, format!"%s,%s,%s\n"("Me", displayNameFromUsername(user), totalTx));
            append(file, format!"%s,%s,%s\n"(displayNameFromUsername(user), "Me", totalRx));
        } else {
            foreach(friend; this.friends.friends) {
                auto _tables = generateHistory(friend.username, false);
                auto rxCounter = _tables[0];
                auto txCounter = _tables[1];
                int totalRx = rxCounter["VIDEO"] + rxCounter["TEXT"] + rxCounter["UNKNOWN"];
                int totalTx = txCounter["VIDEO"] + txCounter["TEXT"] + txCounter["UNKNOWN"];
                if (totalRx + totalTx == 0) continue;

                append(file, format!"%s,%s,%s\n"("Me", friend.displayName, totalTx));
                append(file, format!"%s,%s,%s\n"(friend.displayName, "Me", totalRx));
            }
        }
        append(file, "\r\n");
        return "";
    }
    @Command("export_chat_count", "Export the amount of times you've snapped with someone", 2, 2)
    string exportChatCount(string[] args) {
        auto user = args[0];
        auto file = args[1];
        import std.file;
        if (exists(file)) throw new Exception("File already exists.");
        import std.format;

        if (user != "all") {
            auto _tables = generateHistory(user, true);
            auto rxCounter = _tables[0];
            auto txCounter = _tables[1];
            int totalRx = rxCounter["VIDEO"] + rxCounter["TEXT"] + rxCounter["UNKNOWN"];
            int totalTx = txCounter["VIDEO"] + txCounter["TEXT"] + txCounter["UNKNOWN"];

            append(file, format!"%s,%s,%s\n"("Me", displayNameFromUsername(user), totalTx));
            append(file, format!"%s,%s,%s\n"(displayNameFromUsername(user), "Me", totalRx));
        } else {
            foreach(friend; this.friends.friends) {
                auto _tables = generateHistory(friend.username, true);
                auto rxCounter = _tables[0];
                auto txCounter = _tables[1];
                int totalRx = rxCounter["VIDEO"] + rxCounter["TEXT"] + rxCounter["UNKNOWN"];
                int totalTx = txCounter["VIDEO"] + txCounter["TEXT"] + txCounter["UNKNOWN"];
                if (totalRx + totalTx == 0) continue;

                append(file, format!"%s,%s,%s\n"("Me", friend.displayName, totalTx));
                append(file, format!"%s,%s,%s\n"(friend.displayName, "Me", totalRx));
            }
        }
        append(file, "\r\n");
        return "";
    }

    @Command("export_count", "Export the amount of times you've snapped / chatted with someone", 2, 2)
    string exportTotalCount(string[] args) {
        auto user = args[0];
        auto file = args[1];
        import std.file;
        if (exists(file)) throw new Exception("File already exists.");
        import std.format;

        if (user != "all") {
            int totalRx = 0, totalTx = 0;
            {
                auto _tables = generateHistory(user, true);
                auto rxCounter = _tables[0];
                auto txCounter = _tables[1];
                totalRx += rxCounter["VIDEO"] + rxCounter["TEXT"] + rxCounter["UNKNOWN"];
                totalTx += txCounter["VIDEO"] + txCounter["TEXT"] + txCounter["UNKNOWN"];
            }
            {
                auto _tables = generateHistory(user, false);
                auto rxCounter = _tables[0];
                auto txCounter = _tables[1];
                totalRx += rxCounter["VIDEO"] + rxCounter["TEXT"] + rxCounter["UNKNOWN"];
                totalTx += txCounter["VIDEO"] + txCounter["TEXT"] + txCounter["UNKNOWN"];
            }


            append(file, format!"%s,%s,%s\n"("Me", displayNameFromUsername(user), totalTx));
            append(file, format!"%s,%s,%s\n"(displayNameFromUsername(user), "Me", totalRx));
        } else {
            foreach(friend; this.friends.friends) {
                int totalRx = 0, totalTx = 0;
                {
                    auto _tables = generateHistory(friend.username, true);
                    auto rxCounter = _tables[0];
                    auto txCounter = _tables[1];
                    totalRx += rxCounter["VIDEO"] + rxCounter["TEXT"] + rxCounter["UNKNOWN"];
                    totalTx += txCounter["VIDEO"] + txCounter["TEXT"] + txCounter["UNKNOWN"];
                }
                {
                    auto _tables = generateHistory(friend.username, false);
                    auto rxCounter = _tables[0];
                    auto txCounter = _tables[1];
                    totalRx += rxCounter["VIDEO"] + rxCounter["TEXT"] + rxCounter["UNKNOWN"];
                    totalTx += txCounter["VIDEO"] + txCounter["TEXT"] + txCounter["UNKNOWN"];
                }
                if (totalRx + totalTx == 0) continue;

                append(file, format!"%s,%s,%s\n"("Me", friend.displayName, totalTx));
                append(file, format!"%s,%s,%s\n"(friend.displayName, "Me", totalRx));
            }
        }
        append(file, "\r\n");
        return "";
    }
}

mixin RegisterModule!SnapchatExplorer;

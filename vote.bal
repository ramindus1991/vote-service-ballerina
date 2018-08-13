import ballerina/http;
import ballerina/log;
import ballerina/io;

service<http:Service> voteService bind { port: 9090 } {

    map<Topic> topics;

    vote(endpoint caller, http:Request req) {
        string topic = req.getQueryParams().topic;
        string voteVal = req.getQueryParams().value;
        Topic t;
        match topics[topic].counts[voteVal] {
            int value => {
                t = topics[topic] ?: {};
                t.counts[voteVal] = value + 1;
            }
            () => log:printError("Error in value");
        }
        http:Response res = new;
        json jsonT = check <json> t;
        res.setPayload( untaint jsonT );
        json topicsJson = check <json>topics;
        broadcast(topicsJson);
        caller->respond(res) but { error e => log:printError("Error sending response", err = e) };
    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/addTopic"
    }
    addTopic(endpoint caller, http:Request req) {
        json topicJson = check req.getJsonPayload();
        Topic topic = check <Topic>topicJson;
        topics[topic.name] = topic;
        http:Response res = new;
        json topicsJson = check <json>topics;
        res.setPayload( untaint topicsJson );
        caller->respond(res) but { error e => log:printError("Error sending response", err = e) };
    }

    getTopics(endpoint caller, http:Request req) {
        http:Response res = new;
        json topicsJson = check <json>topics;
        res.setPayload( untaint topicsJson );
        caller->respond(res) but { error e => log:printError("Error sending response", err = e) };
    }



}

@http:WebSocketServiceConfig {
    path: "/vote/ws",
    subProtocols: ["xml", "json"],
    idleTimeoutInSeconds: 120
}
service<http:WebSocketService> votews bind { port: 8080 } {

    string ping = "ping";
    byte[] pingData = ping.toByteArray("UTF-8");

    onOpen(endpoint caller) {
        io:println( caller.id + " connected");
        connectionsMap[caller.id] = caller;
    }

    onText(endpoint caller, string text, boolean final) {

    }
    onIdleTimeout(endpoint caller) {
        io:println("\nReached idle timeout");
        io:println("Closing connection " + caller.id);
        caller->close(100000, "Connection timeout") but {
            error e => log:printError(
                           "Error occured when closing the connection", err = e)
        };
    }

    onError(endpoint caller, error err) {
        io:println("Error occurred: " + err.message);
    }

    onClose(endpoint caller, int statusCode, string reason) {
        io:println(string `Client left with {{statusCode}} because {{reason}}`);
    }
}


function broadcast(json text) {
    endpoint http:WebSocketListener ep;
    foreach id, con in connectionsMap {
        ep = con;
        ep->pushText(text) but {
            error e => log:printError("Error sending message", err = e)
        };
    }
}

map<http:WebSocketListener> connectionsMap;

type Topic record {
    string name,
    map<int> counts;
    !...
};
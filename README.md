# vote-service-ballerina

vote-service is a sample webapp developed during ballerina day 2018

Service allows you to create a voting topic

url : localhost:9090/voteService/addTopic
request type : POST
body :
{
	"name" : "Who will win the cricket world cup 2020?",
	"counts" : {
		"Sri Lanka" : 0,
		"India" : 0,
		"Pakistan" : 0
	}
}

You can get current topics and vote counts

url : localhost:9090/voteService/getTopics
request type : GET

Then you can vote

url : localhost:9090/voteService/vote?topic={topicName}&value={choiceName}
request type : GET
example request : localhost:9090/voteService/vote?topic=Who will win the cricket world cup 2020?&value=Sri Lanka

Someone can listen to the web socket which broadcast the topic details and vote counts

web socket : localhost:9090/vote/ws

When someone votes web socket will update listners

index.html is a simple listner which display a json output of topics and votes with web socket updates

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

//Things we will cover in this smart contract
//1. Create a tweet
//2. Send private messages
//3. Follow other people
//4. Get Lists fo tweets
//5. Implement and API, that is grant access to a third party to connect to his tweeter account and tweets

contract Twitter {
    // we need a struct that we can use to define/create a tweet
    struct Tweet {
        uint id;
        address author;
        string content;
        uint createdAt;
    }

    //Create a struct use for creating messages that can be send to privately
    struct Message {
        uint id;
        string content;
        address from;
        address to;
        uint createdAt;
    }

    //We need a container to hold all the tweets
    mapping(uint => Tweet) private tweets;
    //Create a container to contain all the tweets of a particular user
    mapping(address => uint[]) private tweetsOf;
    //mapping to an array of messages since we will have more than one message but a discussion
    mapping(uint => Message[]) private conversations;
    //we create a mapping to hold the following, e.g address a is following addresses[b,c,...]
    mapping(address => address[]) private following;
    //the second mapping tells if the address of the thirds party is authorized or not
    mapping(address => mapping(address => bool)) private operators;
    //Id for the next tweet
    uint private nextTweetId;
    uint private nextMessageId;


    //Using events and indexing the author, so that we can filter by the author when we are listening to the event
    //We can use this in the place of tweetsOf, hence we don't need the function getLatestTweets, hence saving on gas
    event TweetSent (
        uint id,
        address indexed author,
        string content,
        uint createdAt
    );

    event MessageSent (
        uint id,
        string content,
        address indexed from,
        address indexed to,
        uint createdAt
    );

    //We create a function to create a tweet
    function tweet(string calldata _content) external {
        _tweet(msg.sender, _content);
    }

    function tweetFrom(address _from, string calldata _content) external canOperate(_from){
        _tweet(_from, _content);
    }

    function sendMessage(string calldata _content, address _to) external {
        _sendMessage(_content, msg.sender, _to);
    }

    function sendMessageFrom(string calldata _content, address _from, address _to) external canOperate(_from){
        _sendMessage(_content, _from, _to);
    }

    function follow(address _followed) external {
        _follow(msg.sender, _followed);
    }

    function followFrom(address _from, address _followed) external canOperate(_from) {
        _follow(_from, _followed);
    }

    function getLatestTweets() view external returns(Tweet[] memory){
        //Since we are returning an array we need to create an empty array to contruct the array
        //The size of the array is determined by the id
        Tweet[] memory _tweets = new Tweet[](nextTweetId);
        for(uint i = 0; i < nextTweetId; i++) {
            Tweet storage __tweet = tweets[i];
            _tweets[i] = Tweet(
                __tweet.id,
                __tweet.author,
                __tweet.content,
                __tweet.createdAt
            );
        }
        return _tweets;
    }

    //We can use this to do pagination, we get the numner of tweets we want to show
    function getLatestTweetsByCount(uint count) view external returns(Tweet[] memory){
        require(count > 0 && count <= nextTweetId, "Too few or too many tweets to get");
        Tweet[] memory _tweets = new Tweet[](nextTweetId);
        for(uint i = nextTweetId-count; i < nextTweetId; i++) {
            Tweet storage __tweet = tweets[i];
            _tweets[i] = Tweet(
                __tweet.id,
                __tweet.author,
                __tweet.content,
                __tweet.createdAt
            );
        }
        return _tweets;
    }

    function TweetsOf(address _user) view external returns(Tweet[] memory) {
        uint[] storage tweetIds = tweetsOf[_user];
        Tweet[] memory _tweets = new Tweet[](tweetIds.length);
        for(uint i = 0; i < tweetIds.length; i++) {
            Tweet storage __tweet = tweets[tweetIds[i]];
            _tweets[i] = Tweet(
                __tweet.id,
                __tweet.author,
                __tweet.content,
                __tweet.createdAt
            );
        }
        return _tweets;
    }

    function TweetsOfBYCount(address _user, uint count) view external returns(Tweet[] memory) {
        uint[] storage tweetIds = tweetsOf[_user];
        require(count > 0 && count <= tweetIds.length, "Too few or too many tweets to get");
        Tweet[] memory _tweets = new Tweet[](count);
        for(uint i = tweetIds.length - count; i < tweetIds.length; i++) {
            Tweet storage __tweet = tweets[tweetIds[i]];
            _tweets[i] = Tweet(
                __tweet.id,
                __tweet.author,
                __tweet.content,
                __tweet.createdAt
            );
        }
        return _tweets;
    }

    function approveThirdPartyAddresses(address[] calldata _addresses) external {
        for(uint i = 0; i < _addresses.length; i++){
            operators[msg.sender][_addresses[i]] = true;
        }
    }

    function disapproveThirdPartyAddress(address _address) external {
        operators[msg.sender][_address] = false;
    }

    function _tweet(address _from, string memory _content) internal {
        tweets[nextTweetId] = Tweet(
            nextTweetId,
            _from,
            _content,
            block.timestamp
        );
        tweetsOf[_from].push(nextTweetId);
        emit TweetSent(nextTweetId, _from, _content, block.timestamp);
        nextTweetId++;
    }

    function _sendMessage(string memory _content, address _from, address _to) internal {
        //Create a converstionId from the additiong of from and to addresses
        uint conversationId = uint(uint160(_from)) + uint(uint160(_to));
        conversations[conversationId].push(Message(
            nextMessageId,
            _content,
            _from,
            _to,
            block.timestamp
        ));
        emit MessageSent(nextMessageId, _content, _from, _to, block.timestamp);
        nextMessageId++;
    } 

    function _follow(address _from, address _followed) internal {
        following[_from].push(_followed);
    }

    modifier canOperate(address _from) {
        require(operators[msg.sender][_from], "You are not an approved operator");
        _;
    }
}
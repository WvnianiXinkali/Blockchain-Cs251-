// =============================================================================
//                                  Config
// =============================================================================
const provider = new ethers.providers.JsonRpcProvider("http://localhost:8545");
var defaultAccount;

// Constant we use later
var GENESIS = '0x0000000000000000000000000000000000000000000000000000000000000000';

// This is the ABI for your contract (get it from Remix, in the 'Compile' tab)
// ============================================================
var abi = [{"type":"function","name":"addIOU","inputs":[{"name":"creditor","type":"address","internalType":"address"},{"name":"amount","type":"uint32","internalType":"uint32"},{"name":"path","type":"address[]","internalType":"address[]"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"ious","inputs":[{"name":"","type":"address","internalType":"address"},{"name":"","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"uint32","internalType":"uint32"}],"stateMutability":"view"},{"type":"function","name":"lookup","inputs":[{"name":"debtor","type":"address","internalType":"address"},{"name":"creditor","type":"address","internalType":"address"}],"outputs":[{"name":"ret","type":"uint32","internalType":"uint32"}],"stateMutability":"view"},{"type":"event","name":"IOU_added","inputs":[{"name":"debtor","type":"address","indexed":true,"internalType":"address"},{"name":"creditor","type":"address","indexed":true,"internalType":"address"},{"name":"amount","type":"uint32","indexed":false,"internalType":"uint32"}],"anonymous":false}]; // FIXME: fill this in with your contract's ABI //Be sure to only have one array, not two
// ============================================================
abiDecoder.addABI(abi);
// call abiDecoder.decodeMethod to use this - see 'getAllFunctionCalls' for more

var contractAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3"; // FIXME: fill this in with your contract's address/hash

var BlockchainSplitwise = new ethers.Contract(contractAddress, abi, provider.getSigner());

//0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 //private key for account 0
//0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

// =============================================================================
//                            Functions To Implement
// =============================================================================

// TODO: Add any helper functions here!

async function getNeighbors(node) {
    const users = await getUsers();
    const neighbors = [];
    for (const user of users) {
        const debt = await BlockchainSplitwise.lookup(node, user);
        if (parseInt(debt) > 0) neighbors.push(user);
    }
    return neighbors;
}

// TODO: Return a list of all users (creditors or debtors) in the system
// All users in the system are everyone who has ever sent or received an IOU
async function getUsers() {
	const calls = await getAllFunctionCalls(contractAddress, "addIOU");
	const users = new Set();
    calls.forEach(c => {
        users.add(c.from);
        users.add(c.args[0].toLowerCase());
    });
    return [...users];
}

// TODO: Get the total amount owed by the user specified by 'user'
async function getTotalOwed(user) {
	const users = await getUsers();
    let total = 0;
    for (const other of users) {
        const debt = await BlockchainSplitwise.lookup(user, other);
        total += parseInt(debt);
    }
    return total;
}

// TODO: Get the last time this user has sent or received an IOU, in seconds since Jan. 1, 1970
// Return null if you can't find any activity for the user.
// HINT: Try looking at the way 'getAllFunctionCalls' is written. You can modify it if you'd like.
async function getLastActive(user) {
	const calls = await getAllFunctionCalls(contractAddress, "addIOU");
	let latest = null;
    calls.forEach(c => {
        if (c.from === user.toLowerCase() || c.args[0].toLowerCase() === user.toLowerCase()) {
            if (latest === null || c.t > latest) latest = c.t;
        }
    });
    return latest;
}

// TODO: add an IOU ('I owe you') to the system
// The person you owe money is passed as 'creditor'
// The amount you owe them is passed as 'amount'
async function add_IOU(creditor, amount) {
	const signer = provider.getSigner(defaultAccount);
    creditor = creditor.toLowerCase();

    const path = await doBFS(creditor, defaultAccount, getNeighbors);
	let tx;
    if (path !== null) {
        tx = await BlockchainSplitwise.connect(signer).addIOU(creditor, amount, path);
    } else {
        tx = await BlockchainSplitwise.connect(signer).addIOU(creditor, amount, []);
    }
	await tx.wait();
}

// =============================================================================
//                              Provided Functions
// =============================================================================
// Reading and understanding these should help you implement the above

// This searches the block history for all calls to 'functionName' (string) on the 'addressOfContract' (string) contract
// It returns an array of objects, one for each call, containing the sender ('from'), arguments ('args'), and the timestamp ('t')
async function getAllFunctionCalls(addressOfContract, functionName) {
	var curBlock = await provider.getBlockNumber();
	var function_calls = [];

	while (curBlock !== GENESIS) {
	  var b = await provider.getBlockWithTransactions(curBlock);
	  var txns = b.transactions;
	  for (var j = 0; j < txns.length; j++) {
	  	var txn = txns[j];

	  	// check that destination of txn is our contract
			if(txn.to == null){continue;}
	  	if (txn.to.toLowerCase() === addressOfContract.toLowerCase()) {
	  		var func_call = abiDecoder.decodeMethod(txn.data);

				// check that the function getting called in this txn is 'functionName'
				if (func_call && func_call.name === functionName) {
					var timeBlock = await provider.getBlock(curBlock);
		  		var args = func_call.params.map(function (x) {return x.value});
	  			function_calls.push({
	  				from: txn.from.toLowerCase(),
	  				args: args,
						t: timeBlock.timestamp
	  			})
	  		}
	  	}
	  }
	  curBlock = b.parentHash;
	}
	return function_calls;
}

// We've provided a breadth-first search implementation for you, if that's useful
// It will find a path from start to end (or return null if none exists)
// You just need to pass in a function ('getNeighbors') that takes a node (string) and returns its neighbors (as an array)
async function doBFS(start, end, getNeighbors) {
	var queue = [[start]];
	while (queue.length > 0) {
		var cur = queue.shift();
		var lastNode = cur[cur.length-1]
		if (lastNode.toLowerCase() === end.toString().toLowerCase()) {
			return cur;
		} else {
			var neighbors = await getNeighbors(lastNode);
			for (var i = 0; i < neighbors.length; i++) {
				queue.push(cur.concat([neighbors[i]]));
			}
		}
	}
	return null;
}

// =============================================================================
//                                      UI
// =============================================================================

// This sets the default account on load and displays the total owed to that
// account.
provider.listAccounts().then((response)=> {
	defaultAccount = response[0];

	getTotalOwed(defaultAccount).then((response)=>{
		$("#total_owed").html("$"+response);
	});

	getLastActive(defaultAccount).then((response)=>{
		time = timeConverter(response)
		$("#last_active").html(time)
	});
});

// This code updates the 'My Account' UI with the results of your functions
$("#myaccount").change(function() {
	defaultAccount = $(this).val();

	getTotalOwed(defaultAccount).then((response)=>{
		$("#total_owed").html("$"+response);
	})

	getLastActive(defaultAccount).then((response)=>{
		time = timeConverter(response)
		$("#last_active").html(time)
	});
});

// Allows switching between accounts in 'My Account' and the 'fast-copy' in 'Address of person you owe
provider.listAccounts().then((response)=>{
	var opts = response.map(function (a) { return '<option value="'+
			a.toLowerCase()+'">'+a.toLowerCase()+'</option>' });
	$(".account").html(opts);
	$(".wallet_addresses").html(response.map(function (a) { return '<li>'+a.toLowerCase()+'</li>' }));
});

// This code updates the 'Users' list in the UI with the results of your function
getUsers().then((response)=>{
	$("#all_users").html(response.map(function (u,i) { return "<li>"+u+"</li>" }));
});

// This runs the 'add_IOU' function when you click the button
// It passes the values from the two inputs above
$("#addiou").click(function() {
	defaultAccount = $("#myaccount").val(); //sets the default account
  add_IOU($("#creditor").val(), $("#amount").val()).then((response)=>{
		window.location.reload(false); // refreshes the page after add_IOU returns and the promise is unwrapped
	})
});

// This is a log function, provided if you want to display things to the page instead of the JavaScript console
// Pass in a discription of what you're printing, and then the object to print
function log(description, obj) {
	$("#log").html($("#log").html() + description + ": " + JSON.stringify(obj, null, 2) + "\n\n");
}


// =============================================================================
//                                      TESTING
// =============================================================================

// This section contains a sanity check test that you can use to ensure your code
// works. We will be testing your code this way, so make sure you at least pass
// the given test. You are encouraged to write more tests!

// Remember: the tests will assume that each of the four client functions are
// async functions and thus will return a promise. Make sure you understand what this means.

function check(name, condition) {
	if (condition) {
		console.log(name + ": SUCCESS");
		return 3;
	} else {
		console.log(name + ": FAILED");
		return 0;
	}
}

async function sanityCheck() {
	console.log ("\nTEST", "Simplest possible test: only runs one add_IOU; uses all client functions: lookup, getTotalOwed, getUsers, getLastActive");

	var score = 0;

	var accounts = await provider.listAccounts();
	defaultAccount = accounts[0];

	var users = await getUsers();
	score += check("getUsers() initially empty", users.length === 0);

	var owed = await getTotalOwed(accounts[1]);
	score += check("getTotalOwed(0) initially empty", owed === 0);

	var lookup_0_1 = await BlockchainSplitwise.lookup(accounts[0], accounts[1]);
	console.log("lookup(0, 1) current value" + lookup_0_1);
	score += check("lookup(0,1) initially 0", parseInt(lookup_0_1, 10) === 0);

	var response = await add_IOU(accounts[1], "10");

	users = await getUsers();
	score += check("getUsers() now length 2", users.length === 2);

	owed = await getTotalOwed(accounts[0]);
	score += check("getTotalOwed(0) now 10", owed === 10);

	lookup_0_1 = await BlockchainSplitwise.lookup(accounts[0], accounts[1]);
	score += check("lookup(0,1) now 10", parseInt(lookup_0_1, 10) === 10);

	var timeLastActive = await getLastActive(accounts[0]);
	var timeNow = Date.now()/1000;
	var difference = timeNow - timeLastActive;
	score += check("getLastActive(0) works", difference <= 60 && difference >= -3); // -3 to 60 seconds

	console.log("Final Score: " + score +"/21");
}

 //sanityCheck() //Uncomment this line to run the sanity check when you first open index.html

// Available Accounts
// ==================

// (0) 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 (10000.000000000000000000 ETH)
// (1) 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 (10000.000000000000000000 ETH)
// (2) 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC (10000.000000000000000000 ETH)
// (3) 0x90F79bf6EB2c4f870365E785982E1f101E93b906 (10000.000000000000000000 ETH)
// (4) 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65 (10000.000000000000000000 ETH)
// (5) 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc (10000.000000000000000000 ETH)
// (6) 0x976EA74026E726554dB657fA54763abd0C3a0aa9 (10000.000000000000000000 ETH)
// (7) 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955 (10000.000000000000000000 ETH)
// (8) 0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f (10000.000000000000000000 ETH)
// (9) 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720 (10000.000000000000000000 ETH)

// Private Keys
// ==================

// (0) 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
// (1) 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
// (2) 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
// (3) 0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6
// (4) 0x57e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926B
// (5) 0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba
// (6) 0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e
// (7) 0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356
// (8) 0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97
// (9) 0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6


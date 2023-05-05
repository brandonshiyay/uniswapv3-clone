from init import *
from eth_defi import revert_reason
import math


# p_sqrt = sqrt(x/y)
# y --> USDC (token0) | x --> ETH (token1)
def get_sqrt_p(token0, token1):
    return math.sqrt(token0 / token1)


# sqrt(p(i)) = 1.0001^(i/2)
def calc_tick(p):
    return math.floor(math.log(p, 1.0001))


# price * 2^96
def price_to_sqrt_p(price):
    return int(math.sqrt(price) * pow(2, 96))


def calculate_liqudity(token0, token1, price_a, price_c, price_b):
    l_x = (token1 * price_b * price_c) / (abs(price_b - price_c) * pow(2, 96))
    l_y = (token0 * pow(2, 96)) / abs(price_c - price_a)
    return int(min(l_x, l_y))


def calculate_amounts(liquidity, p_a, p_c, p_b):
    amount_x = (liquidity * abs(p_b - p_c) * pow(2, 96)) / (p_b * p_c)
    amount_y = (liquidity * abs(p_c - p_a)) / (pow(2, 96))
    return (int(amount_x), int(amount_y))


def getBalance(account):
	balance = w3.eth.get_balance(account.address)
	return weiToEther(balance)


def weiToEther(amount):
	return amount / (10 ** 18)


def quote(amount, zero_for_one, price_limit):
	try:
		result = quoter.functions.quote((
			pool.address, 
			int(amount * (10 ** 18)), 
			zero_for_one, 
			price_to_sqrt_p(price_limit))
		).call()

		return result

	except Exception as e:
		# revert_reason = decode_revert_reason(e.revert_data)
		print(f'Revert! Reason: {e}')


def EtherToWei(wei):
	return int(wei * (10 ** 18))



def getLiquidity():
	result = pool.functions.liquidity().call()
	return result


def addLiquidity(loPrice, hiPrice, amount0, amount1):
	loTick = calc_tick(loPrice)
	hiTick = calc_tick(hiPrice)

	args = (
		pool.address,
		loTick,
		hiTick,
		EtherToWei(amount0), 
		EtherToWei(amount1),
		0,
		0)

	gas_estimate = manager.functions.mint(args).estimateGas({'from': account.address})

	data = manager.functions.mint(args).buildTransaction({'gas': gas_estimate})['data']

	sendFunctionCallTX(account, pool.address, data, gas_estimate)


def sendFunctionCallTX(sender, recipient, data, gas):
	transaction = {
	    'to': recipient,
	    'value': 0,
	    'gas': gas,
	    'gasPrice': w3.eth.gasPrice,
	    'nonce': w3.eth.getTransactionCount(sender.address),
	    'data': data
	}

	signed_transaction = sender.signTransaction(transaction)
	transaction_hash = w3.eth.sendRawTransaction(signed_transaction.rawTransaction)
	transaction_receipt = w3.eth.waitForTransactionReceipt(transaction_hash)

	print(f"[DEBUG] Send Transaction {hex(int.from_bytes(transaction_hash, 'big'))}, from: {sender.address} to: {recipient}")

	if transaction_receipt['status'] == 1:
		events = number_set_event.processReceipt(transaction_receipt)

		for event in events:
		    print("Event args:", event['args'])

	else:
		reason = revert_reason.fetch_transaction_revert_reason(w3, transaction_hash)
		print(f"[DEBUG] Transaction reverted, reason: {reason}")

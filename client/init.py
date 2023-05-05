from web3 import Web3, Account
import json


w3 = Web3(Web3.HTTPProvider('http://127.0.0.1:8545'))

PRIVATE_KEY = "0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6"

ERC20_ABI = json.load(open('abi/ERC20.json', 'r'))
POOL_ABI = json.load(open('abi/Pool.json', 'r'))
MANAGER_ABI = json.load(open('abi/Manager.json', 'r'))
QUOTER_ABI = json.load(open('abi/Quoter.json', 'r'))

WETH_ADDRESS = "0x0E4B6314D9756D40EE0b3D68cF3999D29eEFb147"
USDC_ADDRESS = "0x3C4249f1cDf4C5Ee12D480a543a6A42362baAAFf"
POOL_ADDRESS = "0x3Be63776630ac9f282109352C804E650d515C604"
MANAGER_ADDRESS = "0x43992F5f575c28A1dE03b1F337974b94e44FAb8c"
QUOTER_ADDRESS = "0x5f474bC674b6Ad4d7b6A5c6429d586D53053DA33"

weth = w3.eth.contract(address=WETH_ADDRESS, abi=ERC20_ABI)
usdc = w3.eth.contract(address=USDC_ADDRESS, abi=ERC20_ABI)
pool = w3.eth.contract(address=POOL_ADDRESS, abi=POOL_ABI)
manager = w3.eth.contract(address=MANAGER_ADDRESS, abi=MANAGER_ABI)
quoter = w3.eth.contract(address=QUOTER_ADDRESS, abi=QUOTER_ABI)

account = Account.from_key(PRIVATE_KEY)
w3.eth.defaultAccount = account.address

print(f"Set default account to {account.address}")


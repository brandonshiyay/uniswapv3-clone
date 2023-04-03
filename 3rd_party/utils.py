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

eth = 10 ** 18
amount_eth = 1 * eth
amount_usdc = 5000 * eth

p_a = price_to_sqrt_p(4545)
p_c = price_to_sqrt_p(5000)
p_b = price_to_sqrt_p(5500)

liquidity = calculate_liqudity(amount_usdc, amount_eth, p_a, p_c, p_b)
print(liquidity)

amount_x, amount_y = calculate_amounts(liquidity, p_a, p_c, p_b)
print(amount_x, amount_y)


tick_lo = calc_tick(4545)
tick_hi = calc_tick(5500)

print(tick_lo, tick_hi)
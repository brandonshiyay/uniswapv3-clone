def MSB(x):
    r = 0
    if (x >= 0x100000000000000000000000000000000):
        x >>= 128
        r += 128

    if (x >= 0x10000000000000000):
        x >>= 64
        r += 64

    if (x >= 0x100000000):
        x >>= 32
        r += 32

    if (x >= 0x10000):
        x >>= 16
        r += 16

    if (x >= 0x100):
        x >>= 8
        r += 8
    
    if (x >= 0x10):
        x >>= 4
        r += 4
    
    if (x >= 0x4):
        x >>= 2
        r += 2
    
    if (x >= 0x2): r += 1

    return r 


print(MSB(1425))
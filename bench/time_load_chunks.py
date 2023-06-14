import contextlib
import itertools
import time
import zlib
import concatenated_zlib._zlib as z
import concatenated_zlib._zlibng as zng

c0 = open("./chunk_0000.dat", "rb").read()
c1 = open("./chunk_0001.dat", "rb").read()

d0 = zlib.decompress(c0)
d1 = zlib.decompress(c1)

assert d0 == z.zlib_decode(c0)
assert d1 == z.zlib_decode(c1)
assert (d0 + d1) == z.zlib_decode(c0 + c1)

assert d0 == zng.zlibng_decode(c0)
assert d1 == zng.zlibng_decode(c1)
assert (d0 + d1) == zng.zlibng_decode(c0 + c1)

print(d0 + d1 == z.zlib_decode(c0 + c1))
print(d0 + d1 == zng.zlibng_decode(c0 + c1))

@contextlib.contextmanager
def timeit(label, div=1):
    t0 = time.monotonic()
    try:
        yield
    finally:
        print(label, "took", (time.monotonic() - t0) / div, "seconds")

with timeit("overhead", 1000):
    for _ in range(1000):
        x = b"".join(itertools.islice(itertools.cycle([c0, c1]), 1000))
        print(len(x))

with timeit("stdlib.zlib", 1000):
    for _ in range(1000):
        _data0 = b"".join(
            zlib.decompress(c)
            for c in itertools.islice(itertools.cycle([c0, c1]), 1000)
        )

with timeit("concatenated_zlib._zlib", 1000):
    for _ in range(1000):
        _data1 = z.zlib_decode(b"".join(itertools.islice(itertools.cycle([c0, c1]), 1000)))

with timeit("concatenated_zlib._zlibng", 1000):
    for _ in range(1000):
        _data2 = zng.zlibng_decode(b"".join(itertools.islice(itertools.cycle([c0, c1]), 1000)))

# with timeit("onecall"):
#    z.zlib_decode(b"".join(itertools.islice(itertools.cycle([c0, c1]), 256000)))

assert _data0 == _data1 == _data2

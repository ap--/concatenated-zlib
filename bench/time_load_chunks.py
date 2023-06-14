import contextlib
import itertools
import time
import zlib
from concatenated_zlib import zlib_concat_decode
from concatenated_zlib import zlibng_concat_decode

c0 = open("./chunk_0000.dat", "rb").read()
c1 = open("./chunk_0001.dat", "rb").read()

d0 = zlib.decompress(c0)
d1 = zlib.decompress(c1)

assert d0 == zlib_concat_decode(c0)
assert d1 == zlib_concat_decode(c1)
assert (d0 + d1) == zlib_concat_decode(c0 + c1)

assert d0 == zlibng_concat_decode(c0)
assert d1 == zlibng_concat_decode(c1)
assert (d0 + d1) == zlibng_concat_decode(c0 + c1)

print(d0 + d1 == zlib_concat_decode(c0 + c1))
print(d0 + d1 == zlibng_concat_decode(c0 + c1))

@contextlib.contextmanager
def timeit(label, div=1):
    t0 = time.monotonic()
    try:
        yield
    finally:
        print(label, "took", (time.monotonic() - t0) / div, "seconds")

with timeit("overhead", div=100):
    for _ in range(100):
        x = b"".join(itertools.islice(itertools.cycle([c0, c1]), 1000))

with timeit("stdlib.zlib", div=100):
    for _ in range(100):
        _data0 = b"".join(
            zlib.decompress(c)
            for c in itertools.islice(itertools.cycle([c0, c1]), 1000)
        )

with timeit("zlib_concat_decode", div=100):
    for _ in range(100):
        _data1 = zlib_concat_decode(b"".join(itertools.islice(itertools.cycle([c0, c1]), 1000)))

with timeit("zlibng_concat_decode", div=100):
    for _ in range(100):
        _data2 = zlibng_concat_decode(b"".join(itertools.islice(itertools.cycle([c0, c1]), 1000)))

# with timeit("onecall"):
#    z.zlib_decode(b"".join(itertools.islice(itertools.cycle([c0, c1]), 256000)))

assert _data0 == _data1 == _data2

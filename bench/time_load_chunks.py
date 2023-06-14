import contextlib
import itertools
import time
import zlib

import numpy as np

from concatenated_zlib import zlib_concat_decode
from concatenated_zlib import zlibng_concat_decode
from concatenated_zlib import zlib_multi_decompress
from concatenated_zlib._deflate import libdeflate_zlib_decode

def test():

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

    assert d0 == zlib_multi_decompress([c0])
    assert d1 == zlib_multi_decompress([c1])
    assert (d0 + d1) == zlib_multi_decompress([c0, c1])

    print(d0 + d1 == zlib_concat_decode(c0 + c1))
    print(d0 + d1 == zlibng_concat_decode(c0 + c1))
    print(d0 + d1 == zlib_multi_decompress([c0, c1]))

@contextlib.contextmanager
def timeit(label, div=1):
    t0 = time.monotonic()
    try:
        yield
    finally:
        print(label, "took", (time.monotonic() - t0) / div, "seconds")


def bench():

    c0 = open("./chunk_0000.dat", "rb").read()
    c1 = open("./chunk_0001.dat", "rb").read()

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

    with timeit("zlib_multi_decompress", div=10):
        for _ in range(10):
            _data3 = zlib_multi_decompress(itertools.islice(itertools.cycle([c0, c1]), 1000))

    with timeit("libdeflate_zlib_decompress", div=100):
        out = np.empty((1024*12 + 24,), dtype=np.uint8)
        for _ in range(100):
            _data4 = b"".join(
                libdeflate_zlib_decode(c, out)
                for c in itertools.islice(itertools.cycle([c0, c1]), 1000)
            )

    # with timeit("onecall"):
    #    z.zlib_decode(b"".join(itertools.islice(itertools.cycle([c0, c1]), 256000)))

    assert _data0 == _data1 == _data2 == _data3 == _data4


if __name__ == "__main__":
    test()
    bench()
import multiprocessing
import zlib
from typing import Iterable


def zlib_multi_decompress(
    chunks: Iterable[bytes]
) -> bytes:
    decompress = zlib.decompress

    with multiprocessing.Pool() as pool:
        decompressed = pool.map(decompress, chunks)
    return b"".join(decompressed)

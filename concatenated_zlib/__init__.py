from ._zlib import zlib_decode as zlib_concat_decode
from ._zlibng import zlibng_decode as zlibng_concat_decode
from ._stdlib_multi import zlib_multi_decompress

try:
    from ._version import __version__
except ImportError:
    __version__ = "not-installed"

__all__ = [
    "zlib_concat_decode",
    "zlibng_concat_decode",
    "zlib_multi_decompress",
]

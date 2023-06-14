from ._zlib import zlib_decode as zlib_concat_decode
from ._zlibng import zlibng_decode as zlibng_concat_decode

try:
    from ._version import __version__
except ImportError:
    __version__ = "not-installed"

__all__ = [
    "zlib_concat_decode",
    "zlibng_concat_decode",
]

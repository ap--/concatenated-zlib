# concatenated_zlib

this is a playground repository to experiment with an zlib and zlibng
decompressor that can handle zlib compressed concatenated chunks.

The code here is basically copied from the excellent `imagecodecs` package:
https://github.com/cgohlke/imagecodecs/
and modified to support concatenated input.

### description

The below fails to decompress concatenated zlib compressed blocks:
```python
import zlib
c0 = zlib.compress(b"abc")
c1 = zlib.compress(b"efg")

print(zlib.decompress(c0 + c1))  # returns b"abc"
```

This repo provides a zlib and zlibng based decompressor that supports concatenated
input:

```python
import zlib
from concatenated_zlib import zlib_concat_decode
from concatenated_zlib import zlibng_concat_decode
c0 = zlib.compress(b"abc")
c1 = zlib.compress(b"efg")

print(zlib_concat_decode(c0 + c1))  # returns b"abcefg"
print(zlibng_concat_decode(c0 + c1))  # returns b"abcefg"
```

### benchmarks

To reproduce:
```shell
# ON A MAC YOU CAN INSTALL THE DEPENDECIES VIA homebrew
brew install zlib zlib-ng libdeflate
# ^^^ install the corresponding *-dev packages on your OS accordingly

git clone --recursive https://github.com/ap--/concatenated-zlib.git
cd concatenated-zlib/
python3 -m venv venv
source venv/bin/activate
python3 -m pip install .
cd bench; python time_load_chunks.py
```

Run `cd bench; python time_load_chunks.py` to get some crude timing for the different
approaches... Weirdly enough the cython implementation doesn't currently beat
the plain python stdlib decompression of individual chunks. Needs more
investigation...


### related info

- https://stackoverflow.com/a/60208718 decompress concatenated zlib chunks

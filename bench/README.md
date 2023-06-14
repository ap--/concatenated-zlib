This is run on an M2 mac currently...

```
> uname -a
Darwin F2WR4P9QNH 22.5.0 Darwin Kernel Version 22.5.0: Mon Apr 24 20:53:19 PDT 2023; root:xnu-8796.121.2~5/RELEASE_ARM64_T6020 arm64

❯ python time_load_chunks.py
True
True
True
overhead took 0.00032126624981174243 seconds
stdlib.zlib took 0.029090170830022542 seconds
zlib_concat_decode took 0.029393986669892912 seconds
zlibng_concat_decode took 0.028708101249940228 seconds
zlib_multi_decompress took 0.6786801500013098 seconds
libdeflate_zlib_decompress took 0.01889676667022286 seconds

```

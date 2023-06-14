# _deflate.pyx
# distutils: language = c
# cython: language_level = 3
# cython: boundscheck=False
# cython: wraparound=False
# cython: cdivision=True
# cython: nonecheck=False

include '_shared.pxi'

from .deflate cimport *


def libdeflate_zlib_decode(data, out=None):
    """Return decoded zlib data."""
    cdef:
        const uint8_t[::1] src
        const uint8_t[::1] dst  # must be const to write to bytes
        ssize_t dstsize
        size_t srclen, dstlen
        int32_t ret
        size_t actual_out_bytes
        libdeflate_decompressor* decompressor

    if data is out:
        raise ValueError('cannot decode in-place')

    if out is None:
        raise ValueError("OUT CURRENTLY REQUIRED!")  # fixme: ...

    out, dstsize, outgiven, outtype = _parse_output(out)

    if out is None and dstsize < 0:
        # return _zlibng_decode(data, outtype)
        raise NotImplemented("...")

    if out is None:
        if dstsize < 0:
            raise NotImplementedError  # TODO
        out = _create_output(outtype, dstsize)

    src = data
    dst = out
    dstsize = dst.size
    dstlen = <size_t> dstsize
    srclen = <size_t> src.size

    decompressor = libdeflate_alloc_decompressor()
    if decompressor == NULL:
        raise RuntimeError("could not allocate decompressor")

    try:
        with nogil:
            ret = libdeflate_zlib_decompress(
                decompressor,
                <void *> &src[0],
                srclen,
                <void *> &dst[0],
                dstlen,
                &actual_out_bytes,
            )
    finally:
        libdeflate_free_decompressor(decompressor)

    if ret != LIBDEFLATE_SUCCESS:
        msg = {
            LIBDEFLATE_SUCCESS: "success",
            LIBDEFLATE_BAD_DATA: "BAD_DATA",
            LIBDEFLATE_SHORT_OUTPUT: "SHORT_OUTPUT",
            LIBDEFLATE_INSUFFICIENT_SPACE: "INSUFFICIENT_SPACE"
        }
        raise Exception(f'libdeflate_deflate_decompress error: {msg[ret]}')

    del dst
    out_arr = _return_output(out, dstsize, dstlen, outgiven)[:actual_out_bytes]
    return bytes(out_arr)  # fixme: casting to bytes for testing...

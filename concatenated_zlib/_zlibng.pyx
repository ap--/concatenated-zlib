# imagecodecs/_zlibng.pyx
# distutils: language = c
# cython: language_level = 3
# cython: boundscheck=False
# cython: wraparound=False
# cython: cdivision=True
# cython: nonecheck=False

# Copyright (c) 2021-2023, Christoph Gohlke
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

"""Zlib-ng codec for the imagecodecs package."""

__version__ = '2023.3.16'

include '_shared.pxi'

from zlib_ng cimport *

from  libc.math cimport ceil


class ZLIBNG:
    """ZLIBNG codec constants."""

    available = True

    class COMPRESSION(enum.IntEnum):
        """ZLIBNG codec compression levels."""
        DEFAULT = Z_DEFAULT_COMPRESSION
        NO = Z_NO_COMPRESSION
        BEST = Z_BEST_COMPRESSION
        SPEED = Z_BEST_SPEED

    class STRATEGY(enum.IntEnum):
        """ZLIBNG codec compression strategies."""
        DEFAULT = Z_DEFAULT_STRATEGY
        FILTERED = Z_FILTERED
        HUFFMAN_ONLY = Z_HUFFMAN_ONLY
        RLE = Z_RLE
        FIXED = Z_FIXED


class ZlibngError(RuntimeError):
    """ZLIBNG codec exceptions."""

    def __init__(self, func, err):
        msg = {
            Z_OK: 'Z_OK',
            Z_STREAM_END: 'Z_STREAM_END',
            Z_NEED_DICT: 'Z_NEED_DICT',
            Z_ERRNO: 'Z_ERRNO',
            Z_STREAM_ERROR: 'Z_STREAM_ERROR',
            Z_DATA_ERROR: 'Z_DATA_ERROR',
            Z_MEM_ERROR: 'Z_MEM_ERROR',
            Z_BUF_ERROR: 'Z_BUF_ERROR',
            Z_VERSION_ERROR: 'Z_VERSION_ERROR',
        }.get(err, f'unknown error {err!r}')
        msg = f'{func} returned {msg}'
        super().__init__(msg)


def zlibng_version():
    """Return zlibng library version string."""
    return f'zlib_ng {ZLIBNG_VERSION.decode()}'


def zlibng_check(data):
    """Return whether data is DEFLATE encoded."""
    cdef:
        bytes sig = bytes(data[:2])

    # most common ZLIB headers
    if (
        sig == b'\x78\x9C'
        or sig == b'\x78\x5E'
        or sig == b'\x78\x01'
        or sig == b'\x78\xDA'
    ):
        return True
    return None  # maybe


def zlibng_decode(data, out=None):
    """Return decoded DEFLATE data."""
    cdef:
        const uint8_t[::1] src
        const uint8_t[::1] dst  # must be const to write to bytes
        ssize_t dstsize
        size_t srclen, dstlen
        int32_t ret

    if data is out:
        raise ValueError('cannot decode in-place')

    out, dstsize, outgiven, outtype = _parse_output(out)

    if out is None and dstsize < 0:
        return _zlibng_decode(data, outtype)

    if out is None:
        if dstsize < 0:
            raise NotImplementedError  # TODO
        out = _create_output(outtype, dstsize)

    src = data
    dst = out
    dstsize = dst.size
    dstlen = <size_t> dstsize
    srclen = <size_t> src.size

    with nogil:
        ret = zng_uncompress2(
            <uint8_t*> &dst[0],
            &dstlen,
            &src[0],
            &srclen
        )
    if ret != Z_OK:
        raise ZlibngError('zng_uncompress2', ret)

    del dst
    return _return_output(out, dstsize, dstlen, outgiven)


cdef _zlibng_decode(const uint8_t[::1] src, outtype):
    """Decompress using streaming API."""
    cdef:
        output_t* output = NULL
        zng_stream stream
        ssize_t srcsize = src.size
        size_t size, left
        int32_t ret
        ssize_t total_out = 0

    try:
        with nogil:

            stream.next_in = <const uint8_t*> &src[0]
            stream.avail_in = 0
            stream.zalloc = NULL
            stream.zfree = NULL
            stream.opaque = NULL

            ret = zng_inflateInit(&stream)
            if ret != Z_OK:
                raise ZlibngError('zng_inflateInit', ret)

            output = output_new(
                NULL,
                max(4096, (srcsize * 2) + (4096 - srcsize * 2) % 4096)
            )
            if output == NULL:
                raise MemoryError('output_new failed')

            stream.next_out = <uint8_t*> output.data
            stream.avail_out = 0
            left = <size_t> output.size
            size = <size_t> srcsize

            while True:
                while ret == Z_OK or ret == Z_BUF_ERROR:

                    if stream.avail_out == 0:
                        if left == 0:
                            left = output.size * 2
                            if output_resize(output, output.size + left) == 0:
                                raise MemoryError('output_resize failed')
                            stream.next_out = (
                                <uint8_t*> output.data + (output.size - left)
                            )
                        if left > <size_t> 4294967295:
                            stream.avail_out = <uint32_t> 4294967295
                        else:
                            stream.avail_out = <uint32_t> left
                        left -= stream.avail_out

                    if stream.avail_in == 0:
                        if ret == Z_BUF_ERROR:
                            break
                        if size > <size_t> 4294967295:
                            stream.avail_in = <uint32_t> 4294967295
                        else:
                            stream.avail_in = <uint32_t> size
                        size -= stream.avail_in

                    ret = zng_inflate(&stream, Z_NO_FLUSH)

                total_out += stream.total_out

                if ret != Z_STREAM_END:
                    raise ZlibngError('zng_inflate', ret)

                elif stream.avail_in > 0:
                    ret = zng_inflateReset(&stream)
                    if ret != Z_OK:
                        raise ZlibngError("zng_inflateReset", ret)

                else:
                    break

        out = _create_output(
            outtype, total_out, <const char *> output.data
        )

    finally:
        output_del(output)
        ret = zng_inflateEnd(&stream)
        if ret != Z_OK:
            raise ZlibngError('zng_inflateEnd', ret)

    return out


# Output Stream ###############################################################

ctypedef struct output_t:
    uint8_t* data
    size_t size
    size_t pos
    size_t used
    int owner


cdef output_t* output_new(uint8_t* data, size_t size) nogil:
    """Return new output."""
    cdef:
        output_t* output = <output_t*> malloc(sizeof(output_t))

    if output == NULL:
        return NULL
    output.size = size
    output.used = 0
    output.pos = 0
    if data == NULL:
        output.owner = 1
        output.data = <uint8_t*> malloc(size)
    else:
        output.owner = 0
        output.data = data
    if output.data == NULL:
        free(output)
        return NULL
    return output


cdef void output_del(output_t* output) nogil:
    """Free output."""
    if output != NULL:
        if output.owner != 0:
            free(output.data)
        free(output)


cdef int output_seek(output_t* output, size_t pos) nogil:
    """Seek output to position."""
    if output == NULL or pos > output.size:
        return 0
    output.pos = pos
    if pos > output.used:
        output.used = pos
    return 1


cdef int output_resize(output_t* output, size_t newsize) nogil:
    """Resize output."""
    cdef:
        uint8_t* tmp

    if output == NULL or newsize == 0 or output.used > output.size:
        return 0
    if newsize == output.size or output.owner == 0:
        return 1

    tmp = <uint8_t*> realloc(<void*> output.data, newsize)
    if tmp == NULL:
        return 0
    output.data = tmp
    output.size = newsize
    return 1

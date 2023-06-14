# deflate.pxd
# cython: language_level = 3

# Cython-declarations for the `deflate 1.18` library.
# https://github.com/ebiggers/libdeflate


from libc.stdint cimport uint32_t

cdef extern from "libdeflate.h":

    int LIBDEFLATE_VERSION_MAJOR
    int LIBDEFLATE_VERSION_MINOR
    char* LIBDEFLATE_VERSION_STRING

    ctypedef void* voidp
    ctypedef const void* voidpc
    ctypedef size_t* size_tp

    # === COMPRESSION =================================================

    cdef struct libdeflate_compressor
    ctypedef libdeflate_compressor* libdeflate_compressorp

    libdeflate_compressorp libdeflate_alloc_compressor(
        int compression_level
    ) nogil

    size_t libdeflate_deflate_compress(
        libdeflate_compressorp compressor,
        voidpc in_,
        size_t in_nbytes,
        voidp out,
        size_t out_nbytes_avail
    ) nogil

    size_t libdeflate_deflate_compress_bound(
        libdeflate_compressorp compressor,
        size_t in_nbytes
    ) nogil

    size_t libdeflate_zlib_compress(
        libdeflate_compressorp compressor,
        voidpc in_,
        size_t in_nbytes,
        voidp out,
        size_t out_nbytes_avail
    ) nogil

    size_t libdeflate_zlib_compress_bound(
        libdeflate_compressorp compressor,
        size_t in_nbytes
    ) nogil

    size_t libdeflate_gzip_compress(
        libdeflate_compressorp compressor,
        voidpc in_,
        size_t in_nbytes,
        voidp out,
        size_t out_nbytes_avail
    ) nogil

    size_t libdeflate_gzip_compress_bound(
        libdeflate_compressorp compressor,
        size_t in_nbytes
    ) nogil

    void libdeflate_free_compressor(
        libdeflate_compressorp compressor
    ) nogil


    # === DECOMPRESSION ===============================================

    cdef struct libdeflate_decompressor
    ctypedef libdeflate_decompressor* libdeflate_decompressorp

    libdeflate_decompressorp libdeflate_alloc_decompressor() nogil

    cdef enum libdeflate_result:
        LIBDEFLATE_SUCCESS = 0
        LIBDEFLATE_BAD_DATA = 1
        LIBDEFLATE_SHORT_OUTPUT = 2
        LIBDEFLATE_INSUFFICIENT_SPACE = 3

    libdeflate_result libdeflate_deflate_decompress(
        libdeflate_decompressorp decompressor,
        voidpc in_,
        size_t in_nbytes,
        voidp out,
        size_t out_nbytes_avail,
        size_t *actual_out_nbytes_ret
    ) nogil

    libdeflate_result libdeflate_deflate_decompress_ex(
        libdeflate_decompressorp decompressor,
        voidpc in_,
        size_t in_nbytes,
        voidp out,
        size_t out_nbytes_avail,
        size_t *actual_in_nbytes_ret,
        size_t *actual_out_nbytes_ret
    ) nogil

    libdeflate_result libdeflate_zlib_decompress(
        libdeflate_decompressorp decompressor,
        voidpc in_,
        size_t in_nbytes,
        voidp out,
        size_t out_nbytes_avail,
        size_t *actual_out_nbytes_ret
    ) nogil

    libdeflate_result libdeflate_zlib_decompress_ex(
        libdeflate_decompressorp decompressor,
        voidpc in_,
        size_t in_nbytes,
        voidp out,
        size_t out_nbytes_avail,
        size_t *actual_in_nbytes_ret,
        size_t *actual_out_nbytes_ret
    ) nogil

    libdeflate_result libdeflate_gzip_decompress(
        libdeflate_decompressorp decompressor,
        voidpc in_,
        size_t in_nbytes,
        voidp out,
        size_t out_nbytes_avail,
        size_t *actual_out_nbytes_ret
    ) nogil

    libdeflate_result libdeflate_gzip_decompress_ex(
        libdeflate_decompressorp decompressor,
        voidpc in_,
        size_t in_nbytes,
        voidp out,
        size_t out_nbytes_avail,
        size_t *actual_in_nbytes_ret,
        size_t *actual_out_nbytes_ret
    ) nogil

    void libdeflate_free_decompressor(
        libdeflate_decompressorp decompressor
    ) nogil


    # === CHECKSUMS ==================================================

    uint32_t libdeflate_adler32(
        uint32_t adler,
        voidpc buffer,
        size_t len_
    ) nogil

    uint32_t libdeflate_crc32(
        uint32_t crc,
        voidpc buffer,
        size_t len_
    ) nogil


    # === CUSTOM MEMORY ALLOCATOR =====================================

    void libdeflate_set_memory_allocator(
        void *(*malloc_func)(size_t),
        void (*free_func)(void *)
    ) nogil

import numpy as numpy
from Cython.Build import cythonize
from setuptools import setup
from setuptools.extension import Extension


setup(
    name="concatenated_zlib",
    ext_modules=cythonize(
        [
            Extension(
                "concatenated_zlib._shared",
                sources=["concatenated_zlib/_shared.pyx"],
                include_dirs=[numpy.get_include()],
            ),
            Extension(
                "concatenated_zlib._zlib",
                sources=["concatenated_zlib/_zlib.pyx"],
                libraries=["z"],
                include_dirs=[numpy.get_include()],
            ),
            Extension(
                "concatenated_zlib._zlibng",
                sources=["concatenated_zlib/_zlibng.pyx"],
                libraries=["z-ng"],
                include_dirs=[
                    numpy.get_include(),
                    "/opt/homebrew/include/",
                ],
                library_dirs=[
                    "/opt/homebrew/lib/",
                ]
            ),
            Extension(
                "concatenated_zlib._deflate",
                sources=["concatenated_zlib/_deflate.pyx"],
                libraries=["deflate"],
                include_dirs=[
                    numpy.get_include(),
                    "/opt/homebrew/include/",
                ],
                library_dirs=[
                    "/opt/homebrew/lib/",
                ]
            ),
        ],
        compiler_directives={
            "language_level": 3,
        },
    ),
)

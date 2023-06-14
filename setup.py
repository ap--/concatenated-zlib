import numpy as numpy
from Cython.Build import cythonize
from setuptools import setup
from setuptools.extension import Extension


setup(
    name="concatenated_zlib",
    version="v0.0.1",
    license="BSD",
    description="abc",
    python_requires=">=3.8",
    packages=["concatenated_zlib"],
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
        ],
        compiler_directives={
            "language_level": 3,
        },
    ),
)

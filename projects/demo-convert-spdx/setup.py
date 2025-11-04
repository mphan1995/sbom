from setuptools import setup, find_packages

setup(
    name="demo-convert-spdx-advanced",
    version="1.0.0",
    packages=find_packages(),
    install_requires=[
        "requests",
        "pandas",
        "numpy"
    ],
    entry_points={
        "console_scripts": ["demo-convert-spdx=app.main:main"]
    },
)

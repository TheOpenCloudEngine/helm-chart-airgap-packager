from setuptools import setup, find_packages

setup(
    name="helm-airgap-packager",
    version="0.1.0",
    description="Package Helm charts and Docker images for airgap deployment",
    long_description=open("README.md").read(),
    long_description_content_type="text/markdown",
    author="TheOpenCloudEngine",
    python_requires=">=3.10",
    packages=find_packages(),
    install_requires=[
        "click>=8.1.0",
        "PyYAML>=6.0",
    ],
    entry_points={
        "console_scripts": [
            "helm-airgap=packager.main:main",
        ],
    },
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: POSIX :: Linux",
        "Topic :: System :: Systems Administration",
    ],
)

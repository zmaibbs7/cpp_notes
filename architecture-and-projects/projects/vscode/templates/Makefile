SHELL := /bin/bash
ROS_DISTRO ?= humble
BUILD_TYPE ?= Debug

.DEFAULT_GOAL := build

.PHONY: build test clean

build:
	@source /opt/ros/$(ROS_DISTRO)/setup.bash && \
	colcon build \
		--base-paths src \
		--symlink-install \
		--cmake-args \
		-G Ninja \
		-DCMAKE_BUILD_TYPE=$(BUILD_TYPE) \
		-DCMAKE_C_COMPILER_LAUNCHER=ccache \
		-DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
		-DCMAKE_EXPORT_COMPILE_COMMANDS=ON

test:
	@source /opt/ros/$(ROS_DISTRO)/setup.bash && \
	colcon test --base-paths src && \
	colcon test-result --verbose

clean:
	rm -rf build install log .cache

SHELL := /bin/bash
ROS_DISTRO ?= humble
BUILD_TYPE ?= RelWithDebInfo

.DEFAULT_GOAL := build

.PHONY: build clean

build:
	@source /opt/ros/$(ROS_DISTRO)/setup.bash && \
	colcon build \
		--cmake-args \
		-DCMAKE_BUILD_TYPE=$(BUILD_TYPE) \
		-DCMAKE_EXPORT_COMPILE_COMMANDS=ON

clean:
	rm -rf build install log

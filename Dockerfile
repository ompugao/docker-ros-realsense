#syntax=docker/dockerfile:1.2
FROM ros:noetic

LABEL maintainer="iory ab.ioryz@gmail.com"

ENV ROS_DISTRO noetic

RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked --mount=type=cache,target=/var/lib/apt,sharing=locked apt -q -qq update && \
    apt-get install -y --no-install-recommends \
        pkg-config \
        libglvnd-dev  \
        libgl1-mesa-dev \
        libegl1-mesa-dev \
        libgles2-mesa-dev

ENV NVIDIA_VISIBLE_DEVICES \
    ${NVIDIA_VISIBLE_DEVICES:-all}
ENV NVIDIA_DRIVER_CAPABILITIES \
    ${NVIDIA_DRIVER_CAPABILITIES:+$NVIDIA_DRIVER_CAPABILITIES,}graphics

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked --mount=type=cache,target=/var/lib/apt,sharing=locked apt -q -qq update && \
    DEBIAN_FRONTEND=noninteractive apt install -y \
    software-properties-common \
    wget \
    apt-transport-https


#RUN apt-key adv --keyserver keys.gnupg.net:80 --recv-key F6E65AC044F831AC80A06380C8B3A55A6F3EFCDE || apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-option http-proxy=http://in-proxy.denso.co.jp:8080 --recv-key F6E65AC044F831AC80A06380C8B3A55A6F3EFCDE
#RUN add-apt-repository -y "deb https://librealsense.intel.com/Debian/apt-repo xenial main"
RUN mkdir -p /etc/apt/keyrings
#RUN curl -sSf https://librealsense.intel.com/Debian/librealsense.pgp | tee /etc/apt/keyrings/librealsense.pgp > /dev/null
RUN wget https://librealsense.intel.com/Debian/librealsense.pgp -O /etc/apt/keyrings/librealsense.pgp
RUN echo "deb [signed-by=/etc/apt/keyrings/librealsense.pgp] https://librealsense.intel.com/Debian/apt-repo `lsb_release -cs` main" | tee /etc/apt/sources.list.d/librealsense.list
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked --mount=type=cache,target=/var/lib/apt,sharing=locked apt-get update -qq && apt-get install librealsense2-dkms librealsense2-dev --allow-unauthenticated -y

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked --mount=type=cache,target=/var/lib/apt,sharing=locked apt -q -qq update && \
  DEBIAN_FRONTEND=noninteractive apt install -y --allow-unauthenticated \
  python3-rosinstall \
  python3-catkin-tools \
  ros-${ROS_DISTRO}-jsk-tools \
  ros-${ROS_DISTRO}-rgbd-launch \
  ros-${ROS_DISTRO}-image-transport-plugins \
  ros-${ROS_DISTRO}-image-transport \
  ros-${ROS_DISTRO}-rviz \
  ros-${ROS_DISTRO}-pcl-ros \
  git

RUN rosdep update

RUN mkdir -p /workspace

RUN mkdir -p /catkin_ws/src && cd /catkin_ws/src && \
  git clone --depth 1 https://github.com/IntelRealSense/realsense-ros.git --branch ros1-legacy IntelRealSense/realsense-ros && \
  git clone --depth 1 https://github.com/pal-robotics/ddynamic_reconfigure pal-robotics/ddynamic_reconfigure &&\
  git clone --depth 1 https://github.com/blodow/realtime_urdf_filter blodow/realtime_urdf_filter
COPY patches /workspace/patches
RUN patch -f -p1 -d /catkin_ws/src/blodow/realtime_urdf_filter < /workspace/patches/use_latest_robot_tfs.patch # wait_for_robot_tfs.patch
COPY common_pkgs/crigroup/osr_course_pkgs/osr_description /catkin_ws/src/crigroup/osr_description
COPY common_pkgs/bi3ri/robotiq/robotiq_description /catkin_ws/src/bi3ri/robotiq/robotiq_description
COPY catkin_ws/ompugao/simple_voxelizer /catkin_ws/src/ompugao/simple_voxelizer
COPY catkin_ws/ompugao/simple_voxelizer_msgs /catkin_ws/src/ompugao/simple_voxelizer_msgs

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked --mount=type=cache,target=/var/lib/apt,sharing=locked \
	cd catkin_ws; bash -c 'source /opt/ros/${ROS_DISTRO}/setup.bash; rosdep install -y --ignore-src --from-paths src && catkin build -DCATKIN_ENABLE_TESTING=False -DCMAKE_BUILD_TYPE=Release' && rm -rf build
RUN touch /root/.bashrc && \
  echo "source /catkin_ws/devel/setup.bash\n" >> /root/.bashrc && \
  echo "rossetip\n" >> /root/.bashrc && \
  echo "rossetmaster localhost"


RUN --mount=type=cache,target=/var/cache/apt,sharing=locked --mount=type=cache,target=/var/lib/apt,sharing=locked apt -q -qq update && \
  DEBIAN_FRONTEND=noninteractive apt install -y --allow-unauthenticated \
  python3-pip

# generate padded robot for pointcloud filtering
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked --mount=type=cache,target=/var/lib/apt,sharing=locked apt -q -qq update && \
  DEBIAN_FRONTEND=noninteractive apt install -y --allow-unauthenticated \
  python3-pyqt5
RUN --mount=type=cache,target=/root/.cache/pip pip3 install pymeshlab pyqt5==5.15
COPY ./scripts /workspace/scripts
# NOTE: set LD_LIBRARY_PATH for appropriate pyqt5 importing in pymeshlab
RUN cd /workspace/scripts && LD_LIBRARY_PATH=/usr/local/lib/python$(python3 --version |cut -d ' ' -f 2|cut -d '.' -f 1,2)/dist-packages/ bash pad_meshes.sh /catkin_ws/src/crigroup/osr_description/urdf/meshes 0.03
RUN cp -a /catkin_ws/src/crigroup/osr_description/urdf/denso_vs060.urdf /catkin_ws/src/crigroup/osr_description/urdf/denso_vs060_pad.urdf \
	&& sed -i -e 's/\.stl/_pad.stl/g' /catkin_ws/src/crigroup/osr_description/urdf/denso_vs060_pad.urdf \
	&& cp -a /catkin_ws/src/crigroup/osr_description/urdf/denso_vs060_robot.urdf.xacro /catkin_ws/src/crigroup/osr_description/urdf/denso_vs060_robot_pad.urdf.xacro \
	&& sed -i -e 's/denso_vs060\.urdf/denso_vs060_pad.urdf/g' /catkin_ws/src/crigroup/osr_description/urdf/denso_vs060_robot_pad.urdf.xacro \
	&& cp -a /catkin_ws/src/crigroup/osr_description/urdf/denso_robotiq_85_gripper.urdf.xacro /catkin_ws/src/crigroup/osr_description/urdf/denso_pad_robotiq_85_gripper.urdf.xacro \
	&& sed -i -e 's/denso_vs060_robot\.urdf\.xacro/denso_vs060_robot_pad.urdf.xacro/g' /catkin_ws/src/crigroup/osr_description/urdf/denso_pad_robotiq_85_gripper.urdf.xacro

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked --mount=type=cache,target=/var/lib/apt,sharing=locked apt -q -qq update && \
  DEBIAN_FRONTEND=noninteractive apt install -y --allow-unauthenticated \
  tmux \
  gdb \
  vim

WORKDIR /workspace

COPY ./ros_entrypoint.sh /
ENTRYPOINT ["/ros_entrypoint.sh"]

CMD ["bash"]

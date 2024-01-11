FROM ros:noetic

LABEL maintainer="iory ab.ioryz@gmail.com"

ENV ROS_DISTRO noetic

RUN apt -q -qq update && \
    DEBIAN_FRONTEND=noninteractive apt install -y \
    software-properties-common \
    wget \
    apt-transport-https && rm -rf /var/lib/apt/lists


#RUN apt-key adv --keyserver keys.gnupg.net:80 --recv-key F6E65AC044F831AC80A06380C8B3A55A6F3EFCDE || apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-option http-proxy=http://in-proxy.denso.co.jp:8080 --recv-key F6E65AC044F831AC80A06380C8B3A55A6F3EFCDE
#RUN add-apt-repository -y "deb https://librealsense.intel.com/Debian/apt-repo xenial main"
RUN mkdir -p /etc/apt/keyrings
#RUN curl -sSf https://librealsense.intel.com/Debian/librealsense.pgp | tee /etc/apt/keyrings/librealsense.pgp > /dev/null
RUN wget https://librealsense.intel.com/Debian/librealsense.pgp -O /etc/apt/keyrings/librealsense.pgp
RUN echo "deb [signed-by=/etc/apt/keyrings/librealsense.pgp] https://librealsense.intel.com/Debian/apt-repo `lsb_release -cs` main" | tee /etc/apt/sources.list.d/librealsense.list
RUN apt-get update -qq && apt-get install librealsense2-dkms librealsense2-dev --allow-unauthenticated -y  && rm -rf /var/lib/apt/lists

RUN apt -q -qq update && \
  DEBIAN_FRONTEND=noninteractive apt install -y --allow-unauthenticated \
  python3-rosinstall \
  python3-catkin-tools \
  ros-${ROS_DISTRO}-jsk-tools \
  ros-${ROS_DISTRO}-rgbd-launch \
  ros-${ROS_DISTRO}-image-transport-plugins \
  ros-${ROS_DISTRO}-image-transport \
  git \
  && rm -rf /var/lib/apt/lists

RUN rosdep update

RUN mkdir -p /catkin_ws/src && cd /catkin_ws/src && \
  git clone --depth 1 https://github.com/IntelRealSense/realsense-ros.git --branch ros1-legacy && \
  git clone --depth 1 https://github.com/pal-robotics/ddynamic_reconfigure
#RUN mv /bin/sh /bin/sh_tmp && ln -s /bin/bash /bin/sh
RUN cd catkin_ws; bash -c 'source /opt/ros/${ROS_DISTRO}/setup.bash; catkin build -DCATKIN_ENABLE_TESTING=False -DCMAKE_BUILD_TYPE=Release' && rm -rf build
#RUN rm /bin/sh && mv /bin/sh_tmp /bin/sh
RUN touch /root/.bashrc && \
  echo "source /catkin_ws/devel/setup.bash\n" >> /root/.bashrc && \
  echo "rossetip\n" >> /root/.bashrc && \
  echo "rossetmaster localhost"

COPY ./ros_entrypoint.sh /
ENTRYPOINT ["/ros_entrypoint.sh"]

CMD ["bash"]

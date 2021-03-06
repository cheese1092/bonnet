# Use an official Python runtime as a parent image
FROM tano297/bonnet:cuda9-cudnn7

# recommended from nvidia to use the cuda devices
LABEL com.nvidia.volumes.needed="nvidia_driver"
ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64

# Replace 1000 with your user / group id (if needed)
RUN export uid=1000 gid=1000 && \
mkdir -p /home/developer && \
mkdir -p /etc/sudoers.d && \
echo "developer:x:${uid}:${gid}:Developer,,,:/home/developer:/bin/bash" >> /etc/passwd && \
echo "developer:x:${uid}:" >> /etc/group && \
echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
chmod 0440 /etc/sudoers.d/developer && \
chown ${uid}:${gid} -R /home/developer

# Set the working directory to $HOME/bonnet_wrkdir
ENV HOME /home/developer
WORKDIR $HOME/bonnet_wrkdir

# Copy the current directory contents into the container at $HOME/bonnet_wrkdir
ADD . $HOME/bonnet_wrkdir

# ownership of directory
RUN chown -R developer:developer $HOME/bonnet_wrkdir
RUN chmod 755 $HOME/bonnet_wrkdir

# user stuff (and env variables)
USER developer
RUN cp /etc/skel/.bashrc /home/developer/
RUN echo 'source /opt/ros/kinetic/setup.bash' >> /home/developer/.bashrc

# run the standalone build
ENV LD_LIBRARY_PATH /usr/local/cuda-9.0/lib64:$LD_LIBRARY_PATH
ENV PATH /usr/local/cuda-9.0/bin:$PATH
ENTRYPOINT ["/bin/bash","-c"]
CMD ["source /opt/ros/kinetic/setup.bash && \
      cd deploy_cpp/standalone && \
      mkdir -p build && cd build && rm -rf ./* && \
      cmake .. && make -j"]

# for visual output build and run like
# nvidia-docker build -t bonnet .
# nvidia-docker run -ti --rm -e DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -v $HOME/.Xauthority:/home/developer/.Xauthority -v /home/$USER/Desktop:/shared --net=host --pid=host --ipc=host bonnet /bin/bash
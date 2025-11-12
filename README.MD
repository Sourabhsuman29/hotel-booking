#run directly from robot using below command
#robot tests/e2e_application_flow.robot_

#run from docker using below command
#below command is used for creating docker images

#docker build -t robot-playwright .
#use to go inside the container
#docker run -it robot-playwright /bin/bash
#use to run automation from docker
#xvfb-run robot tests/e2e_application_flow.robot

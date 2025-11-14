#run directly from robot using below command
#robot tests/e2e_application_flow.robot

#Method 2 -- run from docker using below command 
#used for creating docker images
#-> docker build -t robot-playwright .
#-> docker run --rm -v "$(pwd):/tests" robot-playwright   
# comment
#Method 3  to run inside linux container
#used for creating docker images
#-> docker build -t robot-playwright .
#use to go inside the container
#-> docker run -it robot-playwright /bin/bash
#use to run automation from docker
#-> xvfb-run robot tests/e2e_application_flow.robot

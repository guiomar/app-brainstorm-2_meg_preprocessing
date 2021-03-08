FROM brainlife/mcr:2020a

#downloaded from https://neuroimage.usc.edu/bst/download.php
COPY brainstorm_210303.zip /
RUN unzip /brainstorm_210303.zip 

RUN ls /brainstorm3/bin/R2020a/brainstorm3.command

ENTRYPOINT ["/brainstorm3/bin/R2020a/brainstorm3.command", "/opt/mcr/v98"]

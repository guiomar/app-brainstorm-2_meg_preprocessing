#!/bin/bash
mkdir -p compiled
cat > build.m <<END
addpath(genpath('brainstorm3/deploy'))
addpath(genpath('jsonlab'))
mcc -m -R -nodisplay -d compiled main
exit
END
matlab -nodisplay -nosplash -r build
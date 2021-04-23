 #!/bin/bash
for i in $(ls | grep -e .*\.zip); do
    echo $(date) $i
    unzip $i
    echo "--------------"
done

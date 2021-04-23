 #!/bin/bash
for i in $(cat youtubedata); do
    echo $(date)
    curl -O $i
    echo "--------------"
done

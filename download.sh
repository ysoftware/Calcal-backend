curl -o data.txt http://185.163.118.53/main.php

if [ $? -eq 0 ]; then
    echo "File downloaded successfully."
else
    echo "Failed to download file."
fi

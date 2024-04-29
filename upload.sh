password=$(<password.txt)

if [ -z "$password" ]; then
    echo "Password not found"
    exit 1
fi

curl -F "file=@data.txt" -F "password=$password" -i https://whoniverse-app.com/calcal/main.php 
# curl -v -F "file=@data.txt" -F "password=$password" -i 127.0.0.1:8000/main.php

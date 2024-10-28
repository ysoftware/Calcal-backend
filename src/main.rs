use std::net::TcpListener;
use std::io::prelude::*;
use std::io::BufReader;
use std::fs;

fn main() {
    let listener = TcpListener::bind("0.0.0.0:7070").unwrap();

    for stream in listener.incoming() {
        let mut stream = stream.unwrap();
        let reader = BufReader::new(&mut stream);
        let request: Vec<String> = reader.lines().map(|r| r.unwrap()).take_while(|l| !l.is_empty()).collect();

        if request.len() > 0 && request.first().unwrap() == "GET /main.php HTTP/1.1" {
            let data = fs::read("data.txt").unwrap();
            let size_header = format!("Content-Length: {}\r\n", data.len());

            _ = stream.write_all(b"HTTP/1.1 200 OK\r\n");
            _ = stream.write_all(b"Content-type: text/plain;charset=UTF-8\r\n");
            _ = stream.write_all(size_header.as_bytes());
            _ = stream.write_all(b"\r\n");
            _ = stream.write_all(&data);
            println!("got get");
        } else {
            _ = stream.write_all("HTTP/1.1 405 Not allowed".as_bytes());
            println!("got garbage, returning 405");
        }
    }
}
